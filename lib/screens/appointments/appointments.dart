import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      bottomNavigationBar: _BottomNav(currentIndex: 2),
      body: const Center(child: Text('Appointments coming soon')),
    );
  }
}

class AddAppointmentScreen extends StatelessWidget {
  const AddAppointmentScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Add Appointment')), body: const Center(child: Text('Add Appointment')));
}

class AppointmentDetailsScreen extends StatelessWidget {
  final String appointmentId;
  const AppointmentDetailsScreen({super.key, required this.appointmentId});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Appointment Details')), body: Center(child: Text('Appointment $appointmentId')));
}

class EditAppointmentScreen extends StatelessWidget {
  final String appointmentId;
  const EditAppointmentScreen({super.key, required this.appointmentId});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Edit Appointment')), body: Center(child: Text('Edit $appointmentId')));
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
