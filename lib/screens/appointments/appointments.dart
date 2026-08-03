import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/appointment_model.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    final uid = context.read<AppAuthProvider>().user?.id;
    if (uid != null) context.read<AppointmentProvider>().listenToAppointments(uid);
  }

  @override
  Widget build(BuildContext context) {
    final appointments = context.watch<AppointmentProvider>().appointments;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/appointments/add'),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(currentIndex: 2),
      floatingActionButton: appointments.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => context.push('/appointments/add'),
              child: const Icon(Icons.add),
            )
          : null,
      body: appointments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No appointments yet', style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/appointments/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Book Appointment'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              itemBuilder: (context, index) => _AppointmentCard(appointment: appointments[index]),
            ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = appointment.status == AppointmentStatus.upcoming
        ? Colors.blue
        : appointment.status == AppointmentStatus.completed
            ? Colors.green
            : Colors.red;

    return GestureDetector(
      onTap: () => context.push('/appointments/${appointment.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
          ),
          title: Text(appointment.petName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${appointment.service} • ${appointment.dateTime.day}/${appointment.dateTime.month}/${appointment.dateTime.year}'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              appointment.status.name,
              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});
  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0: context.go('/home'); break;
          case 1: context.go('/pets'); break;
          case 2: context.go('/appointments'); break;
          case 3: context.go('/marketplace'); break;
          case 4: context.go('/profile'); break;
        }
      },
      indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets), label: 'Pets'),
        NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Appointments'),
        NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Market'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
