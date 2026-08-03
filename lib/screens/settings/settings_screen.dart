import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/authentication.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().user;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Account ──────────────────────────────────────────────
          _SectionHeader('Account'),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
              child: user?.photoUrl == null ? Text(user?.name[0].toUpperCase() ?? '?') : null,
            ),
            title: Text(user?.name ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(user?.email ?? '—'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/edit'),
          ),
          const Divider(height: 1),

          // ── Appearance ───────────────────────────────────────────
          _SectionHeader('Appearance'),
          SwitchListTile(
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            title: const Text('Dark Mode'),
            value: isDark,
            onChanged: (_) => themeProvider.toggleTheme(),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(themeProvider.themeMode.name[0].toUpperCase() + themeProvider.themeMode.name.substring(1)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(context, themeProvider),
          ),
          const Divider(height: 1),

          // ── Security ─────────────────────────────────────────────
          _SectionHeader('Security'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePassword(context, user?.email ?? ''),
          ),
          const Divider(height: 1),

          // ── Notifications ────────────────────────────────────────
          _SectionHeader('Notifications'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/notifications'),
          ),
          const Divider(height: 1),

          // ── About ────────────────────────────────────────────────
          _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(height: 1),

          // ── Danger Zone ──────────────────────────────────────────
          _SectionHeader('Account Actions'),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red)),
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context, ThemeProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Choose Theme', style: TextStyle(fontWeight: FontWeight.bold))),
            ...ThemeMode.values.map((mode) => ListTile(
              leading: Icon(
                provider.themeMode == mode ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(mode.name[0].toUpperCase() + mode.name.substring(1)),
              onTap: () {
                provider.setTheme(mode);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Text('A password reset link will be sent to:\n$email'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AuthService().resetPassword(email);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset email sent.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AppAuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.2,
          ),
        ),
      );
}
