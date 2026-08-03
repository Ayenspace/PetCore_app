import 'package:firebase_database/firebase_database.dart';
import '../models/reminder_model.dart';

class ReminderService {
  final _db = FirebaseDatabase.instance;

  DatabaseReference _ref(String ownerId) => _db.ref('reminders/$ownerId');

  Future<ReminderModel> addReminder(ReminderModel r) async {
    final ref = _ref(r.ownerId).push();
    final newR = ReminderModel(
      id: ref.key!,
      ownerId: r.ownerId,
      petId: r.petId,
      petName: r.petName,
      title: r.title,
      notes: r.notes,
      dateTime: r.dateTime,
      repeat: r.repeat,
      isCompleted: r.isCompleted,
      createdAt: r.createdAt,
    );
    await ref.set(newR.toMap());
    return newR;
  }

  Future<void> toggleComplete(String ownerId, String id, bool value) =>
      _ref(ownerId).child(id).update({'isCompleted': value});

  Future<void> deleteReminder(String ownerId, String id) =>
      _ref(ownerId).child(id).remove();

  Stream<List<ReminderModel>> remindersStream(String ownerId) =>
      _ref(ownerId).onValue.map((event) {
        if (event.snapshot.value == null) return [];
        final map = Map<String, dynamic>.from(
          (event.snapshot.value as Map).map((k, v) => MapEntry(k.toString(), v)),
        );
        return map.values.map((v) {
          final data = Map<String, dynamic>.from(
            (v as Map).map((k, val) => MapEntry(k.toString(), val)),
          );
          return ReminderModel.fromMap(data);
        }).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      });
}
