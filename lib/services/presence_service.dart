import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Starts tracking presence for the logged-in user.
  /// Listens to auth changes and configures real-time connection state.
  void startPresenceTracking() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _setupUserPresence(user.uid);
      }
    });
  }

  Future<void> _setupUserPresence(String uid) async {
    final statusRef = _db.ref('status/$uid');

    // Monitor Firebase Realtime Database active socket connection state
    _db.ref('.info/connected').onValue.listen((event) async {
      final connected = event.snapshot.value as bool? ?? false;
      if (connected) {
        try {
          // 1. Establish the atomic cleanup hook on the database first
          await statusRef.onDisconnect().set({
            'online': false,
            'lastSeen': ServerValue.timestamp,
          });

          // 2. Set status to ONLINE
          await statusRef.set({
            'online': true,
            'lastSeen': null,
          });
          debugPrint("PresenceService: User $uid presence online initialized successfully.");
        } catch (e) {
          debugPrint("PresenceService: Error setting presence properties: $e");
        }
      }
    });
  }

  /// Sets status to OFFLINE manually (used in AppLifecycleState.paused / detached).
  Future<void> setUserOffline() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final statusRef = _db.ref('status/$uid');
      await statusRef.set({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });
      debugPrint("PresenceService: User $uid manually set OFFLINE.");
    } catch (e) {
      debugPrint("PresenceService: Error updating manual offline state: $e");
    }
  }

  /// Sets status to ONLINE manually (used in AppLifecycleState.resumed).
  Future<void> setUserOnline() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final statusRef = _db.ref('status/$uid');
      await statusRef.set({
        'online': true,
        'lastSeen': null,
      });
      debugPrint("PresenceService: User $uid manually set ONLINE.");
    } catch (e) {
      debugPrint("PresenceService: Error updating manual online state: $e");
    }
  }
}