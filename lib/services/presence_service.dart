import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresenceService with WidgetsBindingObserver {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  void start() {
    WidgetsBinding.instance.addObserver(this);

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

    await _db.collection('users').doc(user.uid).set({
      'isOnline': online,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}