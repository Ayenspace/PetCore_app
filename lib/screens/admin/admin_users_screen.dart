import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/admin_navigation.dart';
import '../../widgets/admin_drawer.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _updatingUserId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminId = context.watch<AppAuthProvider>().user?.id;

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(title: const Text('Users')),
      bottomNavigationBar: const AdminNavigation(selectedIndex: 1),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('users').onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load users: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users =
              _usersFrom(
                  snapshot.data!.snapshot.value,
                ).where((user) => _matches(user)).toList()
                ..sort((a, b) => a.name.compareTo(b.name));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.clear),
                            onPressed: _searchController.clear,
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: users.isEmpty
                    ? const Center(child: Text('No users found.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: users.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final isCurrentAdmin = user.id == adminId;
                          return _UserTile(
                            user: user,
                            enabled: !isCurrentAdmin && _updatingUserId == null,
                            onRoleChanged: (role) => _changeRole(user.id, role),
                            isUpdating: _updatingUserId == user.id,
                            isCurrentAdmin: isCurrentAdmin,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _matches(_AdminUser user) {
    if (_query.isEmpty) return true;
    return user.name.toLowerCase().contains(_query) ||
        user.email.toLowerCase().contains(_query);
  }

  Future<void> _changeRole(String userId, String role) async {
    setState(() => _updatingUserId = userId);
    try {
      await FirebaseDatabase.instance.ref('users/$userId/role').set(role);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User role updated.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update role: $error')));
    } finally {
      if (mounted) setState(() => _updatingUserId = null);
    }
  }

  static List<_AdminUser> _usersFrom(Object? value) {
    if (value is! Map) return <_AdminUser>[];
    return value.entries.map((entry) {
      final data = _asMap(entry.value);
      return _AdminUser(
        id: entry.key.toString(),
        name: data['name']?.toString() ?? 'Unnamed user',
        email: data['email']?.toString() ?? 'No email',
        role: data['role']?.toString() ?? 'petOwner',
      );
    }).toList();
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is! Map) return <String, dynamic>{};
    return Map<String, dynamic>.from(
      value.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}

class _AdminUser {
  final String id;
  final String name;
  final String email;
  final String role;

  const _AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
}

class _UserTile extends StatelessWidget {
  final _AdminUser user;
  final bool enabled;
  final bool isUpdating;
  final bool isCurrentAdmin;
  final ValueChanged<String> onRoleChanged;

  const _UserTile({
    required this.user,
    required this.enabled,
    required this.isUpdating,
    required this.isCurrentAdmin,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(user.email, overflow: TextOverflow.ellipsis),
                  if (isCurrentAdmin)
                    Text(
                      'Current account',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            if (isUpdating)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCurrentAdmin && user.role != 'admin')
                    IconButton(
                      tooltip: 'Preview account',
                      icon: const Icon(Icons.visibility_outlined),
                      onPressed: () => context.push(
                        '/admin/users/${user.id}/preview',
                      ),
                    ),
                  DropdownButton<String>(
                    value: _validRole(user.role),
                    onChanged: enabled
                        ? (role) {
                            if (role != null) onRoleChanged(role);
                          }
                        : null,
                    items: const [
                      DropdownMenuItem(
                        value: 'petOwner',
                        child: Text('Pet owner'),
                      ),
                      DropdownMenuItem(value: 'vet', child: Text('Vet')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static String _validRole(String role) {
    return const {'petOwner', 'vet', 'admin'}.contains(role)
        ? role
        : 'petOwner';
  }
}
