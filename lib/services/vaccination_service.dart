import 'package:firebase_database/firebase_database.dart';
import '../models/vaccination_model.dart';

class VaccinationService {
  final _db = FirebaseDatabase.instance;

  DatabaseReference _ref(String ownerId) => _db.ref('vaccinations/$ownerId');

  Future<VaccinationModel> addVaccination(VaccinationModel v) async {
    final ref = _ref(v.ownerId).push();
    final newV = VaccinationModel(
      id: ref.key!,
      ownerId: v.ownerId,
      petId: v.petId,
      petName: v.petName,
      vaccineName: v.vaccineName,
      vetName: v.vetName,
      dateGiven: v.dateGiven,
      nextDueDate: v.nextDueDate,
      notes: v.notes,
      createdAt: v.createdAt,
    );
    await ref.set(newV.toMap());
    return newV;
  }

  Future<void> deleteVaccination(String ownerId, String id) =>
      _ref(ownerId).child(id).remove();

  Stream<List<VaccinationModel>> vaccinationsStream(String ownerId) =>
      _ref(ownerId).onValue.map((event) {
        if (event.snapshot.value == null) return [];
        final map = Map<String, dynamic>.from(
          (event.snapshot.value as Map).map((k, v) => MapEntry(k.toString(), v)),
        );
        return map.values.map((v) {
          final data = Map<String, dynamic>.from(
            (v as Map).map((k, val) => MapEntry(k.toString(), val)),
          );
          return VaccinationModel.fromMap(data);
        }).toList()
          ..sort((a, b) => b.dateGiven.compareTo(a.dateGiven));
      });
}
