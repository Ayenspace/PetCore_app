import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final _db = FirebaseDatabase.instance;

  DatabaseReference ref(String path) => _db.ref(path);

  Future<void> set(String path, Map<String, dynamic> data) =>
      _db.ref(path).set(data);

  Future<void> update(String path, Map<String, dynamic> data) =>
      _db.ref(path).update(data);

  Future<void> delete(String path) => _db.ref(path).remove();

  Future<DataSnapshot> get(String path) => _db.ref(path).get();

  Stream<DatabaseEvent> stream(String path) => _db.ref(path).onValue;

  String generateId(String path) => _db.ref(path).push().key!;
}
