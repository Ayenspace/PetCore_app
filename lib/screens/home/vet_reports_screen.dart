import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';

class VetReportsScreen extends StatelessWidget {
  const VetReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appointments = List<AppointmentModel>.from(
      context.watch<AppointmentProvider>().vetAppointments)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final theme = Theme.of(context);
    final completed = appointments
        .where((a) => a.status == AppointmentStatus.completed)
        .length;
    final cancelled = appointments
        .where((a) => a.status == AppointmentStatus.cancelled)
        .length;
    final upcoming = appointments
        .where((a) => a.status == AppointmentStatus.upcoming)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Reports'),
        actions: [
          IconButton(
            tooltip: 'Export report',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => _export(context, appointments),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Your appointment analytics',
            style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Metric(label: 'Total', value: '${appointments.length}', color: Colors.indigo),
              const SizedBox(width: 8),
              _Metric(label: 'Completed', value: '$completed', color: Colors.green),
              const SizedBox(width: 8),
              _Metric(label: 'Upcoming', value: '$upcoming', color: Colors.orange),
            ],
          ),
          const SizedBox(height: 20),
          _StatusSummary(
            completed: completed,
            cancelled: cancelled,
            upcoming: upcoming,
          ),
          const SizedBox(height: 24),
          _AppointmentTrend(appointments: appointments),
          const SizedBox(height: 24),
          Text(
            'Appointment history',
            style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          if (appointments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('No appointments available yet.')),
            )
          else
            ...appointments.map((appointment) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.pets_outlined),
                  ),
                  title: Text(
                    '${appointment.petName} • ${appointment.service}',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  subtitle: Text(_formatDate(appointment.dateTime)),
                  trailing: Text(
                    appointment.status.name,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                )),
        ],
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    List<AppointmentModel> appointments,
  ) async {
    final user = context.read<AppAuthProvider>().user;
    final document = pw.Document();
    final font = pw.Font.helvetica();
    final bold = pw.Font.helveticaBold();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'PetCore Veterinarian Appointment Report',
            style: pw.TextStyle(font: bold, fontSize: 18),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Veterinarian: ${user?.name ?? 'Unknown'}', style: pw.TextStyle(font: font)),
          pw.Text('Generated: ${_formatDate(DateTime.now())}', style: pw.TextStyle(font: font)),
          pw.SizedBox(height: 20),
          pw.Text('Appointments: ${appointments.length}', style: pw.TextStyle(font: bold)),
          pw.SizedBox(height: 10),
          if (appointments.isEmpty)
            pw.Text('No appointments recorded.', style: pw.TextStyle(font: font))
          else
            pw.Table.fromTextArray(
              headers: const ['Pet', 'Service', 'Date', 'Status'],
              data: appointments
                  .map((a) => [a.petName, a.service, _formatDate(a.dateTime), a.status.name])
                  .toList(),
              headerStyle: pw.TextStyle(font: bold),
              cellStyle: pw.TextStyle(font: font, fontSize: 9),
            ),
        ],
      ),
    );
    final bytes = await document.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'vet_appointment_report.pdf',
    );
  }

  static String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/${dateTime.year} $hour:$minute';
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Metric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
}

class _StatusSummary extends StatelessWidget {
  final int completed;
  final int cancelled;
  final int upcoming;

  const _StatusSummary({
    required this.completed,
    required this.cancelled,
    required this.upcoming,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status breakdown',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text('Completed: $completed'),
              Text('Upcoming: $upcoming'),
              Text('Cancelled: $cancelled'),
            ],
          ),
        ),
      );
}

class _AppointmentTrend extends StatelessWidget {
  final List<AppointmentModel> appointments;

  const _AppointmentTrend({required this.appointments});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(
      6,
      (index) => DateTime(now.year, now.month - 5 + index),
    );
    final counts = months.map((month) {
      return appointments.where((appointment) {
        return appointment.dateTime.year == month.year &&
            appointment.dateTime.month == month.month;
      }).length;
    }).toList();
    final maxCount = counts.fold<int>(
      0,
      (max, count) => count > max ? count : max,
    );
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment trend',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(months.length, (index) {
                  final count = counts[index];
                  final barHeight = maxCount == 0
                      ? 8.0
                      : 82 * count / maxCount;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: 26,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _monthLabel(months[index]),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _monthLabel(DateTime month) {
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
    return labels[month.month - 1];
  }
}