import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../models/pet_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/medical_provider.dart';
import '../../providers/pet_providers.dart';
import '../../providers/vaccination_provider.dart';
import '../../services/pdfs.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<PetProvider>().pets;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: pets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.summarize_outlined,
                    size: 72,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pets added yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a pet to generate health reports',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Select a pet to generate and download their full health report as a PDF.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: pets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _PetReportCard(pet: pets[i]),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PetReportCard extends StatefulWidget {
  final PetModel pet;
  const _PetReportCard({required this.pet});

  @override
  State<_PetReportCard> createState() => _PetReportCardState();
}

class _PetReportCardState extends State<_PetReportCard> {
  bool _generating = false;

  Future<void> _generatePdf(BuildContext context) async {
    setState(() => _generating = true);

    try {
      final appointments =
          context
              .read<AppointmentProvider>()
              .appointments
              .where((a) => a.petId == widget.pet.id)
              .toList()
            ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      final records =
          context
              .read<MedicalProvider>()
              .records
              .where((r) => r.petId == widget.pet.id)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
      final vaccinations =
          context
              .read<VaccinationProvider>()
              .vaccinations
              .where((v) => v.petId == widget.pet.id)
              .toList()
            ..sort((a, b) => b.dateGiven.compareTo(a.dateGiven));

      final pdf = PdfService.generatePetReport(
        pet: widget.pet,
        appointments: appointments,
        records: records,
        vaccinations: vaccinations,
      );

      if (!context.mounted) return;

      final bytes = await pdf.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${widget.pet.name}_health_report.pdf',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointments = context
        .watch<AppointmentProvider>()
        .appointments
        .where((a) => a.petId == widget.pet.id)
        .toList();
    final records = context
        .watch<MedicalProvider>()
        .records
        .where((r) => r.petId == widget.pet.id)
        .toList();
    final vaccinations = context
        .watch<VaccinationProvider>()
        .vaccinations
        .where((v) => v.petId == widget.pet.id)
        .toList();
    final overdueCount = vaccinations.where((v) => v.isDue).length;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet header
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  backgroundImage: widget.pet.photoUrl != null
                      ? NetworkImage(widget.pet.photoUrl!)
                      : null,
                  child: widget.pet.photoUrl == null
                      ? Icon(
                          Icons.pets,
                          color: theme.colorScheme.primary,
                          size: 24,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.pet.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${widget.pet.species}${widget.pet.breed != null ? ' • ${widget.pet.breed}' : ''} • ${widget.pet.age} yr${widget.pet.age != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (overdueCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$overdueCount overdue',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                _StatChip(
                  icon: Icons.event_outlined,
                  label: 'Appointments',
                  value: appointments.length,
                  color: Colors.purple,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.medical_services_outlined,
                  label: 'Records',
                  value: records.length,
                  color: Colors.teal,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.vaccines,
                  label: 'Vaccines',
                  value: vaccinations.length,
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Download PDF button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generating ? null : () => _generatePdf(context),
                icon: _generating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(
                  _generating ? 'Generating...' : 'Download PDF Report',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// Keep this export so routes.dart still works
class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
