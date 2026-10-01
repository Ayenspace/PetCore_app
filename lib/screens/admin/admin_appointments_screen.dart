import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/appointment_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin_navigation.dart';
import '../../widgets/admin_drawer.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().listen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    if (!admin.loaded) {
      return Scaffold(
        drawer: const AdminDrawer(),
        appBar: AppBar(title: const Text('Appointments')),
        bottomNavigationBar: const AdminNavigation(selectedIndex: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final appointments = _appointmentsFrom(admin.appointments)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final ownerNames = _ownerNamesFrom(admin.users);

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(title: const Text('Appointments')),
      bottomNavigationBar: const AdminNavigation(selectedIndex: 0),
      body: appointments.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy_outlined, size: 56),
                  SizedBox(height: 12),
                  Text('No appointments found'),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return _AppointmentTile(
                  appointment: appointment,
                  ownerName:
                      ownerNames[appointment.ownerId] ?? 'Unknown owner',
                );
              },
            ),
    );
  }

  static List<AppointmentModel> _appointmentsFrom(
      Map<String, dynamic> value) {
    final appointments = <AppointmentModel>[];
    for (final ownerEntry in value.values) {
      if (ownerEntry is! Map) continue;
      for (final entry in ownerEntry.entries) {
        if (entry.value is! Map) continue;
        try {
          final data = Map<String, dynamic>.from(
            (entry.value as Map).map((k, v) => MapEntry(k.toString(), v)),
          );
          appointments.add(AppointmentModel.fromMap(data));
        } catch (_) {}
      }
    }
    return appointments;
  }

  static Map<String, String> _ownerNamesFrom(Map<String, dynamic> usersMap) {
    final names = <String, String>{};
    for (final entry in usersMap.entries) {
      final data = entry.value;
      if (data is! Map) continue;
      final name = data['name']?.toString().trim();
      if (name != null && name.isNotEmpty) names[entry.key] = name;
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  static String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/${dt.year} at $hour:$minute $period';
  }
}
