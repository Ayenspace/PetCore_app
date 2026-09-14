import 'dart:async';
import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/reminder_service.dart';

class ReminderProvider extends ChangeNotifier {
  final _service = ReminderService();

  List<ReminderModel> _reminders = [];
  bool _loading = false;
  String? _error;
  StreamSubscription? _subscription;
  Timer? _checkTimer;

  // Callback set by the UI to show in-app banners
  void Function(ReminderModel)? onReminderDue;

  final Set<String> _notifiedIds = {};

  List<ReminderModel> get reminders => _reminders;
  List<ReminderModel> get pending =>
      _reminders.where((r) => !r.isCompleted && !_isOverdue(r)).toList();
  List<ReminderModel> get overdue =>
      _reminders.where((r) => !r.isCompleted && _isOverdue(r)).toList();
  List<ReminderModel> get completed =>
      _reminders.where((r) => r.isCompleted).toList();
  bool get loading => _loading;
  String? get error => _error;

  bool _isOverdue(ReminderModel r) => r.dateTime.isBefore(DateTime.now());

  void listenToReminders(String ownerId) {
    _subscription?.cancel();
    _subscription = _service.remindersStream(ownerId).listen((list) {
      _reminders = list;
      notifyListeners();
    });
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkDue());
    _checkDue();
  }

  void _checkDue() {
    final now = DateTime.now();
    for (final r in _reminders) {
      if (r.isCompleted || _notifiedIds.contains(r.id)) continue;
      // Fire if within 1 minute past due
      final diff = now.difference(r.dateTime);
      if (diff.inSeconds >= 0 && diff.inMinutes < 2) {
        _notifiedIds.add(r.id);
        onReminderDue?.call(r);
      }
    }
  }

  Future<bool> addReminder(ReminderModel r) async {
    _setLoading(true);
    try {
      final newR = await _service.addReminder(r);
      _reminders.add(newR);
      _reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleComplete(String ownerId, String id, bool value) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _reminders[index] = _reminders[index].copyWith(isCompleted: value);
    notifyListeners();
    await _service.toggleComplete(ownerId, id, value);
  }

  Future<bool> deleteReminder(String ownerId, String id) async {
    _setLoading(true);
    try {
      await _service.deleteReminder(ownerId, id);
      _reminders.removeWhere((r) => r.id == id);
      _notifiedIds.remove(id);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _checkTimer?.cancel();
    super.dispose();
  }
}
