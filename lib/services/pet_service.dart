import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/pet_model.dart';

class PetService {
  final _db = FirebaseDatabase.instance;

  DatabaseReference _petsRef(String ownerId) => _db.ref('pets/$ownerId');

  Future<PetModel> addPet(PetModel pet) async {
    try {
      final ref = _petsRef(pet.ownerId).push();
      final newPet = PetModel(
        id: ref.key!,
        ownerId: pet.ownerId,
        name: pet.name,
        species: pet.species,
        breed: pet.breed,
        gender: pet.gender,
        dateOfBirth: pet.dateOfBirth,
        weight: pet.weight,
        photoUrl: pet.photoUrl,
        createdAt: pet.createdAt,
      );
      await ref.set(newPet.toMap());
      return newPet;
    } catch (e, st) {
      debugPrint('PetService.addPet failed: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  Future<void> updatePet(PetModel pet) =>
      _petsRef(pet.ownerId).child(pet.id).update(pet.toMap());

  Future<void> deletePet(String ownerId, String petId) =>
      _petsRef(ownerId).child(petId).remove();

  Stream<List<PetModel>> petsStream(String ownerId) =>
      _petsRef(ownerId).onValue.map((event) {
        if (event.snapshot.value == null) return [];
        final map = Map<String, dynamic>.from(
          (event.snapshot.value as Map).map(
            (k, v) => MapEntry(k.toString(), v),
          ),
        );
        return map.values.map((v) {
          final data = Map<String, dynamic>.from(
            (v as Map).map((k, val) => MapEntry(k.toString(), val)),
          );
          return PetModel.fromMap(data);
        }).toList()..sort((a, b) => a.name.compareTo(b.name));
      });
}
