import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pet_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/medical_provider.dart';
import '../../providers/pet_providers.dart';
import '../../providers/vaccination_provider.dart';
import '../../providers/weight_provider.dart';

class HealthAnalyticsScreen extends StatelessWidget {
  const HealthAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<PetProvider>().pets;
    return Scaffold(
      appBar: AppBar(title: const Text('Health Analytics')),
      body: pets.isEmpty
          ? const Center(child: Text('Add a pet to view health analytics.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pets.length,
              itemBuilder: (context, index) => _PetAnalytics(pet: pets[index]),
            ),
    );
  }
}

class _PetAnalytics extends StatelessWidget {
  final PetModel pet;
  const _PetAnalytics({required this.pet});

  @override
  Widget build(BuildContext context) {
    final appointments = context
        .watch<AppointmentProvider>()
        .appointments
        .where((item) => item.petId == pet.id)
        .toList();
    final records = context
        .watch<MedicalProvider>()
        .records
        .where((item) => item.petId == pet.id)
        .toList();
    final vaccinations = context
        .watch<VaccinationProvider>()
        .vaccinations
        .where((item) => item.petId == pet.id)
        .toList();
    final weights = context.watch<WeightProvider>().forPet(pet.id);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pet.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${pet.species}${pet.breed == null ? '' : ' • ${pet.breed}'}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Metric(
                  label: 'Appointments',
                  value: '${appointments.length}',
                  icon: Icons.event_outlined,
                  color: Colors.indigo,
                ),
                _Metric(
                  label: 'Records',
                  value: '${records.length}',
                  icon: Icons.medical_services_outlined,
                  color: Colors.teal,
                ),
                _Metric(
                  label: 'Vaccines',
                  value: '${vaccinations.length}',
                  icon: Icons.vaccines_outlined,
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Weight trend (kg)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: weights.length < 2
                  ? Center(
                      child: Text(
                        weights.isEmpty
                            ? 'Weight history will appear after recording a weight.'
                            : 'Record another weight to show a trend.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : _WeightChart(weights: weights),
            ),
            const SizedBox(height: 12),
            _SummaryRow(
              label: 'Latest weight',
              value: weights.isEmpty
                  ? (pet.weight == null ? 'Not recorded' : '${pet.weight} kg')
                  : '${weights.last.weight.toStringAsFixed(1)} kg',
            ),
            if (weights.length >= 2)
              _SummaryRow(
                label: 'Change since first record',
                value:
                    '${(weights.last.weight - weights.first.weight).toStringAsFixed(1)} kg',
              ),
            _SummaryRow(
              label: 'Vaccinations due',
              value: '${vaccinations.where((item) => item.isDue).length}',
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _WeightChart extends StatelessWidget {
  final List<dynamic> weights;
  const _WeightChart({required this.weights});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _WeightChartPainter(weights.cast()),
    child: const SizedBox.expand(),
  );
}

class _WeightChartPainter extends CustomPainter {
  final List<dynamic> weights;
  _WeightChartPainter(this.weights);

  @override
  void paint(Canvas canvas, Size size) {
    final values = weights
        .map<double>((entry) => entry.weight as double)
        .toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(maxValue - minValue, 0.5);
    final line = Paint()
      ..color = Colors.teal
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final dot = Paint()
      ..color = Colors.teal
      ..style = PaintingStyle.fill;
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? size.width / 2
          : index * size.width / (values.length - 1);
      final y =
          size.height -
          ((values[index] - minValue) / range * (size.height - 24)) -
          12;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 5, dot);
    }
    canvas.drawPath(path, line);
    final textStyle = const TextStyle(color: Colors.grey, fontSize: 11);
    _drawText(
      canvas,
      '${minValue.toStringAsFixed(1)} kg',
      const Offset(0, 0),
      textStyle,
    );
    _drawText(
      canvas,
      '${maxValue.toStringAsFixed(1)} kg',
      Offset(0, size.height - 16),
      textStyle,
    );
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) =>
      oldDelegate.weights != weights;
}
