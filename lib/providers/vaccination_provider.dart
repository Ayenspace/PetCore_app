import 'dart:async';
import 'package:flutter/material.dart';
import '../models/vaccination_model.dart';
import '../services/vaccination_service.dart';

class VaccinationProvider extends ChangeNotifier {
  final _service = VaccinationService();

  List<VaccinationModel> _vaccinations = [];
  bool _loading = false;
  String? _error;
  StreamSubscription? _subscription;

  List<VaccinationModel> get vaccinations => _vaccinations;
  bool get loading => _loading;
  String? get error => _error;

  List<VaccinationModel> forPet(String petId) =>
      _vaccinations.where((v) => v.petId == petId).toList();

  List<VaccinationModel> get dueSoon => _vaccinations
      .where((v) =>
          v.nextDueDate != null &&
          v.nextDueDate!.isAfter(DateTime.now()) &&
          v.nextDueDate!.isBefore(DateTime.now().add(const Duration(days: 30))))
      .toList();

  List<VaccinationModel> get overdue =>
      _vaccinations.where((v) => v.isDue).toList();

  void listenToVaccinations(String ownerId) {
    _subscription?.cancel();
    _subscription = _service.vaccinationsStream(ownerId).listen((list) {
      _vaccinations = list;
      notifyListeners();
    });
  }

  Future<bool> addVaccination(VaccinationModel v) async {
    _setLoading(true);
    try {
      final newV = await _service.addVaccination(v);
      _vaccinations.insert(0, newV);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteVaccination(String ownerId, String id) async {
    _setLoading(true);
    try {
      await _service.deleteVaccination(ownerId, id);
      _vaccinations.removeWhere((v) => v.id == id);
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
