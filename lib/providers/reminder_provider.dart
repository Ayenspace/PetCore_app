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

  List<ReminderModel> get reminders => _reminders;
  List<ReminderModel> get pending => _reminders.where((r) => !r.isCompleted).toList();
  List<ReminderModel> get completed => _reminders.where((r) => r.isCompleted).toList();
  bool get loading => _loading;
  String? get error => _error;

  void listenToReminders(String ownerId) {
    _subscription?.cancel();
    _subscription = _service.remindersStream(ownerId).listen((list) {
      _reminders = list;
      notifyListeners();
    });
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
    super.dispose();
  }
}
