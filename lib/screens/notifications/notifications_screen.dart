import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/marketplace_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/vaccination_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AppAuthProvider>().user;
      if (user == null) return;
      context.read<AppointmentProvider>().listenToAppointments(user.id);
      if (user.isVet) {
        context.read<AppointmentProvider>().listenToVetAppointments(user.id);
      }
      context.read<MarketplaceProvider>().listenToOrders(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    final appointments = provider.appointments;
    final vetAppointments = provider.vetAppointments;
    final vaccinations = context.watch<VaccinationProvider>().vaccinations;
    final reminders = context.watch<ReminderProvider>().reminders;
    final orders = context.watch<MarketplaceProvider>().orders;
    final currentUser = context.watch<AppAuthProvider>().user;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<_NotificationItem> items = [];

    for (final r in reminders) {
      if (!r.isCompleted && r.dateTime.isBefore(now)) {
        items.add(
          _NotificationItem(
            icon: Icons.alarm_off,
            color: Colors.red,
            title: 'Overdue Reminder: ${r.title}',
            subtitle: r.petName != null
                ? 'For ${r.petName}'
                : 'No pet assigned',
            time: r.dateTime,
            onTap: () => context.push('/reminders'),
          ),
        );
      }
    }

    for (final v in vaccinations) {
      if (v.isDue) {
        items.add(
          _NotificationItem(
            icon: Icons.vaccines,
            color: Colors.red,
            title: 'Overdue Vaccine: ${v.vaccineName}',
            subtitle: v.petName,
            time: v.nextDueDate!,
            onTap: () => context.push('/vaccinations'),
          ),
        );
      }
    }

    for (final v in vaccinations) {
      if (!v.isDue &&
          v.nextDueDate != null &&
          v.nextDueDate!.isAfter(now) &&
          v.nextDueDate!.isBefore(now.add(const Duration(days: 30)))) {
        items.add(
          _NotificationItem(
            icon: Icons.vaccines,
            color: Colors.orange,
            title: 'Vaccine Due Soon: ${v.vaccineName}',
            subtitle: v.petName,
            time: v.nextDueDate!,
            onTap: () => context.push('/vaccinations'),
          ),
        );
      }
    }

    for (final a in appointments) {
      final apptDay = DateTime(
        a.dateTime.year,
        a.dateTime.month,
        a.dateTime.day,
      );
      if (apptDay == today && a.status.name == 'upcoming') {
        items.add(
          _NotificationItem(
            icon: Icons.event,
            color: Colors.purple,
            title: 'Appointment Today: ${a.service}',
            subtitle: '${a.petName} • ${a.vetName}',
            time: a.dateTime,
            onTap: () => context.push('/appointments/${a.id}'),
          ),
        );
      }
    }

    for (final a in appointments) {
      final apptDay = DateTime(
        a.dateTime.year,
        a.dateTime.month,
        a.dateTime.day,
      );
      if (apptDay.isAfter(today) &&
          apptDay.isBefore(today.add(const Duration(days: 3))) &&
          a.status.name == 'upcoming') {
        items.add(
          _NotificationItem(
            icon: Icons.event_available,
            color: Colors.blue,
            title: 'Upcoming: ${a.service}',
            subtitle: '${a.petName} • ${a.vetName}',
            time: a.dateTime,
            onTap: () => context.push('/appointments/${a.id}'),
          ),
        );
      }
    }

    if (currentUser != null) {
      for (final order in orders.where(
        (o) => o.buyerId == currentUser.id || o.sellerId == currentUser.id,
      )) {
        if (order.sellerId == currentUser.id && order.isPending) {
          items.add(
            _NotificationItem(
              icon: Icons.shopping_bag,
              color: Colors.teal,
              title: 'New order request: ${order.listingTitle}',
              subtitle: '${order.buyerName} wants ${order.quantity} item(s)',
              time: order.createdAt,
              onTap: () => context.push('/marketplace/my-listings'),
            ),
          );
        }

        if (order.buyerId == currentUser.id &&
            order.sellerReply != null &&
            order.sellerReply!.trim().isNotEmpty &&
            !order.isAccepted &&
            !order.isRejected) {
          items.add(
            _NotificationItem(
              icon: Icons.reply,
              color: Colors.indigo,
              title: 'Seller replied: ${order.listingTitle}',
              subtitle: order.sellerReply!,
              time: order.createdAt,
              onTap: () => context.push('/marketplace/${order.listingId}'),
            ),
          );
        }

        if (order.buyerId == currentUser.id && order.isAccepted) {
          items.add(
            _NotificationItem(
              icon: Icons.check_circle,
              color: Colors.green,
              title: 'Order accepted: ${order.listingTitle}',
              subtitle:
                  order.sellerReply ?? 'The seller accepted your request.',
              time: order.createdAt,
              onTap: () => context.push('/marketplace/${order.listingId}'),
            ),
          );
        }

        if (order.buyerId == currentUser.id && order.isRejected) {
          items.add(
            _NotificationItem(
              icon: Icons.cancel,
              color: Colors.red,
              title: 'Order rejected: ${order.listingTitle}',
              subtitle:
                  order.sellerReply ?? 'The seller declined your request.',
              time: order.createdAt,
              onTap: () => context.push('/marketplace/${order.listingId}'),
            ),
          );
        }
      }

      if (currentUser.isVet) {
        for (final a in vetAppointments) {
          if (a.status == AppointmentStatus.upcoming) {
            items.add(
              _NotificationItem(
                icon: Icons.local_hospital,
                color: Colors.deepPurple,
                title: 'New appointment assigned: ${a.service}',
                subtitle:
                    '${a.petName} • ${a.dateTime.toLocal().toString().substring(0, 16)}',
                time: a.dateTime,
                onTap: () => context.push('/appointments/${a.id}'),
              ),
            );
          }
        }
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
                  Text(
                    'No notifications',
                    style: TextStyle(color: Colors.grey),
                  ),
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
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: const TextStyle(fontSize: 12),
                    ),
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
