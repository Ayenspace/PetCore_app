import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_poviders.dart';
import '../../models/pet_model.dart';

class PetDetailsScreen extends StatelessWidget {
  final String petId;
  const PetDetailsScreen({super.key, required this.petId});

  @override
  Widget build(BuildContext context) {
    final pet = context.watch<PetProvider>().getPetById(petId);
    final theme = Theme.of(context);

    if (pet == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Pet not found')));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: pet.photoUrl != null
                  ? Image.network(pet.photoUrl!, fit: BoxFit.cover)
                  : Container(
                      color: theme.colorScheme.primary,
                      child: const Icon(Icons.pets, size: 80, color: Colors.white54),
                    ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => context.push('/pets/$petId/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: () => _confirmDelete(context, pet),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(pet.name, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: pet.gender.toLowerCase() == 'male' ? Colors.blue.shade50 : Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          pet.gender,
                          style: TextStyle(
                            color: pet.gender.toLowerCase() == 'male' ? Colors.blue : Colors.pink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet.species}${pet.breed != null ? ' • ${pet.breed}' : ''}',
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoGrid(context, pet),
                  const SizedBox(height: 28),
                  Text('Health Records', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildHealthActions(context, pet),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(BuildContext context, PetModel pet) {
    final items = [
      _InfoItem(icon: Icons.cake_outlined, label: 'Age', value: '${pet.age} year${pet.age != 1 ? 's' : ''}'),
      _InfoItem(icon: Icons.calendar_today_outlined, label: 'Born', value: '${pet.dateOfBirth.day}/${pet.dateOfBirth.month}/${pet.dateOfBirth.year}'),
      _InfoItem(icon: Icons.monitor_weight_outlined, label: 'Weight', value: pet.weight != null ? '${pet.weight} kg' : 'N/A'),
      _InfoItem(icon: Icons.pets, label: 'Species', value: pet.species),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: items.map((item) => _buildInfoCard(context, item)).toList(),
    );
  }

  Widget _buildInfoCard(BuildContext context, _InfoItem item) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(item.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthActions(BuildContext context, PetModel pet) {
    final actions = [
      {'icon': Icons.medical_services_outlined, 'label': 'Medical Records', 'route': '/medical'},
      {'icon': Icons.vaccines, 'label': 'Vaccinations', 'route': '/vaccinations'},
      {'icon': Icons.calendar_today_outlined, 'label': 'Appointments', 'route': '/appointments'},
      {'icon': Icons.summarize_outlined, 'label': 'Reports', 'route': '/reports'},
    ];
    return Column(
      children: actions.map((a) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(a['icon'] as IconData, color: Theme.of(context).colorScheme.primary, size: 20),
        ),
        title: Text(a['label'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(a['route'] as String),
      )).toList(),
    );
  }

  void _confirmDelete(BuildContext context, PetModel pet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Pet'),
        content: Text('Are you sure you want to remove ${pet.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final uid = context.read<AppAuthProvider>().user!.id;
              await context.read<PetProvider>().deletePet(uid, pet.id);
              if (context.mounted) context.go('/pets');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem({required this.icon, required this.label, required this.value});
}
