import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/appointment_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/vaccination_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appointments = context.watch<AppointmentProvider>().appointments;
    final vaccinations = context.watch<VaccinationProvider>().vaccinations;
    final reminders = context.watch<ReminderProvider>().reminders;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<_NotificationItem> items = [];

    // Overdue reminders
    for (final r in reminders) {
      if (!r.isCompleted && r.dateTime.isBefore(now)) {
        items.add(_NotificationItem(
          icon: Icons.alarm_off,
          color: Colors.red,
          title: 'Overdue Reminder: ${r.title}',
          subtitle: r.petName != null ? 'For ${r.petName}' : 'No pet assigned',
          time: r.dateTime,
          onTap: () => context.push('/reminders'),
        ));
      }
    }

    // Overdue vaccinations
    for (final v in vaccinations) {
      if (v.isDue) {
        items.add(_NotificationItem(
          icon: Icons.vaccines,
          color: Colors.red,
          title: 'Overdue Vaccine: ${v.vaccineName}',
          subtitle: v.petName,
          time: v.nextDueDate!,
          onTap: () => context.push('/vaccinations'),
        ));
      }
    }

    // Due soon vaccinations (within 30 days)
    for (final v in vaccinations) {
      if (!v.isDue &&
          v.nextDueDate != null &&
          v.nextDueDate!.isAfter(now) &&
          v.nextDueDate!.isBefore(now.add(const Duration(days: 30)))) {
        items.add(_NotificationItem(
          icon: Icons.vaccines,
          color: Colors.orange,
          title: 'Vaccine Due Soon: ${v.vaccineName}',
          subtitle: v.petName,
          time: v.nextDueDate!,
          onTap: () => context.push('/vaccinations'),
        ));
      }
    }

    // Today's appointments
    for (final a in appointments) {
      final apptDay = DateTime(a.dateTime.year, a.dateTime.month, a.dateTime.day);
      if (apptDay == today && a.status.name == 'upcoming') {
        items.add(_NotificationItem(
          icon: Icons.event,
          color: Colors.purple,
          title: 'Appointment Today: ${a.service}',
          subtitle: '${a.petName} • ${a.vetName}',
          time: a.dateTime,
          onTap: () => context.push('/appointments/${a.id}'),
        ));
      }
    }

    // Upcoming appointments in next 3 days
    for (final a in appointments) {
      final apptDay = DateTime(a.dateTime.year, a.dateTime.month, a.dateTime.day);
      if (apptDay.isAfter(today) &&
          apptDay.isBefore(today.add(const Duration(days: 3))) &&
          a.status.name == 'upcoming') {
        items.add(_NotificationItem(
          icon: Icons.event_available,
          color: Colors.blue,
          title: 'Upcoming: ${a.service}',
          subtitle: '${a.petName} • ${a.vetName}',
          time: a.dateTime,
          onTap: () => context.push('/appointments/${a.id}'),
        ));
      }
    }

    items.sort((a, b) => a.time.compareTo(b.time));

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: items.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No notifications', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = items[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item.color.withValues(alpha: 0.15),
                      child: Icon(item.icon, color: item.color, size: 20),
                    ),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 12)),
                    trailing: Text(
                      _formatTime(item.time),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    onTap: item.onTap,
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(DateTime(now.year, now.month, now.day));
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays == -1) return 'Yesterday';
    if (diff.inDays < 0) return '${diff.inDays.abs()}d ago';
    return 'In ${diff.inDays}d';
  }
}

class _NotificationItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final DateTime time;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.onTap,
  });
}
