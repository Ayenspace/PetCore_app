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

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get loading => _loading;

  AppAuthProvider() {
    _service.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        _status = AuthStatus.unauthenticated;
        _user = null;
      } else {
        _user = await _service.getUser(firebaseUser.uid);
        _status = AuthStatus.authenticated;
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
      _user = await _service.register(
        name: name,
        email: email,
        password: password,
        role: role,
        clinicName: clinicName,
        specialization: specialization,
      );
      _status = AuthStatus.authenticated;
      _error = null;
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
      _user = await _service.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      _error = null;
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

  String _parseError(dynamic e) {
    if (e.toString().contains('user-not-found')) return 'No account found with this email.';
    if (e.toString().contains('wrong-password')) return 'Incorrect password.';
    if (e.toString().contains('email-already-in-use')) return 'An account already exists with this email.';
    if (e.toString().contains('weak-password')) return 'Password is too weak.';
    if (e.toString().contains('invalid-email')) return 'Invalid email address.';
    if (e.toString().contains('network-request-failed')) return 'No internet connection.';
    return 'Something went wrong. Please try again.';
  }
}
