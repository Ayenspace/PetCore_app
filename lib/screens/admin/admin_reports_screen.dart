import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../widgets/admin_navigation.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            tooltip: 'Export report',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => _exportReport(context),
          ),
        ],
      ),
      bottomNavigationBar: const AdminNavigation(selectedIndex: 2),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('users').onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load reports: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final counts = _monthlyCounts(snapshot.data!.snapshot.value);
          final total = counts.fold<int>(0, (sum, item) => sum + item.count);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'User growth',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'New accounts created over the last 12 months.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                  child: SizedBox(
                    height: 280,
                    child: _UserGrowthChart(counts: counts),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_add_alt_1_outlined),
                  title: const Text('New users in the last 12 months'),
                  trailing: Text(
                    '$total',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportReport(BuildContext context) async {
    final snapshot = await FirebaseDatabase.instance.ref('users').get();
    final counts = _monthlyCounts(snapshot.value);
    final total = counts.fold<int>(0, (sum, item) => sum + item.count);
    final document = pw.Document();
    final boldFont = pw.Font.helveticaBold();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'PetCore Admin User Growth Report',
            style: pw.TextStyle(font: boldFont, fontSize: 20),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Generated ${_formatDate(DateTime.now())}'),
          pw.SizedBox(height: 24),
          pw.Text(
            'New users in the last 12 months: $total',
            style: pw.TextStyle(font: boldFont, fontSize: 13),
          ),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: const ['Month', 'New users'],
            data: [
              for (final item in counts)
                [_monthLabel(item.month), item.count.toString()],
            ],
            headerStyle: pw.TextStyle(font: boldFont),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.all(8),
          ),
        ],
      ),
    );

    try {
      await Printing.sharePdf(
        bytes: await document.save(),
        filename: 'petcore-user-growth-report.pdf',
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export report: $error')),
      );
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String _monthLabel(DateTime date) {
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${labels[date.month - 1]} ${date.year}';
  }

  static List<_MonthCount> _monthlyCounts(Object? value) {
    final now = DateTime.now();
    final months = List.generate(
      12,
      (index) => DateTime(now.year, now.month - 11 + index),
    );
    final counts = List.filled(12, 0);
    if (value is! Map) {
      return [for (var i = 0; i < 12; i++) _MonthCount(months[i], counts[i])];
    }

    for (final entry in value.entries) {
      if (entry.value is! Map) continue;
      final data = Map<String, dynamic>.from(
        (entry.value as Map).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
      final rawDate = data['createdAt']?.toString();
      if (rawDate == null) continue;
      final createdAt = DateTime.tryParse(rawDate);
      if (createdAt == null) continue;
      for (var i = 0; i < months.length; i++) {
        if (createdAt.year == months[i].year &&
            createdAt.month == months[i].month) {
          counts[i]++;
          break;
        }
      }
    }

    return [for (var i = 0; i < 12; i++) _MonthCount(months[i], counts[i])];
  }
}

class _MonthCount {
  final DateTime month;
  final int count;

  const _MonthCount(this.month, this.count);
}

class _UserGrowthChart extends StatelessWidget {
  final List<_MonthCount> counts;

  const _UserGrowthChart({required this.counts});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _UserGrowthPainter(
        counts: counts,
        barColor: Theme.of(context).colorScheme.primary,
        labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _UserGrowthPainter extends CustomPainter {
  final List<_MonthCount> counts;
  final Color barColor;
  final Color labelColor;

  const _UserGrowthPainter({
    required this.counts,
    required this.barColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const chartTop = 12.0;
    const chartBottom = 38.0;
    const chartLeft = 12.0;
    const chartRight = 8.0;
    final chartHeight = size.height - chartTop - chartBottom;
    final chartWidth = size.width - chartLeft - chartRight;
    final maxCount = counts.fold<int>(
      0,
      (max, item) => item.count > max ? item.count : max,
    );
    final scale = maxCount == 0 ? 1.0 : maxCount.toDouble();
    final slotWidth = chartWidth / counts.length;
    final barWidth = slotWidth * 0.56;
    final barPaint = Paint()..color = barColor;
    final linePaint = Paint()
      ..color = labelColor.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    final textStyle = TextStyle(color: labelColor, fontSize: 10);
    final valueStyle = TextStyle(
      color: labelColor,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    for (var line = 0; line <= 4; line++) {
      final y = chartTop + chartHeight * (line / 4);
      canvas.drawLine(
        Offset(chartLeft, y),
        Offset(size.width - chartRight, y),
        linePaint,
      );
    }

    for (var index = 0; index < counts.length; index++) {
      final item = counts[index];
      final barHeight = chartHeight * (item.count / scale);
      final x = chartLeft + index * slotWidth + (slotWidth - barWidth) / 2;
      final y = chartTop + chartHeight - barHeight;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(4),
        ),
        barPaint,
      );
      if (item.count > 0) {
        _drawText(
          canvas,
          '${item.count}',
          Offset(x + barWidth / 2, y - 14),
          valueStyle,
          centered: true,
        );
      }
      _drawText(
        canvas,
        _monthLabel(item.month),
        Offset(x + barWidth / 2, size.height - 22),
        textStyle,
        centered: true,
      );
    }
  }

  static String _monthLabel(DateTime date) {
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return labels[date.month - 1];
  }

  static void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style, {
    required bool centered,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = centered
        ? Offset(center.dx - painter.width / 2, center.dy)
        : center;
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _UserGrowthPainter oldDelegate) {
    return oldDelegate.counts != counts || oldDelegate.barColor != barColor;
  }
}
