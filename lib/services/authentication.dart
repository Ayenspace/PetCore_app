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
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    return await getUser(_auth.currentUser!.uid);
  }

  Future<void> logout() => _auth.signOut();

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<UserModel> getUser(String uid) async {
    final snapshot = await _userRef(uid).get();
    return UserModel.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
  }

  Future<void> updateUser(UserModel user) =>
      _userRef(user.id).update(user.toMap());
}
