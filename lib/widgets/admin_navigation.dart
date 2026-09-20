import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminNavigation extends StatelessWidget {
  final int selectedIndex;

  const AdminNavigation({super.key, required this.selectedIndex});

  void _navigate(BuildContext context, int index) {
    final routes = ['/admin', '/admin/users', '/admin/reports', '/marketplace'];
    if (index != selectedIndex) context.go(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _navigate(context, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Users',
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Reports',
        ),
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'Marketplace',
        ),
      ],
    );
  }
}
