import 'package:firebase_database/firebase_database.dart';
import '../models/weight_entry.dart';

class WeightService {
  final _db = FirebaseDatabase.instance;

  DatabaseReference _ref(String ownerId, String petId) =>
      _db.ref('weight_history/$ownerId/$petId');

  Future<void> addEntry(String ownerId, WeightEntry entry) async {
    final ref = _ref(ownerId, entry.petId).push();
    await ref.set(
      WeightEntry(
        id: ref.key!,
        petId: entry.petId,
        weight: entry.weight,
        recordedAt: entry.recordedAt,
      ).toMap(),
    );
  }

  Future<void> addVetEntry({
    required String ownerId,
    required String petId,
    required String appointmentId,
    required double weight,
  }) async {
    final ref = _ref(ownerId, petId).push();
    await ref.set({
      'id': ref.key!,
      'petId': petId,
      'weight': weight,
      'recordedAt': DateTime.now().toIso8601String(),
      'appointmentId': appointmentId,
    });
  }

  Future<void> recordIfChanged(
    String ownerId,
    String petId,
    double? weight,
  ) async {
    if (weight == null) return;
    final snapshot = await _ref(ownerId, petId).get();
    if (snapshot.exists && snapshot.value is Map) {
      final values = Map<String, dynamic>.from(
        (snapshot.value as Map).map((k, v) => MapEntry(k.toString(), v)),
      ).values.whereType<Map>();
      if (values.isNotEmpty) {
        final latest = values
            .map(
              (value) => WeightEntry.fromMap(
                Map<String, dynamic>.from(
                  value.map((k, v) => MapEntry(k.toString(), v)),
                ),
              ),
            )
            .reduce((a, b) => a.recordedAt.isAfter(b.recordedAt) ? a : b);
        if (latest.weight == weight) return;
      }
    }
    await addEntry(
      ownerId,
      WeightEntry(
        id: '',
        petId: petId,
        weight: weight,
        recordedAt: DateTime.now(),
      ),
    );
  }

  Stream<List<WeightEntry>> stream(String ownerId) =>
      _db.ref('weight_history/$ownerId').onValue.map((event) {
        if (event.snapshot.value == null) return <WeightEntry>[];
        final pets = Map<String, dynamic>.from(
          (event.snapshot.value as Map).map(
            (k, v) => MapEntry(k.toString(), v),
          ),
        );
        final entries = <WeightEntry>[];
        for (final value in pets.values) {
          if (value is! Map) continue;
          final records = Map<String, dynamic>.from(
            value.map((k, v) => MapEntry(k.toString(), v)),
          );
          for (final record in records.values) {
            if (record is Map) {
              entries.add(
                WeightEntry.fromMap(
                  Map<String, dynamic>.from(
                    record.map((k, v) => MapEntry(k.toString(), v)),
                  ),
                ),
              );
            }
          }
        }
        return entries..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
      });
}
