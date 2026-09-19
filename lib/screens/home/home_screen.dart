import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/appointment_model.dart';
import '../../models/pet_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_providers.dart';
import '../../providers/vaccination_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/medical_provider.dart';
import '../../models/user_model.dart';
import '../../providers/weight_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    final user = context.read<AppAuthProvider>().user;
    final uid = user?.id;
    if (uid != null) {
      context.read<PetProvider>().listenToPets(uid);
      context.read<AppointmentProvider>().listenToAppointments(uid);
      if (user!.isVet) {
        context.read<AppointmentProvider>().listenToVetAppointments(uid);
      }
      context.read<VaccinationProvider>().listenToVaccinations(uid);
      context.read<MedicalProvider>().listenToRecords(uid);
      context.read<ReminderProvider>().listenToReminders(uid);
      context.read<WeightProvider>().listenToWeights(uid);
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
    final theme = Theme.of(context);
    final user = context.watch<AppAuthProvider>().user;
    final firstName = user?.name.split(' ').first ?? 'there';
    final pets = context.watch<PetProvider>().pets;
    final appointmentProvider = context.watch<AppointmentProvider>();
    final allAppointments = user?.isVet == true
        ? appointmentProvider.vetAppointments
        : appointmentProvider.appointments;
    final vaccinations = context.watch<VaccinationProvider>();
    final reminders = context.watch<ReminderProvider>();
    final now = DateTime.now();
    final pendingReminderCount = reminders.reminders.where((r) {
      if (r.isCompleted) return false;
      final timeUntilReminder = r.dateTime.difference(now);
      return r.dateTime.isBefore(now) || timeUntilReminder.inHours <= 24;
    }).length;

    final upcomingAppts =
        allAppointments
            .where(
              (a) =>
                  a.status == AppointmentStatus.upcoming &&
                  a.dateTime.isAfter(DateTime.now()),
            )
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final overdueAppts = allAppointments
        .where((a) => a.status == AppointmentStatus.overdue)
        .toList();

    final dueVaccines =
        vaccinations.overdue.length + vaccinations.dueSoon.length;
    final overdueReminders = reminders.overdue.length;

    // Today's focus items
    final List<_FocusItem> focusItems = [
      if (overdueAppts.isNotEmpty)
        _FocusItem(
          icon: Icons.warning_amber_rounded,
          color: Colors.red,
          label:
              '${overdueAppts.length} overdue appointment${overdueAppts.length > 1 ? 's' : ''}',
          onTap: () => context.go('/appointments'),
        ),
      if (overdueReminders > 0)
        _FocusItem(
          icon: Icons.alarm_outlined,
          color: Colors.orange,
          label:
              '$overdueReminders overdue reminder${overdueReminders > 1 ? 's' : ''}',
          onTap: () => context.push('/reminders'),
        ),
      if (dueVaccines > 0)
        _FocusItem(
          icon: Icons.vaccines,
          color: Colors.deepOrange,
          label: '$dueVaccines vaccine${dueVaccines > 1 ? 's' : ''} due',
          onTap: () => context.push('/vaccinations'),
        ),
      if (upcomingAppts.isNotEmpty)
        _FocusItem(
          icon: Icons.calendar_today,
          color: Colors.blue,
          label:
              'Next: ${upcomingAppts.first.petName} — ${upcomingAppts.first.service}',
          onTap: () => context.go('/appointments'),
        ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: _BottomNav(currentIndex: 0),
      drawer: _AppDrawer(user: user, onLogout: () => _logout(context)),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(
            context,
            firstName,
            user?.photoUrl,
            pendingReminderCount,
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pet carousel
                _buildPetCarousel(context, pets),
                const SizedBox(height: 20),
                // Today's focus
                if (focusItems.isNotEmpty) ...[
                  _sectionLabel(context, "Today's Focus"),
                  _buildFocusCard(context, focusItems),
                  const SizedBox(height: 20),
                ],
                // Stats row
                _sectionLabel(context, 'Overview'),
                _buildStatsRow(
                  context,
                  pets.length,
                  upcomingAppts.length,
                  dueVaccines,
                ),
                const SizedBox(height: 20),
                // Quick actions
                _sectionLabel(context, 'Quick Actions'),
                _buildQuickActions(context),
                const SizedBox(height: 20),
                // Upcoming appointments
                _sectionLabel(
                  context,
                  user?.isVet == true
                      ? 'Scheduled Appointments'
                      : 'Upcoming Appointments',
                ),
                _buildUpcomingAppointments(
                  context,
                  upcomingAppts,
                  isVet: user?.isVet == true,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    String firstName,
    String? photoUrl,
    int pendingReminderCount,
  ) {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      backgroundColor: theme.colorScheme.primary,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hello, $firstName!',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'How are your pets doing today?',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        onPressed: () => context.push('/notifications'),
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                        ),
                      ),
                      if (pendingReminderCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              pendingReminderCount > 99
                                  ? '99+'
                                  : pendingReminderCount.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    icon: const Icon(Icons.menu, color: Colors.white),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      backgroundImage: photoUrl != null
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl == null
                          ? const Icon(
                              Icons.person,
                              color: Color(0xFF6A1B9A),
                              size: 18,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPetCarousel(BuildContext context, List<PetModel> pets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Pets',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/pets'),
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (pets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => context.push('/pets/add'),
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6A1B9A).withValues(alpha: 0.2),
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: Color(0xFF6A1B9A),
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add your first pet',
                        style: TextStyle(
                          color: Color(0xFF6A1B9A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: pets.length + 1,
              itemBuilder: (context, i) {
                if (i == pets.length) {
                  return _AddPetCard(onTap: () => context.push('/pets/add'));
                }
                return _PetCarouselCard(
                  pet: pets[i],
                  onTap: () => context.push('/pets/${pets[i].id}'),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFocusCard(BuildContext context, List<_FocusItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: items.asMap().entries.map((e) {
            final item = e.value;
            final isLast = e.key == items.length - 1;
            return Column(
              children: [
                ListTile(
                  onTap: item.onTap,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.color, size: 18),
                  ),
                  title: Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 18,
                  ),
                  dense: true,
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 64,
                    endIndent: 16,
                    color: Colors.grey.shade100,
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    int petCount,
    int apptCount,
    int dueVaccines,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.pets,
              label: 'Pets',
              value: '$petCount',
              color: const Color(0xFF6A1B9A),
              onTap: () => context.go('/pets'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.calendar_today,
              label: 'Upcoming',
              value: '$apptCount',
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
              color: dueVaccines > 0
                  ? Colors.red.shade700
                  : const Color(0xFF2E7D32),
              onTap: () => context.push('/vaccinations'),
            ),
          ),
        ],
      ),
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
        label: 'Book Appt',
        color: const Color(0xFF1565C0),
        onTap: () => context.push('/appointments/add'),
      ),
      _QuickAction(
        icon: Icons.medical_services_outlined,
        label: 'Medical',
        color: const Color(0xFFC62828),
        onTap: () => context.push('/medical/add'),
      ),
      _QuickAction(
        icon: Icons.vaccines,
        label: 'Vaccine',
        color: const Color(0xFF2E7D32),
        onTap: () => context.push('/vaccinations/add'),
      ),
      _QuickAction(
        icon: Icons.alarm,
        label: 'Reminder',
        color: const Color(0xFFE65100),
        onTap: () => context.push('/reminders'),
      ),
      _QuickAction(
        icon: Icons.storefront_outlined,
        label: 'Market',
        color: const Color(0xFF00695C),
        onTap: () => context.go('/marketplace'),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
        children: actions.map((a) => _QuickActionCard(action: a)).toList(),
      ),
    );
  }

  Widget _buildUpcomingAppointments(
    BuildContext context,
    List<AppointmentModel> appointments, {
    bool isVet = false,
  }) {
    if (appointments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: Colors.grey.shade400,
                size: 32,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVet
                        ? 'No scheduled appointments'
                        : 'No upcoming appointments',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!isVet)
                    GestureDetector(
                      onTap: () => context.push('/appointments/add'),
                      child: const Text(
                        'Book one now →',
                        style: TextStyle(
                          color: Color(0xFF6A1B9A),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          ...appointments.take(3).map((appt) => _AppointmentTile(appt: appt)),
          if (appointments.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () => context.go('/appointments'),
                child: const Text(
                  'View all appointments →',
                  style: TextStyle(
                    color: Color(0xFF6A1B9A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A2E),
        ),
      ),
    );
  }
}

// ── Pet Carousel Card ──────────────────────────────────────────────────────

class _PetCarouselCard extends StatelessWidget {
  final PetModel pet;
  final VoidCallback onTap;
  const _PetCarouselCard({required this.pet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
              backgroundImage: pet.photoUrl != null
                  ? NetworkImage(pet.photoUrl!)
                  : null,
              child: pet.photoUrl == null
                  ? const Icon(Icons.pets, color: Color(0xFF6A1B9A), size: 24)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              pet.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              pet.species,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPetCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPetCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF6A1B9A).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF6A1B9A).withValues(alpha: 0.2),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Color(0xFF6A1B9A), size: 28),
            SizedBox(height: 6),
            Text(
              'Add Pet',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF6A1B9A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Focus item model ───────────────────────────────────────────────────────

class _FocusItem {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _FocusItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });
}

// ── Stat Card ──────────────────────────────────────────────────────────────

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
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
                fontSize: 10,
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

// ── Quick Action ───────────────────────────────────────────────────────────

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.color, size: 22),
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

// ── Appointment Tile ───────────────────────────────────────────────────────

class _AppointmentTile extends StatelessWidget {
  final AppointmentModel appt;
  const _AppointmentTile({required this.appt});

  @override
  Widget build(BuildContext context) {
    final isToday =
        appt.dateTime.day == DateTime.now().day &&
        appt.dateTime.month == DateTime.now().month &&
        appt.dateTime.year == DateTime.now().year;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isToday
            ? Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.4))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Color(0xFF6A1B9A),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appt.petName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  appt.service,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isToday
                    ? 'Today'
                    : '${appt.dateTime.day}/${appt.dateTime.month}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isToday
                      ? const Color(0xFF6A1B9A)
                      : Colors.grey.shade600,
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
  }
}

// ── Drawer ─────────────────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onLogout;
  const _AppDrawer({required this.user, required this.onLogout});

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
                  radius: 32,
                  backgroundColor: Colors.white,
                  backgroundImage: user?.photoUrl != null
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? const Icon(Icons.person, color: primary, size: 32)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? '',
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
                  icon: Icons.pets_outlined,
                  label: 'My Pets',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/pets');
                  },
                ),
                _DrawerItem(
                  icon: Icons.storefront_outlined,
                  label: 'My Listings',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/marketplace/my-listings');
                  },
                ),
                _DrawerItem(
                  icon: Icons.alarm_outlined,
                  label: 'Reminders',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/reminders');
                  },
                ),
                _DrawerItem(
                  icon: Icons.bar_chart_outlined,
                  label: 'Reports',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/reports');
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/settings');
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                _DrawerItem(
                  icon: Icons.logout,
                  label: 'Log Out',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    onLogout();
                  },
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
      indicatorColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.15),
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
