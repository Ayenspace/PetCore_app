import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_bottom_nav.dart';

class VetDashboardScreen extends StatefulWidget {
  const VetDashboardScreen({super.key});

  @override
  State<VetDashboardScreen> createState() => _VetDashboardScreenState();
}

class _VetDashboardScreenState extends State<VetDashboardScreen> {
  @override
  void initState() {
    super.initState();
    final user = context.read<AppAuthProvider>().user;
    if (user != null) {
      context.read<AppointmentProvider>().listenToVetAppointments(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().user;
    final appointments = context.watch<AppointmentProvider>().vetAppointments;
    final upcoming = appointments
        .where((appointment) =>
            appointment.status == AppointmentStatus.upcoming ||
            appointment.status == AppointmentStatus.overdue)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final completed = appointments
        .where((appointment) => appointment.status == AppointmentStatus.completed)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dr. ${user?.name ?? 'Veterinarian'}'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: RefreshIndicator(
        onRefresh: () async {
          final currentUser = context.read<AppAuthProvider>().user;
          if (currentUser != null) {
            context.read<AppointmentProvider>().listenToVetAppointments(
              currentUser.id,
            );
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Your practice overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MetricCard(
                  label: 'Total',
                  value: '${appointments.length}',
                  icon: Icons.calendar_month_outlined,
                  color: Colors.indigo,
                ),
                const SizedBox(width: 10),
                _MetricCard(
                  label: 'Upcoming',
                  value: '${upcoming.length}',
                  icon: Icons.schedule_outlined,
                  color: Colors.orange,
                ),
                const SizedBox(width: 10),
                _MetricCard(
                  label: 'Completed',
                  value: '$completed',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Upcoming appointments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            if (upcoming.isEmpty)
              const _EmptyAppointments()
            else
              ...upcoming.take(8).map(
                    (appointment) => _AppointmentPreview(
                      appointment: appointment,
                    ),
                  ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.go('/appointments'),
              icon: const Icon(Icons.calendar_today_outlined),
              label: const Text('View all appointments'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}

class _AppointmentPreview extends StatelessWidget {
  final AppointmentModel appointment;

  const _AppointmentPreview({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.push('/appointments/${appointment.id}'),
        leading: const CircleAvatar(child: Icon(Icons.pets_outlined)),
        title: Text(appointment.petName),
        subtitle: Text(
          '${appointment.service} • ${appointment.dateTime.day}/${appointment.dateTime.month}/${appointment.dateTime.year} at ${TimeOfDay.fromDateTime(appointment.dateTime).format(context)}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _EmptyAppointments extends StatelessWidget {
  const _EmptyAppointments();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_available_outlined, size: 40),
          SizedBox(height: 8),
          Text('No upcoming appointments'),
        ],
      ),
    );
  }
}