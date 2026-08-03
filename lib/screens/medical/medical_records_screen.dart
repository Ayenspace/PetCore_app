import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/medical_record.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medical_provider.dart';
import '../../providers/pet_providers.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});
  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  String? _filterPetId;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AppAuthProvider>().user?.id;
    if (uid != null) context.read<MedicalProvider>().listenToRecords(uid);
  }

  @override
  Widget build(BuildContext context) {
    final records = context.watch<MedicalProvider>().records;
    final pets = context.watch<PetProvider>().pets;
    final theme = Theme.of(context);

    final filtered = _filterPetId == null
        ? records
        : records.where((r) => r.petId == _filterPetId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/medical/add'),
          ),
        ],
      ),
      floatingActionButton: records.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => context.push('/medical/add'),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          if (pets.isNotEmpty)
            _PetFilterBar(
              pets: pets.map((p) => (id: p.id, name: p.name)).toList(),
              selectedPetId: _filterPetId,
              onSelected: (id) => setState(() => _filterPetId = id),
            ),
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(onAdd: () => context.push('/medical/add'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _RecordCard(
                      record: filtered[index],
                      theme: theme,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PetFilterBar extends StatelessWidget {
  final List<({String id, String name})> pets;
  final String? selectedPetId;
  final ValueChanged<String?> onSelected;

  const _PetFilterBar({
    required this.pets,
    required this.selectedPetId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 48,
      color: theme.scaffoldBackgroundColor,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _FilterChip(
            label: 'All',
            selected: selectedPetId == null,
            onTap: () => onSelected(null),
          ),
          ...pets.map((p) => _FilterChip(
                label: p.name,
                selected: selectedPetId == p.id,
                onTap: () => onSelected(selectedPetId == p.id ? null : p.id),
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

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

class _RecordCard extends StatelessWidget {
  final MedicalRecord record;
  final ThemeData theme;

  const _RecordCard({required this.record, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(record.id),
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
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Record'),
            content: const Text('Are you sure you want to delete this medical record?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        final ownerId = context.read<AppAuthProvider>().user!.id;
        context.read<MedicalProvider>().deleteRecord(ownerId, record.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
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
                      color: const Color(0xFFC62828).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medical_services_outlined, color: Color(0xFFC62828), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(record.diagnosis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(record.petName, style: TextStyle(color: theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Text(
                    '${record.date.day}/${record.date.month}/${record.date.year}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(icon: Icons.healing_outlined, label: 'Treatment', value: record.treatment),
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.person_outline, label: 'Vet', value: record.vetName),
              if (record.notes != null && record.notes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _InfoRow(icon: Icons.notes_outlined, label: 'Notes', value: record.notes!),
              ],
            ],
          ),
        ),
      ),
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
          Icon(Icons.medical_services_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No medical records yet', style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey)),
          const SizedBox(height: 8),
          Text('Add your first record to track your pet\'s health', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Record'),
          ),
        ],
      ),
    );
  }
}
