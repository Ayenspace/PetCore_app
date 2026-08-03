import 'package:firebase_database/firebase_database.dart';
import '../models/medical_record.dart';

class MedicalService {
  final _db = FirebaseDatabase.instance;

  DatabaseReference _ref(String ownerId) => _db.ref('medical_records/$ownerId');

  Future<MedicalRecord> addRecord(MedicalRecord record) async {
    final ref = _ref(record.ownerId).push();
    final newRecord = MedicalRecord(
      id: ref.key!,
      ownerId: record.ownerId,
      petId: record.petId,
      petName: record.petName,
      diagnosis: record.diagnosis,
      treatment: record.treatment,
      vetName: record.vetName,
      date: record.date,
      notes: record.notes,
      attachmentUrls: record.attachmentUrls,
      createdAt: record.createdAt,
    );
    await ref.set(newRecord.toMap());
    return newRecord;
  }

  Future<void> deleteRecord(String ownerId, String recordId) =>
      _ref(ownerId).child(recordId).remove();

  Stream<List<MedicalRecord>> recordsStream(String ownerId) =>
      _ref(ownerId).onValue.map((event) {
        if (event.snapshot.value == null) return [];
        final map = Map<String, dynamic>.from(
          (event.snapshot.value as Map).map((k, v) => MapEntry(k.toString(), v)),
        );
        return map.values.map((v) {
          final data = Map<String, dynamic>.from(
            (v as Map).map((k, val) => MapEntry(k.toString(), val)),
          );
          return MedicalRecord.fromMap(data);
        }).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      });
}
