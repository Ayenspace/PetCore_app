import 'dart:async';
import 'package:flutter/material.dart';
import '../models/pet_model.dart';
import '../services/pet_service.dart';

class PetProvider extends ChangeNotifier {
  final _service = PetService();

  List<PetModel> _pets = [];
  bool _loading = false;
  String? _error;
  StreamSubscription? _subscription;
  String? _listeningOwnerId;

  List<PetModel> get pets => _pets;
  bool get loading => _loading;
  String? get error => _error;

  void listenToPets(String ownerId) {
    if (_listeningOwnerId == ownerId && _subscription != null) return;

    _subscription?.cancel();
    _listeningOwnerId = ownerId;
    _subscription = _service.petsStream(ownerId).listen((pets) {
      _pets = pets;
      notifyListeners();
    });
  }

  Future<bool> addPet(PetModel pet) async {
    _setLoading(true);
    try {
      final newPet = await _service.addPet(pet);
      if (!_pets.any((existing) => existing.id == newPet.id)) {
        _pets.add(newPet);
        _pets.sort((a, b) => a.name.compareTo(b.name));
      }
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updatePet(PetModel pet) async {
    _setLoading(true);
    try {
      await _service.updatePet(pet);
      final index = _pets.indexWhere((p) => p.id == pet.id);
      if (index != -1) _pets[index] = pet;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deletePet(String ownerId, String petId) async {
    _setLoading(true);
    try {
      await _service.deletePet(ownerId, petId);
      _pets.removeWhere((p) => p.id == petId);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  PetModel? getPetById(String id) {
    try {
      return _pets.firstWhere((p) => p.id == id);
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
