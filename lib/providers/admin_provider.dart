import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AdminProvider extends ChangeNotifier {
  final _db = FirebaseDatabase.instance;

  StreamSubscription? _rootSub;
  StreamSubscription? _usersSub;
  StreamSubscription? _appointmentsSub;

  Map<String, dynamic> _root = {};
  Map<String, dynamic> _users = {};
  Map<String, dynamic> _appointments = {};

  bool _loaded = false;
  bool get loaded => _loaded;

  Map<String, dynamic> get root => _root;
  Map<String, dynamic> get users => _users;
  Map<String, dynamic> get appointments => _appointments;
  Map<String, dynamic> get marketplace => _asMap(_root['marketplace']);

  void listen() {
    if (_rootSub != null) return;

    _rootSub = _db.ref().onValue.listen((event) {
      _root = _asMap(event.snapshot.value);
      _users = _asMap(_root['users']);
      _appointments = _asMap(_root['appointments']);
      _loaded = true;
      notifyListeners();
    });
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is! Map) return {};
    return Map<String, dynamic>.from(
      value.map((k, v) => MapEntry(k.toString(), v)),
    );
  }

  @override
  void dispose() {
    _rootSub?.cancel();
    _usersSub?.cancel();
    _appointmentsSub?.cancel();
    super.dispose();
  }
}
