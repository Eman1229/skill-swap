import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class ChatUserProfile {
  final String userId;
  final String name;
  final String? imageUrl;
  final bool isOnline;
  final Timestamp? lastSeen;

  const ChatUserProfile({
    required this.userId,
    required this.name,
    this.imageUrl,
    required this.isOnline,
    this.lastSeen,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  String get relativeLastSeen {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final dt = lastSeen!.toDate();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}

class ChatUserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Single dynamic stream for user details (Firestore) and presence (Realtime Database)
  Stream<ChatUserProfile> getUserProfile(String userId) {
    if (userId.isEmpty) {
      return Stream.value(const ChatUserProfile(
        userId: '',
        name: 'Unknown User',
        isOnline: false,
      ));
    }

    // 1. Fetch swap listing profile details once (since name and photo don't change dynamically)
    final profileFuture = _db
        .collection('swapListings')
        .where('userId', isEqualTo: userId)
        .get()
        .then((listingsSnap) {
      String name = 'Unknown User';
      String? imageUrl;

      if (listingsSnap.docs.isNotEmpty) {
        final docs = List<QueryDocumentSnapshot>.from(listingsSnap.docs);
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'] as Timestamp?;
          final bTime = bData['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        final latestData = docs.first.data() as Map<String, dynamic>;
        name = latestData['name'] as String? ?? 'Unknown User';
        imageUrl = latestData['imageUrl'] as String?;
      }

      return {'name': name, 'imageUrl': imageUrl};
    });

    // 2. Stream user active status and lastSeen timestamp from Realtime Database
    final dbRef = FirebaseDatabase.instance.ref('status/$userId');
    return dbRef.onValue.asyncMap((event) async {
      final snap = event.snapshot;
      bool isOnline = false;
      Timestamp? lastSeen;

      if (snap.exists && snap.value != null) {
        try {
          final val = snap.value as Map<dynamic, dynamic>;
          isOnline = (val['online'] as bool?) ?? false;
          final lastSeenMs = val['lastSeen'] as int?;
          if (lastSeenMs != null) {
            lastSeen = Timestamp.fromMillisecondsSinceEpoch(lastSeenMs);
          }
        } catch (e) {
          debugPrint("ChatUserService: Error parsing presence value: $e");
        }
      }

      final profile = await profileFuture;
      return ChatUserProfile(
        userId: userId,
        name: profile['name'] as String,
        imageUrl: profile['imageUrl'],
        isOnline: isOnline,
        lastSeen: lastSeen,
      );
    });
  }
}
