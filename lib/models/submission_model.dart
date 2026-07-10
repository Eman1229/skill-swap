import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String id;
  final String assignmentId;
  final String learnerId;
  final String learnerName;
  final String fileUrl;
  final String fileName;
  final String submissionText;
  final DateTime submittedAt;
  final String feedback;
  final String grade;
  final String status; // 'pending', 'graded'

  SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.learnerId,
    required this.learnerName,
    required this.fileUrl,
    required this.fileName,
    this.submissionText = '',
    required this.submittedAt,
    this.feedback = '',
    this.grade = '',
    required this.status,
  });

  factory SubmissionModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final submittedField = d['submittedAt'];
    return SubmissionModel(
      id: doc.id,
      assignmentId: d['assignmentId'] ?? '',
      learnerId: d['learnerId'] ?? '',
      learnerName: d['learnerName'] ?? '',
      fileUrl: d['fileUrl'] ?? '',
      fileName: d['fileName'] ?? '',
      submissionText: d['submissionText'] ?? '',
      submittedAt: submittedField is Timestamp ? submittedField.toDate() : DateTime.now(),
      feedback: d['feedback'] ?? '',
      grade: d['grade']?.toString() ?? '',
      status: d['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'submissionId': id,
      'assignmentId': assignmentId,
      'learnerId': learnerId,
      'learnerName': learnerName,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'submissionText': submissionText,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'feedback': feedback,
      'grade': grade,
      'status': status,
    };
  }

  SubmissionModel copyWith({
    String? id,
    String? assignmentId,
    String? learnerId,
    String? learnerName,
    String? fileUrl,
    String? fileName,
    String? submissionText,
    DateTime? submittedAt,
    String? feedback,
    String? grade,
    String? status,
  }) {
    return SubmissionModel(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      learnerId: learnerId ?? this.learnerId,
      learnerName: learnerName ?? this.learnerName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      submissionText: submissionText ?? this.submissionText,
      submittedAt: submittedAt ?? this.submittedAt,
      feedback: feedback ?? this.feedback,
      grade: grade ?? this.grade,
      status: status ?? this.status,
    );
  }
}
