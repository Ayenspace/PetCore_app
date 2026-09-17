import 'dart:async';
import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

class AppointmentProvider extends ChangeNotifier {
  final _service = AppointmentService();

  List<AppointmentModel> _appointments = [];
  List<AppointmentModel> _vetAppointments = [];
  bool _loading = false;
  String? _error;
  StreamSubscription? _subscription;
  StreamSubscription? _vetSubscription;
  Timer? _overdueTimer;
  String? _currentOwnerId;
  String? _currentVetId;

  List<AppointmentModel> get appointments => _appointments;
  List<AppointmentModel> get vetAppointments => _vetAppointments;
  bool get loading => _loading;
  String? get error => _error;

  void listenToAppointments(String ownerId) {
    if (_currentOwnerId == ownerId && _subscription != null) return;
    _currentOwnerId = ownerId;
    _subscription?.cancel();
    _subscription = _service.appointmentsStream(ownerId).listen((list) {
      _appointments = list;
      notifyListeners();
    });
    _overdueTimer?.cancel();
    _overdueTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _markOverdue(ownerId),
    );
    _markOverdue(ownerId);
  }

  void listenToVetAppointments(String vetId) {
    if (_currentVetId == vetId && _vetSubscription != null) return;
    _currentVetId = vetId;
    _vetSubscription?.cancel();
    _vetSubscription = _service.vetAppointmentsStream(vetId).listen((list) {
      _vetAppointments = list;
      notifyListeners();
    });
  }

  void _markOverdue(String ownerId) {
    final now = DateTime.now();
    for (final a in _appointments) {
      if (a.status == AppointmentStatus.upcoming && a.dateTime.isBefore(now)) {
        _service.updateStatus(
          ownerId,
          a.id,
          AppointmentStatus.overdue,
          vetId: a.vetId,
        );
      }
    }
  }

  Future<void> addAppointment(AppointmentModel appointment) async {
    _setLoading(true);
    try {
      final saved = await _service.addAppointment(appointment);
      _appointments.add(saved);
      _appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      if (appointment.vetId.isNotEmpty) {
        final vetIndex = _vetAppointments.indexWhere(
          (a) => a.id == appointment.id,
        );
        if (vetIndex != -1) {
          _vetAppointments[vetIndex] = saved;
        } else {
          _vetAppointments.add(saved);
        }
        _vetAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateAppointment(AppointmentModel appointment) async {
    _setLoading(true);
    try {
      await _service.updateAppointment(appointment);
      final index = _appointments.indexWhere((a) => a.id == appointment.id);
      if (index != -1) {
        _appointments[index] = appointment;
      } else {
        _appointments.add(appointment);
      }
      if (appointment.vetId.isNotEmpty) {
        final vetIndex = _vetAppointments.indexWhere(
          (a) => a.id == appointment.id,
        );
        if (vetIndex != -1) {
          _vetAppointments[vetIndex] = appointment;
        } else {
          _vetAppointments.add(appointment);
        }
      }
      _appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      _vetAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteAppointment(
    String ownerId,
    String appointmentId, {
    String? vetId,
  }) async {
    _setLoading(true);
    try {
      await _service.deleteAppointment(ownerId, appointmentId, vetId: vetId);
      _appointments.removeWhere((a) => a.id == appointmentId);
      if (vetId != null && vetId.isNotEmpty) {
        _vetAppointments.removeWhere((a) => a.id == appointmentId);
      }
      _error = null;
      notifyListeners();
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
      try {
        return _vetAppointments.firstWhere((a) => a.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _vetSubscription?.cancel();
    _overdueTimer?.cancel();
    super.dispose();
  }
}
