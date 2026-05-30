import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus { sent, delivered, read }

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final Timestamp timestamp;
  final MessageStatus status;
  final String type; // e.g., 'text', 'image', 'swap_proposal'

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.status,
    required this.type,
  });

  factory ChatMessage.fromMap(String docId, Map<String, dynamic> map) {
    MessageStatus status;
    switch (map['status'] as String?) {
      case 'delivered':
        status = MessageStatus.delivered;
        break;
      case 'read':
        status = MessageStatus.read;
        break;
      default:
        status = MessageStatus.sent;
    }
    return ChatMessage(
      id: docId,
      senderId: map['senderId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      timestamp: map['timestamp'] as Timestamp? ?? Timestamp.now(),
      status: status,
      type: map['type'] as String? ?? 'text',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'status': status.name,
      'type': type,
    };
  }
}
