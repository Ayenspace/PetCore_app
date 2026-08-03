import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/vaccination_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_providers.dart';
import '../../providers/vaccination_provider.dart';

class VaccinationsScreen extends StatefulWidget {
  const VaccinationsScreen({super.key});
  @override
  State<VaccinationsScreen> createState() => _VaccinationsScreenState();
}

class _VaccinationsScreenState extends State<VaccinationsScreen> {
  String? _filterPetId;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AppAuthProvider>().user?.id;
    if (uid != null) context.read<VaccinationProvider>().listenToVaccinations(uid);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VaccinationProvider>();
    final pets = context.watch<PetProvider>().pets;
    final theme = Theme.of(context);

    final filtered = _filterPetId == null
        ? provider.vaccinations
        : provider.forPet(_filterPetId!);

    final overdue = provider.overdue;
    final dueSoon = provider.dueSoon;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccinations', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/vaccinations/add'),
          ),
        ],
      ),
      floatingActionButton: provider.vaccinations.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => context.push('/vaccinations/add'),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          // Overdue / due soon banners
          if (overdue.isNotEmpty)
            _AlertBanner(
              icon: Icons.warning_amber_rounded,
              color: Colors.red,
              message: '${overdue.length} vaccination${overdue.length > 1 ? 's are' : ' is'} overdue',
            ),
          if (dueSoon.isNotEmpty)
            _AlertBanner(
              icon: Icons.notifications_active_outlined,
              color: Colors.orange,
              message: '${dueSoon.length} vaccination${dueSoon.length > 1 ? 's are' : ' is'} due within 30 days',
            ),

          // Pet filter
          if (pets.isNotEmpty)
            _PetFilterBar(
              pets: pets.map((p) => (id: p.id, name: p.name)).toList(),
              selectedPetId: _filterPetId,
              onSelected: (id) => setState(() => _filterPetId = id),
            ),

          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(onAdd: () => context.push('/vaccinations/add'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _VaccinationCard(
                      vaccination: filtered[index],
                      theme: theme,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _AlertBanner({required this.icon, required this.color, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _PetFilterBar extends StatelessWidget {
  final List<({String id, String name})> pets;
  final String? selectedPetId;
  final ValueChanged<String?> onSelected;

  const _PetFilterBar({required this.pets, required this.selectedPetId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _Chip(label: 'All', selected: selectedPetId == null, onTap: () => onSelected(null)),
          ...pets.map((p) => _Chip(
                label: p.name,
                selected: selectedPetId == p.id,
                onTap: () => onSelected(selectedPetId == p.id ? null : p.id),
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey.shade600,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _VaccinationCard extends StatelessWidget {
  final VaccinationModel vaccination;
  final ThemeData theme;

  const _VaccinationCard({required this.vaccination, required this.theme});

  @override
  Widget build(BuildContext context) {
    final status = _getStatus(vaccination);

    return Dismissible(
      key: Key(vaccination.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Vaccination'),
          content: const Text('Are you sure you want to delete this vaccination record?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        final ownerId = context.read<AppAuthProvider>().user!.id;
        context.read<VaccinationProvider>().deleteVaccination(ownerId, vaccination.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.vaccines, color: Color(0xFF2E7D32), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vaccination.vaccineName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(vaccination.petName, style: TextStyle(color: theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  _StatusBadge(label: status.label, color: status.color),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(icon: Icons.calendar_today_outlined, label: 'Given', value: '${vaccination.dateGiven.day}/${vaccination.dateGiven.month}/${vaccination.dateGiven.year}'),
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.person_outline, label: 'Vet', value: vaccination.vetName),
              if (vaccination.nextDueDate != null) ...[
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.event_repeat_outlined,
                  label: 'Next due',
                  value: '${vaccination.nextDueDate!.day}/${vaccination.nextDueDate!.month}/${vaccination.nextDueDate!.year}',
                ),
              ],
              if (vaccination.notes != null && vaccination.notes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _InfoRow(icon: Icons.notes_outlined, label: 'Notes', value: vaccination.notes!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  ({String label, Color color}) _getStatus(VaccinationModel v) {
    if (v.isDue) return (label: 'Overdue', color: Colors.red);
    if (v.nextDueDate == null) return (label: 'Done', color: Colors.green);
    final daysLeft = v.nextDueDate!.difference(DateTime.now()).inDays;
    if (daysLeft <= 30) return (label: 'Due soon', color: Colors.orange);
    return (label: 'Up to date', color: Colors.green);
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.vaccines, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No vaccinations yet', style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey)),
          const SizedBox(height: 8),
          Text('Track your pet\'s vaccination history', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Vaccination'),
          ),
        ],
      ),
    );
  }
}
