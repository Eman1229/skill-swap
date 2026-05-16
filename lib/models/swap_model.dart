import 'package:cloud_firestore/cloud_firestore.dart';

class SwapModel {
  final String id;
  final String mentorId;
  final String learnerId;
  final String mentorName;
  final String learnerName;
  final String skillName;
  final String status; // 'ongoing', 'completed', 'paused'
  final double progress;
  final String conversationId;
  final int completedSessions;
  final int totalSessions;
  final DateTime? lastSessionAt;
  final DateTime createdAt;

  SwapModel({
    required this.id,
    required this.mentorId,
    required this.learnerId,
    required this.mentorName,
    required this.learnerName,
    required this.skillName,
    required this.status,
    required this.progress,
    required this.conversationId,
    required this.completedSessions,
    required this.totalSessions,
    this.lastSessionAt,
    required this.createdAt,
  });

  factory SwapModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SwapModel(
      id: doc.id,
      mentorId: d['mentorId'] ?? '',
      learnerId: d['learnerId'] ?? '',
      mentorName: d['mentorName'] ?? '',
      learnerName: d['learnerName'] ?? '',
      skillName: d['skillName'] ?? '',
      status: d['status'] ?? 'ongoing',
      progress: (d['progress'] as num?)?.toDouble() ?? 0.0,
      conversationId: d['conversationId'] ?? '',
      completedSessions: d['completedSessions'] ?? 0,
      totalSessions: d['totalSessions'] ?? 0,
      lastSessionAt: (d['lastSessionAt'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mentorId': mentorId,
      'learnerId': learnerId,
      'mentorName': mentorName,
      'learnerName': learnerName,
      'skillName': skillName,
      'status': status,
      'progress': progress,
      'conversationId': conversationId,
      'completedSessions': completedSessions,
      'totalSessions': totalSessions,
      'lastSessionAt': lastSessionAt != null ? Timestamp.fromDate(lastSessionAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
