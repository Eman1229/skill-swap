import 'package:cloud_firestore/cloud_firestore.dart';

enum ConversationStatus { active, archived }

class Conversation {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final Timestamp? lastMessageAt;
  final int unreadCount;
  final String skill;
  final String wanting;
  final ConversationStatus status;

  Conversation({
    required this.id,
    required this.participants,
    required this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    required this.skill,
    required this.wanting,
    this.status = ConversationStatus.active,
  });

  factory Conversation.fromMap(String docId, Map<String, dynamic> map) {
    return Conversation(
      id: docId,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageAt: map['lastMessageAt'] as Timestamp?,
      unreadCount: (map['unreadCount'] as Map<String, dynamic>?)?.values
              .fold<int>(0, (prev, v) => prev + (v as int)) ??
          0,
      skill: map['skill'] as String? ?? '',
      wanting: map['wanting'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt,
      'unreadCount': unreadCount,
      'skill': skill,
      'wanting': wanting,
    };
  }
}
