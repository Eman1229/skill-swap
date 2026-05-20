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
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Single dynamic stream for user details and presence
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

      // Query swapListings where userId matches to fetch profile image and actual name
      final listingsSnap = await _db
          .collection('swapListings')
          .where('userId', isEqualTo: userId)
          .get();

      String name = 'Unknown User';
      String? imageUrl;

      if (listingsSnap.docs.isNotEmpty) {
        final docs = List<QueryDocumentSnapshot>.from(listingsSnap.docs);
        // Sort in-memory to get the latest updated listing
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
        imageUrl = latestData['imageUrl'] as String? ?? latestData['imageUrl'];
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
