import 'dart:async';
import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

class AppointmentProvider extends ChangeNotifier {
  final _service = AppointmentService();

  List<AppointmentModel> _appointments = [];
  bool _loading = false;
  String? _error;
  StreamSubscription? _subscription;

  List<AppointmentModel> get appointments => _appointments;
  bool get loading => _loading;
  String? get error => _error;

  void listenToAppointments(String ownerId) {
    _subscription?.cancel();
    _subscription = _service.appointmentsStream(ownerId).listen((list) {
      _appointments = list;
      notifyListeners();
    });
  }

  Future<bool> addAppointment(AppointmentModel appointment) async {
    _setLoading(true);
    try {
      final newAppt = await _service.addAppointment(appointment);
      _appointments.add(newAppt);
      _appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateAppointment(AppointmentModel appointment) async {
    _setLoading(true);
    try {
      await _service.updateAppointment(appointment);
      final index = _appointments.indexWhere((a) => a.id == appointment.id);
      if (index != -1) _appointments[index] = appointment;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteAppointment(String ownerId, String appointmentId) async {
    _setLoading(true);
    try {
      await _service.deleteAppointment(ownerId, appointmentId);
      _appointments.removeWhere((a) => a.id == appointmentId);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  AppointmentModel? getAppointmentById(String id) {
    try {
      return _appointments.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
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
