import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String swapId;
  final String title;
  final DateTime date;
  final String duration;
  final String meetingLink;
  final String mentorId;
  final String learnerId;
  final String mentorName;
  final String learnerName;
  final List<String> participantIds;
  final String status;
  /// Persisted in Firestore so a scheduled session cannot be completed early.
  final bool isLocked;
  final DateTime createdAt;

  SessionModel({
    required this.id,
    required this.swapId,
    required this.title,
    required this.date,
    required this.duration,
    this.meetingLink = '',
    this.mentorId = '',
    this.learnerId = '',
    this.mentorName = '',
    this.learnerName = '',
    this.participantIds = const [],
    required this.status,
    this.isLocked = false,
    required this.createdAt,
  });

  factory SessionModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final dateField = d['date'] ?? d['sessionDate'];
    final createdAtField = d['createdAt'];
    return SessionModel(
      id: doc.id,
      swapId: d['swapId'] ?? '',
      title: d['title'] ?? '',
      date: dateField is Timestamp ? dateField.toDate() : DateTime.now(),
      duration: d['duration'] ?? '',
      meetingLink: d['meetingLink'] ?? '',
      mentorId: d['mentorId'] ?? '',
      learnerId: d['learnerId'] ?? '',
      mentorName: d['mentorName'] ?? '',
      learnerName: d['learnerName'] ?? '',
      participantIds: List<String>.from(d['participantIds'] ?? const []),
      status: d['status'] ?? 'pending',
      isLocked: d['isLocked'] == true,
      createdAt: createdAtField is Timestamp
          ? createdAtField.toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': id,
      'swapId': swapId,
      'title': title,
      'date': Timestamp.fromDate(date),
      'sessionDate': Timestamp.fromDate(date),
      'sessionTime':
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
      'duration': duration,
      'meetingLink': meetingLink,
      'mentorId': mentorId,
      'learnerId': learnerId,
      'mentorName': mentorName,
      'learnerName': learnerName,
      'participantIds': participantIds,
      'status': status,
      'isLocked': isLocked,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  SessionModel copyWith({
    String? id,
    String? swapId,
    String? title,
    DateTime? date,
    String? duration,
    String? meetingLink,
    String? mentorId,
    String? learnerId,
    String? mentorName,
    String? learnerName,
    List<String>? participantIds,
    String? status,
    bool? isLocked,
    DateTime? createdAt,
  }) {
    return SessionModel(
      id: id ?? this.id,
      swapId: swapId ?? this.swapId,
      title: title ?? this.title,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      meetingLink: meetingLink ?? this.meetingLink,
      mentorId: mentorId ?? this.mentorId,
      learnerId: learnerId ?? this.learnerId,
      mentorName: mentorName ?? this.mentorName,
      learnerName: learnerName ?? this.learnerName,
      participantIds: participantIds ?? this.participantIds,
      status: status ?? this.status,
      isLocked: isLocked ?? this.isLocked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
