import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/admin_navigation.dart';
import '../../widgets/admin_drawer.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().listen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().user;
    if (user?.isAdmin != true) {
      return const Scaffold(
        body: Center(child: Text('You do not have access to this page.')),
      );
    }

    final admin = context.watch<AdminProvider>();

    if (!admin.loaded) {
      return Scaffold(
        drawer: const AdminDrawer(),
        appBar: AppBar(title: const Text('Admin Dashboard')),
        bottomNavigationBar: const AdminNavigation(selectedIndex: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final users = admin.users;
    final appointments = admin.appointments;
    final marketplace = admin.marketplace;
    final vetCount = users.values
        .map(_asMap)
        .where((v) => v['role'] == 'vet')
        .length;
    final ownerCount = users.values
        .map(_asMap)
        .where((v) => v['role'] == 'petOwner')
        .length;

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      bottomNavigationBar: const AdminNavigation(selectedIndex: 0),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Welcome, ${user!.name}',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Here is the current PetCore overview.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 600 ? 4 : 2;
              return GridView.count(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.55,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _MetricCard(
                    icon: Icons.people_outline,
                    label: 'Total users',
                    value: '${users.length}',
                    color: Colors.blue,
                  ),
                  _MetricCard(
                    icon: Icons.pets,
                    label: 'Pet owners',
                    value: '$ownerCount',
                    color: Colors.teal,
                  ),
                  _MetricCard(
                    icon: Icons.medical_services_outlined,
                    label: 'Veterinarians',
                    value: '$vetCount',
                    color: Colors.orange,
                  ),
                  _MetricCard(
                    icon: Icons.calendar_month_outlined,
                    label: 'Appointments',
                    value: '${_countNested(appointments)}',
                    color: Colors.purple,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Text('Management', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _AdminActionTile(
            icon: Icons.people_alt_outlined,
            title: 'Users',
            subtitle: '${users.length} registered accounts',
            onTap: () => context.push('/admin/users'),
          ),
          _AdminActionTile(
            icon: Icons.calendar_today_outlined,
            title: 'Appointments',
            subtitle: '${_countNested(appointments)} appointments across owners',
            onTap: () => context.push('/admin/appointments'),
          ),
          _AdminActionTile(
            icon: Icons.storefront_outlined,
            title: 'Marketplace',
            subtitle: '${marketplace.length} listings',
            onTap: () => context.push('/marketplace'),
          ),
          _AdminActionTile(
            icon: Icons.analytics_outlined,
            title: 'Reports',
            subtitle: 'User growth and platform analytics',
            onTap: () => context.push('/admin/reports'),
          ),
        ],
      ),
    );
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is! Map) return {};
    return Map<String, dynamic>.from(
      value.map((k, v) => MapEntry(k.toString(), v)),
    );
  }

  static int _countNested(Map<String, dynamic> value) {
    return value.values.fold<int>(0, (total, child) => total + _asMap(child).length);
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _AdminActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
