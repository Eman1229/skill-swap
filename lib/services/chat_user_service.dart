import 'package:cloud_firestore/cloud_firestore.dart';

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
  
  // Cache base profile info to prevent heavy listing lookups
  final Map<String, ({String name, String? imageUrl})> _baseInfoCache = {};

  Stream<ChatUserProfile> getUserProfile(String userId) {
    if (userId.isEmpty) {
      return Stream.value(const ChatUserProfile(
        userId: '',
        name: 'Unknown User',
        isOnline: false,
      ));
    }

    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) async {
      final userData = userDoc.data();
      final bool isOnline = (userData?['isOnline'] as bool?) ?? false;
      final Timestamp? lastSeen = userData?['lastSeen'] as Timestamp?;

      String name = 'Unknown User';
      String? imageUrl;

      // 1. Check if name/image is already in main user doc (optimization)
      if (userData?['name'] != null) {
        name = userData!['name'];
        imageUrl = userData['imageUrl'];
      } 
      // 2. Check cache
      else if (_baseInfoCache.containsKey(userId)) {
        final cached = _baseInfoCache[userId]!;
        name = cached.name;
        imageUrl = cached.imageUrl;
      } 
      // 3. Fallback to slow listing lookup
      else {
        final listingsSnap = await _db
            .collection('swapListings')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        if (listingsSnap.docs.isNotEmpty) {
          final data = listingsSnap.docs.first.data();
          name = data['name'] as String? ?? 'Unknown User';
          imageUrl = data['imageUrl'] as String?;
          
          _baseInfoCache[userId] = (name: name, imageUrl: imageUrl);
        }
      }

      return ChatUserProfile(
        userId: userId,
        name: name,
        imageUrl: imageUrl,
        isOnline: isOnline,
        lastSeen: lastSeen,
      );
    });
  }
}
