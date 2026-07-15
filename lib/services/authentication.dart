import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  DatabaseReference _userRef(String uid) => _db.ref('users/$uid');

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? clinicName,
    String? specialization,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = UserModel(
      id: credential.user!.uid,
      name: name,
      email: email,
      role: role,
      clinicName: clinicName,
      specialization: specialization,
      createdAt: DateTime.now(),
    );
    await _userRef(user.id).set(user.toMap());
    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;
    final snapshot = await _userRef(uid).get();
    if (!snapshot.exists || snapshot.value == null) {
      // User exists in Auth but not in DB — create a basic record
      final user = UserModel(
        id: uid,
        name: credential.user!.email!.split('@').first,
        email: credential.user!.email!,
        role: UserRole.petOwner,
        createdAt: DateTime.now(),
      );
      await _userRef(uid).set(user.toMap());
      return user;
    }
    return UserModel.fromMap(
      Map<String, dynamic>.from(
        (snapshot.value as Map).map((k, v) => MapEntry(k.toString(), v)),
      ),
    );
  }

  Future<void> logout() => _auth.signOut();

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<UserModel> getUser(String uid) async {
    final snapshot = await _userRef(uid).get();
    if (!snapshot.exists || snapshot.value == null) {
      throw Exception('User not found in database');
    }
    print('RAW DB VALUE: ${snapshot.value}');
    print('RAW DB TYPE: ${snapshot.value.runtimeType}');
    try {
      final data = Map<String, dynamic>.from(
        (snapshot.value as Map).map((k, v) => MapEntry(k.toString(), v)),
      );
      print('PARSED DATA: $data');
      return UserModel.fromMap(data);
    } catch (e) {
      print('PARSE ERROR: $e');
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user) =>
      _userRef(user.id).update(user.toMap());
}
