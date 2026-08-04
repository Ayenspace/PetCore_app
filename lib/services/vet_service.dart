import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class VetService {
  final _db = FirebaseDatabase.instance;

  Future<List<UserModel>> loadVets() async {
    final snapshot = await _db.ref('users').get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final value = snapshot.value;
    if (value is! Map) return [];

    return parseVets(Map<dynamic, dynamic>.from(value));
  }

  static List<UserModel> parseVets(Map<dynamic, dynamic> data) {
    final vets = <UserModel>[];

    data.forEach((key, value) {
      if (value is! Map) return;

      final userMap = Map<String, dynamic>.from(
        value.map((k, v) => MapEntry(k.toString(), v)),
      );

      final user = UserModel.fromMap(userMap);
      if (user.role == UserRole.vet) {
        vets.add(user);
      }
    });

    vets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return vets;
  }
}
