import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PetsScreen extends StatelessWidget {
  const PetsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Pets')),
      bottomNavigationBar: _BottomNav(currentIndex: 1),
      body: const Center(child: Text('Pets coming soon')),
    );
  }
}

class AddPetScreen extends StatelessWidget {
  const AddPetScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Add Pet')), body: const Center(child: Text('Add Pet')));
}

class PetDetailsScreen extends StatelessWidget {
  final String petId;
  const PetDetailsScreen({super.key, required this.petId});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Pet Details')), body: Center(child: Text('Pet $petId')));
}

class EditPetScreen extends StatelessWidget {
  final String petId;
  const EditPetScreen({super.key, required this.petId});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Edit Pet')), body: Center(child: Text('Edit Pet $petId')));
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
