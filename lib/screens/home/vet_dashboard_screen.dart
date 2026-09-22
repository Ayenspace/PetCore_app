import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_bottom_nav.dart';

List<AppointmentModel> vetUpcomingAppointments(List<AppointmentModel> appointments) {
  final now = DateTime.now();
  final items = appointments
      .where(
        (appointment) =>
            appointment.status == AppointmentStatus.upcoming &&
            appointment.dateTime.isAfter(now),
      )
      .toList();
  items.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  return items;
}

List<AppointmentModel> vetOverdueAppointments(List<AppointmentModel> appointments) {
  final items = appointments
      .where((appointment) => appointment.status == AppointmentStatus.overdue)
      .toList();
  items.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  return items;
}

class VetDashboardScreen extends StatefulWidget {
  const VetDashboardScreen({super.key});

  @override
  State<VetDashboardScreen> createState() => _VetDashboardScreenState();
}

class _VetDashboardScreenState extends State<VetDashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    final user = context.read<AppAuthProvider>().user;
    if (user != null) {
      context.read<AppointmentProvider>().listenToVetAppointments(user.id);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AppAuthProvider>();
    final router = GoRouter.of(context);
    await auth.logout();
    router.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().user;
    final appointments = context.watch<AppointmentProvider>().vetAppointments;
    final upcoming = vetUpcomingAppointments(appointments);
    final overdue = vetOverdueAppointments(appointments);
    final completed = appointments
        .where((appointment) => appointment.status == AppointmentStatus.completed)
        .length;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Dr. ${user?.name ?? 'Veterinarian'}'),
        leading: IconButton(
          tooltip: 'Menu',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: const Icon(Icons.menu),
        ),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      drawer: _VetDrawer(user: user, onLogout: () => _logout(context)),
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
                  label: 'Overdue',
                  value: '${overdue.length}',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.red,
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
            if (overdue.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Overdue appointments',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
              ),
              const SizedBox(height: 10),
              ...overdue.take(8).map(
                    (appointment) => _AppointmentPreview(
                      appointment: appointment,
                      accentColor: Colors.red,
                    ),
                  ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/vet/reports'),
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Appointment analytics and reports'),
            ),
            const SizedBox(height: 20),
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
  final Color accentColor;

  const _AppointmentPreview({
    required this.appointment,
    this.accentColor = const Color(0xFF6A1B9A),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: accentColor.withValues(alpha: 0.03),
      child: ListTile(
        onTap: () => context.push('/appointments/${appointment.id}'),
        leading: CircleAvatar(
          backgroundColor: accentColor.withValues(alpha: 0.12),
          child: Icon(Icons.pets_outlined, color: accentColor),
        ),
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

class _VetDrawer extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onLogout;

  const _VetDrawer({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6A1B9A);

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: user?.photoUrl != null
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? const Icon(Icons.person, color: primary, size: 28)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? 'Veterinarian',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/vet');
                  },
                ),
                _DrawerItem(
                  icon: Icons.calendar_month_outlined,
                  label: 'Appointments',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/appointments');
                  },
                ),
                _DrawerItem(
                  icon: Icons.analytics_outlined,
                  label: 'Reports',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/vet/reports');
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                _DrawerItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/profile');
                  },
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/settings');
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _DrawerItem(
                    icon: Icons.logout,
                    label: 'Log Out',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      onLogout();
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'PetCore v1.0.0',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(
        label,
        style: TextStyle(color: c, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      dense: true,
      horizontalTitleGap: 8,
    );
  }
}