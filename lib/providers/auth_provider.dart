import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/authentication.dart';

export '../models/user_model.dart' show UserRole;

enum AuthStatus { initial, authenticated, unauthenticated }

class AppAuthProvider extends ChangeNotifier {
  final _service = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _error;
  bool _loading = false;
  Timer? _initializationTimer;
  StreamSubscription? _authSubscription;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get loading => _loading;

  AppAuthProvider() {
    _initializationTimer = Timer(const Duration(seconds: 8), () {
      if (_status != AuthStatus.initial) return;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    });

    _authSubscription = _service.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        _status = AuthStatus.unauthenticated;
        _user = null;
        _initializationTimer?.cancel();
      } else {
        try {
          _user = await _service
              .getUser(firebaseUser.uid)
              .timeout(const Duration(seconds: 5));
          _status = AuthStatus.authenticated;
          _initializationTimer?.cancel();
        } catch (e) {
          _status = AuthStatus.unauthenticated;
          _user = null;
          _initializationTimer?.cancel();
          notifyListeners();
          // Do not block routing while Firebase signs out the invalid session.
          unawaited(_service.logout());
          return;
        }
      }
      notifyListeners();
    });
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? clinicName,
    String? specialization,
  }) async {
    _setLoading(true);
    try {
      final user = await _service.register(
        name: name,
        email: email,
        password: password,
        role: role,
        clinicName: clinicName,
        specialization: specialization,
      );
      _user = user;
      _status = AuthStatus.authenticated;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      final user = await _service.login(email: email, password: password);
      _user = user;
      _status = AuthStatus.authenticated;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_user == null) return;
    try {
      _user = await _service.getUser(_user!.id);
      notifyListeners();
    } catch (_) {}
  }

  void continueAsSignedOut() {
    if (_status != AuthStatus.initial) return;
    _initializationTimer?.cancel();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _service.resetPassword(email);
      _error = null;
      return true;
    } catch (e) {
      _error = _parseError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _initializationTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  String _parseError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('user-not-found') || msg.contains('no user record')) return 'No account found with this email.';
    if (msg.contains('wrong-password') || msg.contains('invalid-credential') || msg.contains('invalid credential')) return 'Incorrect email or password.';
    if (msg.contains('email-already-in-use')) return 'An account already exists with this email.';
    if (msg.contains('weak-password')) return 'Password is too weak. Use at least 6 characters.';
    if (msg.contains('invalid-email')) return 'Invalid email address.';
    if (msg.contains('network-request-failed') || msg.contains('network')) return 'No internet connection.';
    if (msg.contains('too-many-requests')) return 'Too many attempts. Please try again later.';
    if (msg.contains('permission-denied')) return 'Database permission denied. Check Firebase rules.';
    return 'Something went wrong: ${e.toString()}';
  }
}
