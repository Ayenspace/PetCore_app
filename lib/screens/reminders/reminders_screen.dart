import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pet_model.dart';
import '../../models/reminder_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_providers.dart';
import '../../providers/reminder_provider.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final uid = context.read<AppAuthProvider>().user?.id;
    if (uid != null) context.read<ReminderProvider>().listenToReminders(uid);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddReminderSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReminderProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Pending (${provider.pending.length})'),
            Tab(text: 'Completed (${provider.completed.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReminderList(reminders: provider.pending, theme: theme, emptyMessage: 'No pending reminders'),
          _ReminderList(reminders: provider.completed, theme: theme, emptyMessage: 'No completed reminders'),
        ],
      ),
    );
  }
}

class _ReminderList extends StatelessWidget {
  final List<ReminderModel> reminders;
  final ThemeData theme;
  final String emptyMessage;

  const _ReminderList({required this.reminders, required this.theme, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.alarm_off_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(emptyMessage, style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: reminders.length,
      itemBuilder: (context, index) => _ReminderCard(reminder: reminders[index], theme: theme),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final ThemeData theme;

  const _ReminderCard({required this.reminder, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isOverdue = !reminder.isCompleted && reminder.dateTime.isBefore(DateTime.now());
    final ownerId = context.read<AppAuthProvider>().user!.id;

    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Reminder'),
          content: const Text('Are you sure you want to delete this reminder?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
      onDismissed: (_) => context.read<ReminderProvider>().deleteReminder(ownerId, reminder.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isOverdue ? Border.all(color: Colors.red.shade300) : null,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Checkbox(
            value: reminder.isCompleted,
            activeColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (val) => context.read<ReminderProvider>().toggleComplete(ownerId, reminder.id, val!),
          ),
          title: Text(
            reminder.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
              color: reminder.isCompleted ? Colors.grey : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 13,
                    color: isOverdue ? Colors.red : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(reminder.dateTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue ? Colors.red : Colors.grey.shade500,
                      fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (reminder.repeat != ReminderRepeat.none) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.repeat, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 2),
                    Text(
                      reminder.repeat.name,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ],
              ),
              if (reminder.petName != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.pets, size: 13, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(reminder.petName!, style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
                  ],
                ),
              ],
              if (reminder.notes != null && reminder.notes!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(reminder.notes!, style: TextStyle(fontSize: 12, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    if (date == today) return 'Today at $timeStr';
    if (date == today.add(const Duration(days: 1))) return 'Tomorrow at $timeStr';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday at $timeStr';
    return '${dt.day}/${dt.month}/${dt.year} at $timeStr';
  }
}

// ── Add Reminder Bottom Sheet ──────────────────────────────────────────────

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();
  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  PetModel? _selectedPet;
  DateTime _date = DateTime.now().add(const Duration(hours: 1));
  ReminderRepeat _repeat = ReminderRepeat.none;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2040),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    if (time == null) return;

    setState(() => _date = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = context.read<AppAuthProvider>().user!.id;

    final reminder = ReminderModel(
      id: '',
      ownerId: uid,
      petId: _selectedPet?.id,
      petName: _selectedPet?.name,
      title: _titleController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      dateTime: _date,
      repeat: _repeat,
      createdAt: DateTime.now(),
    );

    final success = await context.read<ReminderProvider>().addReminder(reminder);
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<PetProvider>().pets;
    final provider = context.watch<ReminderProvider>();
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('New Reminder', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.alarm_outlined),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 12),

            // Date & time picker
            GestureDetector(
              onTap: _pickDateTime,
              child: AbsorbPointer(
                child: TextFormField(
                  key: ValueKey(_date),
                  initialValue: _formatDateTime(_date),
                  decoration: const InputDecoration(
                    labelText: 'Date & Time',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    suffixIcon: Icon(Icons.edit_calendar_outlined),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Repeat
            DropdownButtonFormField<ReminderRepeat>(
              initialValue: _repeat,
              decoration: const InputDecoration(
                labelText: 'Repeat',
                prefixIcon: Icon(Icons.repeat),
              ),
              items: ReminderRepeat.values
                  .map((r) => DropdownMenuItem(value: r, child: Text(_repeatLabel(r))))
                  .toList(),
              onChanged: (v) => setState(() => _repeat = v!),
            ),
            const SizedBox(height: 12),

            // Optional pet
            if (pets.isNotEmpty)
              DropdownButtonFormField<PetModel>(
                decoration: const InputDecoration(
                  labelText: 'Link to Pet (optional)',
                  prefixIcon: Icon(Icons.pets),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No pet')),
                  ...pets.map((p) => DropdownMenuItem(value: p, child: Text(p.name))),
                ],
                onChanged: (p) => setState(() => _selectedPet = p),
              ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _notesController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: provider.loading ? null : _save,
                child: provider.loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Reminder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.day}/${dt.month}/${dt.year} at $timeStr';
  }

  String _repeatLabel(ReminderRepeat r) {
    switch (r) {
      case ReminderRepeat.none: return 'No repeat';
      case ReminderRepeat.daily: return 'Daily';
      case ReminderRepeat.weekly: return 'Weekly';
      case ReminderRepeat.monthly: return 'Monthly';
    }
  }
}
