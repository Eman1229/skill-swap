import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:skill_swap/services/guest_mode_service.dart';

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
  static final ChatUserService _instance = ChatUserService._internal();
  factory ChatUserService() => _instance;
  ChatUserService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Cache for the profile data from Firestore
  final Map<String, Future<Map<String, dynamic>>> _profileCache = {};
  
  // Cache for the fully constructed profiles to provide instant UI
  final Map<String, ChatUserProfile> _latestProfiles = {};

  ChatUserProfile? getCachedProfile(String userId) => _latestProfiles[userId];

  // Single dynamic stream for user details (Firestore) and presence (Realtime Database)
  Stream<ChatUserProfile> getUserProfile(String userId) {
    if (userId.isEmpty) {
      return Stream.value(const ChatUserProfile(
        userId: '',
        name: 'Unknown User',
        isOnline: false,
      ));
    }

    // Guest mode: return mock profiles for known demo users
    if (GuestModeService().isGuestMode) {
      final mockProfile = _guestMockProfile(userId);
      if (mockProfile != null) {
        return Stream.value(mockProfile);
      }
    }

    if (!_profileCache.containsKey(userId)) {
      _profileCache[userId] = _db
          .collection('swapListings')
          .where('userId', isEqualTo: userId)
          .get()
          .then((listingsSnap) async {
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

        bool showOnlineStatus = true;
        try {
          final userDoc = await _db.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final data = userDoc.data();
            if (data != null) {
              showOnlineStatus = data['showOnlineStatus'] ?? true;
              if (imageUrl == null || imageUrl.isEmpty) {
                imageUrl = (data['imageUrl'] ?? data['photoURL'] ?? data['profilePic'] ?? data['ProfilePic']) as String?;
              }
              final n = data['name'] as String?;
              if (n != null && n.trim().isNotEmpty && name == 'Unknown User') {
                name = n;
              }
            }
          }
        } catch (e) {
          debugPrint("ChatUserService: Error fetching from users collection: $e");
        }

        return {'name': name, 'imageUrl': imageUrl, 'showOnlineStatus': showOnlineStatus};
      }).catchError((e) {
        debugPrint("ChatUserService: Error fetching profile: $e");
        return {'name': 'Unknown User', 'imageUrl': null, 'showOnlineStatus': true};
      });
    }

    final dbRef = FirebaseDatabase.instance.ref('status/$userId');
    return _createProfileStream(userId, dbRef);
  }

  Stream<ChatUserProfile> _createProfileStream(String userId, DatabaseReference dbRef) async* {
    // Wait for the profile data to be fetched (or instantly resolve if cached)
    final profile = await _profileCache[userId]!;
    final showOnlineStatus = (profile['showOnlineStatus'] as bool?) ?? true;
    
    // Yield the profile with offline status immediately if no latest profile exists
    final initialProfile = _latestProfiles[userId] ?? ChatUserProfile(
      userId: userId,
      name: profile['name'] as String,
      imageUrl: profile['imageUrl'] as String?,
      isOnline: false, // Default until RTDB responds
    );
    
    _latestProfiles[userId] = initialProfile;
    yield initialProfile;
    
    // Then listen to RTDB updates
    await for (final event in dbRef.onValue) {
      final snap = event.snapshot;
      bool isOnline = false;
      Timestamp? lastSeen;

      if (snap.exists && snap.value != null && showOnlineStatus) {
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

      final updatedProfile = ChatUserProfile(
        userId: userId,
        name: profile['name'] as String,
        imageUrl: profile['imageUrl'] as String?,
        isOnline: isOnline,
        lastSeen: lastSeen,
      );
      
      _latestProfiles[userId] = updatedProfile;
      yield updatedProfile;
    }
  }

  // Guest mode mock profiles for demo user IDs
  ChatUserProfile? _guestMockProfile(String userId) {
    const profiles = {
      'user_sarah_1': ChatUserProfile(
        userId: 'user_sarah_1',
        name: 'Sarah Jenkins',
        isOnline: true,
      ),
      'user_david_2': ChatUserProfile(
        userId: 'user_david_2',
        name: 'David Chen',
        isOnline: false,
      ),
      'user_elena_3': ChatUserProfile(
        userId: 'user_elena_3',
        name: 'Elena Rostova',
        isOnline: false,
      ),
      'user_marcus_4': ChatUserProfile(
        userId: 'user_marcus_4',
        name: 'Marcus Vance',
        isOnline: true,
      ),
      'guest_demo_user_101': ChatUserProfile(
        userId: 'guest_demo_user_101',
        name: 'Alex Rivers (Guest)',
        isOnline: true,
      ),
    };
    return profiles[userId];
  }
}
