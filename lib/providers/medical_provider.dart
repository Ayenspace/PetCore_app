import 'dart:async';
import 'package:flutter/material.dart';
import '../models/medical_record.dart';
import '../services/medical_service.dart';

class MedicalProvider extends ChangeNotifier {
  final _service = MedicalService();

  List<MedicalRecord> _records = [];
  bool _loading = false;
  String? _error;
  StreamSubscription? _subscription;

  List<MedicalRecord> get records => _records;
  bool get loading => _loading;
  String? get error => _error;

  List<MedicalRecord> recordsForPet(String petId) =>
      _records.where((r) => r.petId == petId).toList();

  void listenToRecords(String ownerId) {
    _subscription?.cancel();
    _subscription = _service.recordsStream(ownerId).listen((list) {
      _records = list;
      notifyListeners();
    });
  }

  Future<bool> addRecord(MedicalRecord record) async {
    _setLoading(true);
    try {
      final newRecord = await _service.addRecord(record);
      _records.insert(0, newRecord);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteRecord(String ownerId, String recordId) async {
    _setLoading(true);
    try {
      await _service.deleteRecord(ownerId, recordId);
      _records.removeWhere((r) => r.id == recordId);
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
