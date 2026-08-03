import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_providers.dart';
import '../../services/authentication.dart';
import '../../services/storage.dart';

// ── Profile Screen ─────────────────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final user = auth.user;
    final petCount = context.watch<PetProvider>().pets.length;
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      bottomNavigationBar: _BottomNav(currentIndex: 4),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white,
                      backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                      child: user.photoUrl == null
                          ? Icon(Icons.person, size: 44, color: theme.colorScheme.primary)
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.isVet ? '🩺 Veterinarian' : '🐾 Pet Owner',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => context.push('/profile/edit'),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: user.isVet
                  ? _VetProfileBody(user: user)
                  : _OwnerProfileBody(user: user, petCount: petCount),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vet Profile Body ───────────────────────────────────────────────────────

class _VetProfileBody extends StatelessWidget {
  final UserModel user;
  const _VetProfileBody({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vet stats: specialization + clinic
        Row(
          children: [
            _StatTile(
              icon: Icons.workspace_premium_outlined,
              label: 'Specialization',
              value: user.specialization?.isNotEmpty == true ? user.specialization! : 'General',
            ),
            const SizedBox(width: 12),
            _StatTile(
              icon: Icons.local_hospital_outlined,
              label: 'Clinic',
              value: user.clinicName?.isNotEmpty == true ? user.clinicName! : 'Not set',
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Contact info
        _SectionLabel('Contact Information'),
        const SizedBox(height: 8),
        _SectionCard(children: [
          _InfoTile(icon: Icons.email_outlined, label: 'Email', value: user.email),
          if (user.phone != null && user.phone!.isNotEmpty)
            _InfoTile(icon: Icons.phone_outlined, label: 'Phone', value: user.phone!),
          if (user.address != null && user.address!.isNotEmpty)
            _InfoTile(icon: Icons.location_on_outlined, label: 'Address', value: user.address!),
        ]),
        const SizedBox(height: 20),

        // Clinic info
        _SectionLabel('Clinic Information'),
        const SizedBox(height: 8),
        _SectionCard(children: [
          _InfoTile(
            icon: Icons.local_hospital_outlined,
            label: 'Clinic Name',
            value: user.clinicName?.isNotEmpty == true ? user.clinicName! : 'Not provided',
          ),
          _InfoTile(
            icon: Icons.workspace_premium_outlined,
            label: 'Specialization',
            value: user.specialization?.isNotEmpty == true ? user.specialization! : 'Not provided',
          ),
          if (user.bio != null && user.bio!.isNotEmpty)
            _InfoTile(icon: Icons.info_outline, label: 'Bio', value: user.bio!),
        ]),
        const SizedBox(height: 20),

        // Quick links — vet relevant
        _SectionLabel('Quick Access'),
        const SizedBox(height: 8),
        _SectionCard(children: [
          _LinkTile(icon: Icons.calendar_today_outlined, label: 'Appointments', onTap: () => GoRouter.of(context).go('/appointments')),
          _LinkTile(icon: Icons.medical_services_outlined, label: 'Medical Records', onTap: () => GoRouter.of(context).go('/medical')),
          _LinkTile(icon: Icons.vaccines, label: 'Vaccinations', onTap: () => GoRouter.of(context).go('/vaccinations')),
          _LinkTile(icon: Icons.bar_chart_outlined, label: 'Reports', onTap: () => GoRouter.of(context).push('/reports')),
          _LinkTile(icon: Icons.settings_outlined, label: 'Settings', onTap: () => GoRouter.of(context).go('/settings')),
        ]),
        const SizedBox(height: 20),

        _LogoutButton(),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Owner Profile Body ─────────────────────────────────────────────────────

class _OwnerProfileBody extends StatelessWidget {
  final UserModel user;
  final int petCount;
  const _OwnerProfileBody({required this.user, required this.petCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatTile(icon: Icons.pets, label: 'My Pets', value: '$petCount'),
            const SizedBox(width: 12),
            _StatTile(icon: Icons.alternate_email, label: 'Username', value: user.email.split('@').first),
          ],
        ),
        const SizedBox(height: 20),

        _SectionCard(children: [
          _InfoTile(icon: Icons.email_outlined, label: 'Email', value: user.email),
          if (user.phone != null && user.phone!.isNotEmpty)
            _InfoTile(icon: Icons.phone_outlined, label: 'Phone', value: user.phone!),
          if (user.address != null && user.address!.isNotEmpty)
            _InfoTile(icon: Icons.location_on_outlined, label: 'Address', value: user.address!),
          if (user.bio != null && user.bio!.isNotEmpty)
            _InfoTile(icon: Icons.info_outline, label: 'Bio', value: user.bio!),
        ]),
        const SizedBox(height: 20),

        _SectionCard(children: [
          _LinkTile(icon: Icons.pets, label: 'My Pets', onTap: () => GoRouter.of(context).go('/pets')),
          _LinkTile(icon: Icons.calendar_today_outlined, label: 'Appointments', onTap: () => GoRouter.of(context).go('/appointments')),
          _LinkTile(icon: Icons.medical_services_outlined, label: 'Medical Records', onTap: () => GoRouter.of(context).go('/medical')),
          _LinkTile(icon: Icons.vaccines, label: 'Vaccinations', onTap: () => GoRouter.of(context).go('/vaccinations')),
          _LinkTile(icon: Icons.settings_outlined, label: 'Settings', onTap: () => GoRouter.of(context).go('/settings')),
        ]),
        const SizedBox(height: 20),

        _LogoutButton(),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.1,
        ),
      );
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await context.read<AppAuthProvider>().logout();
          if (context.mounted) GoRouter.of(context).go('/login');
        },
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text('Log Out', style: TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatTile({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis, maxLines: 1),
                  Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) Divider(height: 1, indent: 52, color: Colors.grey.shade100),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      dense: true,
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LinkTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      dense: true,
    );
  }
}

// ── Edit Profile Screen ────────────────────────────────────────────────────

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _bioController;
  late final TextEditingController _clinicController;
  late final TextEditingController _specializationController;

  XFile? _pickedImage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppAuthProvider>().user!;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phone ?? '');
    _addressController = TextEditingController(text: user.address ?? '');
    _bioController = TextEditingController(text: user.bio ?? '');
    _clinicController = TextEditingController(text: user.clinicName ?? '');
    _specializationController = TextEditingController(text: user.specialization ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _clinicController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _pickedImage = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final auth = context.read<AppAuthProvider>();
      final user = auth.user!;

      String? photoUrl = user.photoUrl;
      if (_pickedImage != null) {
        photoUrl = await StorageService().uploadProfilePhoto(user.id, _pickedImage!);
      }

      final updated = user.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        photoUrl: photoUrl,
        clinicName: user.isVet ? (_clinicController.text.trim().isEmpty ? null : _clinicController.text.trim()) : null,
        specialization: user.isVet ? (_specializationController.text.trim().isEmpty ? null : _specializationController.text.trim()) : null,
      );

      await AuthService().updateUser(updated);

      // Refresh auth provider user
      await auth.refreshUser();

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().user!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar picker
              GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      backgroundImage: _pickedImage != null
                          ? (kIsWeb ? NetworkImage(_pickedImage!.path) : FileImage(File(_pickedImage!.path))) as ImageProvider
                          : (user.photoUrl != null ? NetworkImage(user.photoUrl!) as ImageProvider : null),
                      child: (_pickedImage == null && user.photoUrl == null)
                          ? Icon(Icons.person, size: 52, color: theme.colorScheme.primary)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone (optional)', prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Address (optional)', prefixIcon: Icon(Icons.location_on_outlined)),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bioController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio (optional)',
                  prefixIcon: Icon(Icons.info_outline),
                  alignLabelWithHint: true,
                ),
              ),

              // Vet-only fields
              if (user.isVet) ...[
                const SizedBox(height: 20),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 8),
                Text('Clinic Information', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _clinicController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Clinic Name', prefixIcon: Icon(Icons.local_hospital_outlined)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _specializationController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Specialization', prefixIcon: Icon(Icons.workspace_premium_outlined)),
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom Nav ─────────────────────────────────────────────────────────────

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
