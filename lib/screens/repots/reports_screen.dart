import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pet_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/medical_provider.dart';
import '../../providers/pet_providers.dart';
import '../../providers/vaccination_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<PetProvider>().pets;

    return Scaffold(
      appBar: AppBar(title: const Text('Health Reports')),
      body: pets.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No pets added yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _PetReportCard(pet: pets[i]),
            ),
    );
  }
}

class _PetReportCard extends StatelessWidget {
  final PetModel pet;
  const _PetReportCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    final appointments = context.watch<AppointmentProvider>().appointments
        .where((a) => a.petId == pet.id).toList();
    final records = context.watch<MedicalProvider>().records
        .where((r) => r.petId == pet.id).toList();
    final vaccinations = context.watch<VaccinationProvider>().vaccinations
        .where((v) => v.petId == pet.id).toList();

    final overdueVaccines = vaccinations.where((v) => v.isDue).length;
    final upcomingAppts = appointments.where((a) => a.status.name == 'upcoming').length;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _PetReportDetailScreen(pet: pet)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: pet.photoUrl != null ? NetworkImage(pet.photoUrl!) : null,
                    child: pet.photoUrl == null ? Text(pet.name[0].toUpperCase()) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pet.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${pet.species} • ${pet.breed}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                  if (overdueVaccines > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text('$overdueVaccines overdue', style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatChip(icon: Icons.event, label: 'Appointments', value: appointments.length, color: Colors.purple),
                  const SizedBox(width: 8),
                  _StatChip(icon: Icons.medical_services, label: 'Records', value: records.length, color: Colors.teal),
                  const SizedBox(width: 8),
                  _StatChip(icon: Icons.vaccines, label: 'Vaccines', value: vaccinations.length, color: Colors.blue),
                ],
              ),
              if (upcomingAppts > 0) ...[
                const SizedBox(height: 10),
                Text('$upcomingAppts upcoming appointment${upcomingAppts > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ],
          ),
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
  const _StatChip({required this.icon, required this.label, required this.value, required this.color});

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
            Text('$value', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

// ─── Detail Screen ───────────────────────────────────────────────────────────

class _PetReportDetailScreen extends StatelessWidget {
  final PetModel pet;
  const _PetReportDetailScreen({required this.pet});

  @override
  Widget build(BuildContext context) {
    final appointments = context.watch<AppointmentProvider>().appointments
        .where((a) => a.petId == pet.id).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final records = context.watch<MedicalProvider>().records
        .where((r) => r.petId == pet.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final vaccinations = context.watch<VaccinationProvider>().vaccinations
        .where((v) => v.petId == pet.id).toList()
      ..sort((a, b) => b.dateGiven.compareTo(a.dateGiven));

    return Scaffold(
      appBar: AppBar(title: Text('${pet.name}\'s Report')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'Appointments (${appointments.length})'),
          if (appointments.isEmpty)
            _EmptyRow(label: 'No appointments')
          else
            ...appointments.map((a) => _SimpleRow(
              icon: Icons.event,
              title: a.service,
              subtitle: '${a.vetName} • ${_fmt(a.dateTime)}',
              trailing: _statusBadge(a.status.name),
            )),
          const SizedBox(height: 16),
          _SectionHeader(title: 'Medical Records (${records.length})'),
          if (records.isEmpty)
            _EmptyRow(label: 'No medical records')
          else
            ...records.map((r) => _SimpleRow(
              icon: Icons.medical_services,
              title: r.diagnosis,
              subtitle: '${r.vetName} • ${_fmt(r.date)}',
            )),
          const SizedBox(height: 16),
          _SectionHeader(title: 'Vaccinations (${vaccinations.length})'),
          if (vaccinations.isEmpty)
            _EmptyRow(label: 'No vaccinations')
          else
            ...vaccinations.map((v) => _SimpleRow(
              icon: Icons.vaccines,
              title: v.vaccineName,
              subtitle: 'Given: ${_fmt(v.dateGiven)}${v.nextDueDate != null ? ' • Due: ${_fmt(v.nextDueDate!)}' : ''}',
              trailing: v.isDue
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                      child: const Text('Overdue', style: TextStyle(color: Colors.red, fontSize: 11)),
                    )
                  : null,
            )),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  Widget _statusBadge(String status) {
    final colors = {
      'upcoming': Colors.blue,
      'completed': Colors.green,
      'cancelled': Colors.grey,
    };
    final c = colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(color: c, fontSize: 11)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      );
}

class _EmptyRow extends StatelessWidget {
  final String label;
  const _EmptyRow({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      );
}

class _SimpleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  const _SimpleRow({required this.icon, required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 6),
        child: ListTile(
          dense: true,
          leading: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
          trailing: trailing,
        ),
      );
}

class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('PDF Preview')),
        body: const Center(child: Text('PDF preview coming soon.')),
      );
}
