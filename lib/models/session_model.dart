import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String swapId;
  final String title;
  final DateTime date;
  final String duration; // e.g., "1 hour"
  final String status; // 'pending', 'accepted', 'completed', 'cancelled'
  final DateTime createdAt;

  SessionModel({
    required this.id,
    required this.swapId,
    required this.title,
    required this.date,
    required this.duration,
    required this.status,
    required this.createdAt,
  });

  factory SessionModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SessionModel(
      id: doc.id,
      swapId: d['swapId'] ?? '',
      title: d['title'] ?? '',
      date: (d['date'] as Timestamp).toDate(),
      duration: d['duration'] ?? '',
      status: d['status'] ?? 'pending',
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'swapId': swapId,
      'title': title,
      'date': Timestamp.fromDate(date),
      'duration': duration,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
