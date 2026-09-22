import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../widgets/admin_navigation.dart';
import '../../widgets/admin_drawer.dart';

class AdminAccountPreviewScreen extends StatelessWidget {
  final String userId;

  const AdminAccountPreviewScreen({super.key, required this.userId});

  Future<Map<String, Object?>> _loadPreview() async {
    final database = FirebaseDatabase.instance;
    final results = await Future.wait([
      database.ref('users/$userId').get(),
      database.ref('pets/$userId').get(),
      database.ref('appointments/$userId').get(),
      database.ref('vet_appointments/$userId').get(),
    ]);
    return {
      'user': _asMap(results[0].value),
      'pets': _asMap(results[1].value),
      'ownerAppointments': _asMap(results[2].value),
      'vetAppointments': _asMap(results[3].value),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Account preview'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'READ ONLY',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AdminNavigation(selectedIndex: 1),
      body: FutureBuilder<Map<String, Object?>>(
        future: _loadPreview(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Could not load account: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data!['user'] as Map<String, dynamic>;
          final role = user['role']?.toString() ?? 'petOwner';
          final pets = snapshot.data!['pets'] as Map<String, dynamic>;
          final ownerAppointments =
              snapshot.data!['ownerAppointments'] as Map<String, dynamic>;
          final vetAppointments =
              snapshot.data!['vetAppointments'] as Map<String, dynamic>;
          final appointments = role == 'vet'
              ? vetAppointments
              : ownerAppointments;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Text(
                      (user['name']?.toString().isNotEmpty ?? false)
                          ? user['name'].toString()[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name']?.toString() ?? 'Unnamed user',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(user['email']?.toString() ?? 'No email'),
                        Text(_roleLabel(role)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _PreviewMetric(
                    label: role == 'vet' ? 'Appointments' : 'Pets',
                    value: role == 'vet'
                        ? '${appointments.length}'
                        : '${pets.length}',
                    icon: role == 'vet'
                        ? Icons.calendar_month_outlined
                        : Icons.pets_outlined,
                  ),
                  const SizedBox(width: 12),
                  _PreviewMetric(
                    label: role == 'vet' ? 'Clinic' : 'Appointments',
                    value: role == 'vet'
                        ? (user['clinicName']?.toString() ?? 'Not set')
                        : '${appointments.length}',
                    icon: role == 'vet'
                        ? Icons.local_hospital_outlined
                        : Icons.event_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                role == 'vet' ? 'Assigned appointments' : 'Pets',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              if (role != 'vet')
                ...pets.values.map((pet) {
                  final data = _asMap(pet);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.pets_outlined),
                    title: Text(data['name']?.toString() ?? 'Unnamed pet'),
                    subtitle: Text(data['species']?.toString() ?? ''),
                  );
                })
              else
                ...appointments.values.map((appointment) {
                  final data = _asMap(appointment);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(data['petName']?.toString() ?? 'Unknown pet'),
                    subtitle: Text(data['service']?.toString() ?? ''),
                    trailing: Text(data['status']?.toString() ?? ''),
                  );
                }),
              if ((role == 'vet' ? appointments : pets).isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No data available')),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _roleLabel(String role) {
    switch (role) {
      case 'vet':
        return 'Veterinarian';
      case 'admin':
        return 'Administrator';
      default:
        return 'Pet owner';
    }
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is! Map) return <String, dynamic>{};
    return Map<String, dynamic>.from(
      value.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _PreviewMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}