import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresenceService with WidgetsBindingObserver {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);

    // Track active user changes
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _setStatus(true);
      }
    });

    _setStatus(true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setStatus(true);
    } else {
      _setStatus(false);
    }
  }

  Future<void> _setStatus(bool online) async {
    final user = _auth.currentUser;

    if (user == null) return;

    try {
      await _db.collection('users').doc(user.uid).set({
        'isOnline': online,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error setting status: $e");
    }
  }
}