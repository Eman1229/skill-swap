import 'package:cloud_firestore/cloud_firestore.dart';

enum SwapRequestStatus { pending, accepted, rejected, cancelled, completed }

class SwapRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String receiverName;
  final String offeredSkill;
  final String requestedSkill;
  final SwapRequestStatus status;
  final DateTime createdAt;
  final String conversationId;

  SwapRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.receiverName,
    required this.offeredSkill,
    required this.requestedSkill,
    required this.status,
    required this.createdAt,
    required this.conversationId,
  });

  factory SwapRequest.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SwapRequest(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      senderName: data['senderName'] ?? '',
      receiverName: data['receiverName'] ?? '',
      offeredSkill: data['offeredSkill'] ?? '',
      requestedSkill: data['requestedSkill'] ?? '',
      status: SwapRequestStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => SwapRequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      conversationId: data['conversationId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'receiverName': receiverName,
      'offeredSkill': offeredSkill,
      'requestedSkill': requestedSkill,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
      'conversationId': conversationId,
    };
  }
}
