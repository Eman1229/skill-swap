import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus { sending, sent, delivered, read, failed }

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final Timestamp timestamp;
  final MessageStatus status;
  final String type; // e.g., 'text', 'image', 'swap_proposal'
  final String? requestId;
  final String? sessionId;
  final String? swapId;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.status,
    required this.type,
    this.requestId,
    this.sessionId,
    this.swapId,
  });

  factory ChatMessage.fromMap(String docId, Map<String, dynamic> map) {
    MessageStatus status;
    switch (map['status'] as String?) {
      case 'sending':
        status = MessageStatus.sending;
        break;
      case 'failed':
        status = MessageStatus.failed;
        break;
      case 'delivered':
        status = MessageStatus.delivered;
        break;
      case 'read':
        status = MessageStatus.read;
        break;
      case 'sent':
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
      requestId: map['requestId'] as String?,
      sessionId: map['sessionId'] as String?,
      swapId: map['swapId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'status': status.name,
      'type': type,
      if (requestId != null) 'requestId': requestId,
      if (sessionId != null) 'sessionId': sessionId,
      if (swapId != null) 'swapId': swapId,
    };
  }
}
