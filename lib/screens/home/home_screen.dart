import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_providers.dart';
import '../../providers/vaccination_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/medical_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final uid = context.read<AppAuthProvider>().user?.id;
    if (uid != null) {
      context.read<PetProvider>().listenToPets(uid);
      context.read<AppointmentProvider>().listenToAppointments(uid);
      context.read<VaccinationProvider>().listenToVaccinations(uid);
      context.read<MedicalProvider>().listenToRecords(uid);
      context.read<ReminderProvider>().listenToReminders(uid);
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
    final auth = context.watch<AppAuthProvider>();
    final user = auth.user;
    final theme = Theme.of(context);
    final firstName = user?.name.split(' ').first ?? 'there';

    final petCount = context.watch<PetProvider>().pets.length;
    final upcomingAppointments = context.watch<AppointmentProvider>()
        .appointments
        .where((a) => a.status == AppointmentStatus.upcoming && a.dateTime.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final dueVaccineCount = context.watch<VaccinationProvider>().overdue.length
        + context.watch<VaccinationProvider>().dueSoon.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: _BottomNav(currentIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, firstName, user?.photoUrl),
              const SizedBox(height: 24),
              _buildStatsRow(context, petCount, upcomingAppointments.length, dueVaccineCount),
              const SizedBox(height: 28),
              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildQuickActions(context),
              const SizedBox(height: 28),
              Text(
                'Upcoming Appointments',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildUpcomingAppointments(context, upcomingAppointments),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String firstName,
    String? photoUrl,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF6A1B9A), // Purple background
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $firstName 👋',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'How are your pets doing?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
              ),

              // Logout button
              IconButton(
                onPressed: () => _logout(context),
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
                ),
                tooltip: 'Logout',
              ),

              GestureDetector(
                onTap: () => context.push('/profile'),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child:
                      photoUrl == null
                          ? const Icon(
                              Icons.person,
                              color: Color(0xFF6A1B9A),
                              size: 20,
                            )
                          : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, int petCount, int appointmentCount, int dueVaccines) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.pets,
            label: 'My Pets',
            value: '$petCount',
            color: const Color(0xFF6A1B9A),
            onTap: () => context.go('/pets'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_today,
            label: 'Appointments',
            value: '$appointmentCount',
            color: const Color(0xFF1565C0),
            onTap: () => context.go('/appointments'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.vaccines,
            label: 'Due Vaccines',
            value: '$dueVaccines',
            color: dueVaccines > 0 ? Colors.red.shade700 : const Color(0xFF2E7D32),
            onTap: () => context.go('/vaccinations'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.add_circle_outline,
        label: 'Add Pet',
        color: const Color(0xFF6A1B9A),
        onTap: () => context.push('/pets/add'),
      ),
      _QuickAction(
        icon: Icons.event_available,
        label: 'Book Appointment',
        color: const Color(0xFF1565C0),
        onTap: () => context.push('/appointments/add'),
      ),
      _QuickAction(
        icon: Icons.medical_services_outlined,
        label: 'Medical Record',
        color: const Color(0xFFC62828),
        onTap: () => context.push('/medical/add'),
      ),
      _QuickAction(
        icon: Icons.vaccines,
        label: 'Add Vaccine',
        color: const Color(0xFF2E7D32),
        onTap: () => context.push('/vaccinations/add'),
      ),
      _QuickAction(
        icon: Icons.alarm,
        label: 'Set Reminder',
        color: const Color(0xFFE65100),
        onTap: () => context.push('/reminders'),
      ),
      _QuickAction(
        icon: Icons.storefront_outlined,
        label: 'Marketplace',
        color: const Color(0xFF00695C),
        onTap: () => context.go('/marketplace'),
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1,
      children: actions.map((a) => _QuickActionCard(action: a)).toList(),
    );
  }

  Widget _buildUpcomingAppointments(BuildContext context, List<AppointmentModel> appointments) {
    if (appointments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: Colors.grey.shade400, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No upcoming appointments', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => context.push('/appointments/add'),
                  child: Text(
                    'Book one now →',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final cards = appointments.take(3).map((appt) {
        final theme = Theme.of(context);
        final isToday = appt.dateTime.day == DateTime.now().day &&
            appt.dateTime.month == DateTime.now().month &&
            appt.dateTime.year == DateTime.now().year;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: isToday ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)) : null,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.calendar_today, color: theme.colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appt.petName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(appt.service, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isToday ? 'Today' : '${appt.dateTime.day}/${appt.dateTime.month}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isToday ? theme.colorScheme.primary : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${appt.dateTime.hour.toString().padLeft(2, '0')}:${appt.dateTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList();

    return Column(
      children: [
        ...cards,
        if (appointments.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              onTap: () => context.go('/appointments'),
              child: Text(
                'View all ${appointments.length} appointments →',
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;

  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: action.color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: action.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
    final theme = Theme.of(context);

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/pets');
            break;
          case 2:
            context.go('/appointments');
            break;
          case 3:
            context.go('/marketplace');
            break;
          case 4:
            context.go('/profile');
            break;
        }
      },
      indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.pets_outlined),
          selectedIcon: Icon(Icons.pets),
          label: 'Pets',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today),
          label: 'Appointments',
        ),
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'Market',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}