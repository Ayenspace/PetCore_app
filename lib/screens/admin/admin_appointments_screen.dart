import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../models/appointment_model.dart';
import '../../widgets/admin_navigation.dart';
import '../../widgets/admin_drawer.dart';

class AdminAppointmentsScreen extends StatelessWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(title: const Text('Appointments')),
      bottomNavigationBar: const AdminNavigation(selectedIndex: 0),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('appointments').onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Could not load appointments: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointments = _appointmentsFrom(snapshot.data!.snapshot.value)
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

          if (appointments.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy_outlined, size: 56),
                  SizedBox(height: 12),
                  Text('No appointments found'),
                ],
              ),
            );
          }

          return StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance.ref('users').onValue,
            builder: (context, usersSnapshot) {
              if (!usersSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final ownerNames = _ownerNamesFrom(
                usersSnapshot.data!.snapshot.value,
              );
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: appointments.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  return _AppointmentTile(
                    appointment: appointment,
                    ownerName: ownerNames[appointment.ownerId] ?? 'Unknown owner',
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static List<AppointmentModel> _appointmentsFrom(Object? value) {
    if (value is! Map) return <AppointmentModel>[];
    final appointments = <AppointmentModel>[];

    for (final ownerEntry in value.entries) {
      final ownerAppointments = ownerEntry.value;
      if (ownerAppointments is! Map) continue;
      for (final entry in ownerAppointments.entries) {
        if (entry.value is! Map) continue;
        try {
          final data = Map<String, dynamic>.from(
            (entry.value as Map).map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          );
          appointments.add(AppointmentModel.fromMap(data));
        } catch (_) {
          // Ignore malformed legacy records and keep the admin list usable.
        }
      }
    }
    return appointments;
  }

  static Map<String, String> _ownerNamesFrom(Object? value) {
    if (value is! Map) return <String, String>{};
    final names = <String, String>{};
    for (final entry in value.entries) {
      if (entry.value is! Map) continue;
      final data = Map<String, dynamic>.from(
        (entry.value as Map).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
      final name = data['name']?.toString().trim();
      if (name != null && name.isNotEmpty) {
        names[entry.key.toString()] = name;
      }
    }
    return names;
  }
}

class _AppointmentTile extends StatelessWidget {
  final AppointmentModel appointment;
  final String ownerName;

  const _AppointmentTile({
    required this.appointment,
    required this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (appointment.status) {
      AppointmentStatus.completed => Colors.green,
      AppointmentStatus.cancelled => Colors.red,
      AppointmentStatus.overdue => Colors.orange,
      AppointmentStatus.upcoming => Colors.blue,
    };

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          child: Icon(Icons.calendar_today_outlined, color: statusColor),
        ),
        title: Text(
          '${appointment.petName} • ${appointment.service}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${_formatDate(appointment.dateTime)}\nVet: ${appointment.vetName}\nOwner: $ownerName',
        ),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            appointment.status.name,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/${dateTime.year} at $hour:$minute $period';
  }
}