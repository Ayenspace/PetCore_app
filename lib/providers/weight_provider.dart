import 'dart:async';
import 'package:flutter/material.dart';
import '../models/pet_model.dart';
import '../models/weight_entry.dart';
import '../services/weight_service.dart';

class WeightProvider extends ChangeNotifier {
  final _service = WeightService();
  final Map<String, List<WeightEntry>> _history = {};
  StreamSubscription? _subscription;
  String? _listeningOwnerId;

  List<WeightEntry> forPet(String petId) => _history[petId] ?? const [];

  void listenToWeights(String ownerId) {
    if (_listeningOwnerId == ownerId && _subscription != null) return;
    _listeningOwnerId = ownerId;
    _subscription?.cancel();
    _subscription = _service.stream(ownerId).listen((entries) {
      _history
        ..clear()
        ..addEntries(
          entries.fold<Map<String, List<WeightEntry>>>({}, (map, entry) {
            map.putIfAbsent(entry.petId, () => []).add(entry);
            return map;
          }).entries,
        );
      notifyListeners();
    });
  }

  Future<void> recordPetWeight(PetModel pet) async {
    if (pet.weight == null) return;
    final existing = forPet(pet.id);
    if (existing.isNotEmpty && existing.last.weight == pet.weight) return;
    await _service.addEntry(
      pet.ownerId,
      WeightEntry(
        id: '',
        petId: pet.id,
        weight: pet.weight!,
        recordedAt: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
