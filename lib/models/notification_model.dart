import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  chatMessage,
  swapRequest,
  session,
  assetUpload,
  system,
}

class NotificationModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderProfilePic;
  final String receiverId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final String? actionRoute;
  final String? actionId;
  final String? deepLink;
  final String? imageUrl;

  NotificationModel({
    required this.id,
    required this.senderId,
    this.senderName = 'Someone',
    this.senderProfilePic = '',
    required this.receiverId,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
    this.actionRoute,
    this.actionId,
    this.deepLink,
    this.imageUrl,
  });

  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    try {
      final d = doc.data() as Map<String, dynamic>? ?? {};

      final bool isReadField = d['isRead'] ?? d['read'] ?? false;

      NotificationType parsedType = NotificationType.system;
      final typeStr = d['type']?.toString();
      if (typeStr == 'chat_message' || typeStr == 'chat' || typeStr == 'chatMessage') {
        parsedType = NotificationType.chatMessage;
      } else if (typeStr == 'swap_request' || typeStr == 'swap' || typeStr == 'swapRequest') {
        parsedType = NotificationType.swapRequest;
      } else if (typeStr == 'session') {
        parsedType = NotificationType.session;
      } else if (typeStr == 'asset_upload' || typeStr == 'assetUpload') {
        parsedType = NotificationType.assetUpload;
      } else if (typeStr == 'system' ||
          typeStr == 'system_tip' ||
          typeStr == 'admin') {
        parsedType = NotificationType.system;
      }

      // Retrieve sender name and profile picture with robust fallbacks
      final String senderName =
          d['senderName'] ??
          d['data']?['senderName'] ??
          d['data']?['otherName'] ??
          d['title'] ??
          'Someone';
      final String senderProfilePic =
          d['senderProfilePic'] ??
          d['imageUrl'] ??
          d['data']?['senderProfilePic'] ??
          '';

      final String actionId =
          d['actionId'] ??
          d['relatedId'] ??
          d['data']?['conversationId'] ??
          d['data']?['requestId'] ??
          '';
      final String actionRoute =
          d['actionRoute'] ??
          d['route'] ??
          (parsedType == NotificationType.chatMessage
              ? '/chat'
              : parsedType == NotificationType.swapRequest
              ? '/swap'
              : '');

      return NotificationModel(
        id: doc.id,
        senderId: d['senderId'] ?? '',
        senderName: senderName,
        senderProfilePic: senderProfilePic,
        receiverId: d['receiverId'] ?? d['recipientId'] ?? '',
        type: parsedType,
        title: d['title'] ?? '',
        body: d['body'] ?? d['message'] ?? '',
        data: Map<String, dynamic>.from(d['data'] ?? {}),
        isRead: isReadField,
        createdAt: d['createdAt'] is Timestamp
            ? (d['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        actionRoute: actionRoute,
        actionId: actionId,
        deepLink: d['deepLink'] ?? '',
        imageUrl: d['imageUrl'] ?? senderProfilePic,
      );
    } catch (e) {
      debugPrint("NotificationModel parsing error for doc ${doc.id}: $e");
      return NotificationModel(
        id: doc.id,
        senderId: '',
        senderName: 'System Alert',
        senderProfilePic: '',
        receiverId: '',
        type: NotificationType.system,
        title: 'System Alert',
        body: 'Failed to parse notification details.',
        createdAt: DateTime.now(),
        isRead: true,
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderProfilePic': senderProfilePic,
      'receiverId': receiverId,
      'type': type.name,
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'read': isRead,
      'createdAt': FieldValue.serverTimestamp(),
      'actionRoute': actionRoute,
      'actionId': actionId,
      'deepLink': deepLink,
      'imageUrl': imageUrl,
    };
  }
}
