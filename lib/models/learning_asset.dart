import 'package:cloud_firestore/cloud_firestore.dart';

class LearningAsset {
  final String id;
  final String teacherId;
  final String teacherName;
  final String courseId;
  final String courseName;
  final String documentName;
  final String fileUrl;
  final String fileType;
  final DateTime uploadedAt;

  LearningAsset({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.courseId,
    required this.courseName,
    required this.documentName,
    required this.fileUrl,
    required this.fileType,
    required this.uploadedAt,
  });

  factory LearningAsset.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final uploadedAt = data['uploadedAt'];
    return LearningAsset(
      id: doc.id,
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      courseId: data['courseId'] ?? '',
      courseName: data['courseName'] ?? '',
      documentName: data['documentName'] ?? data['assetName'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      fileType: data['fileType'] ?? '',
      uploadedAt: uploadedAt is Timestamp
          ? uploadedAt.toDate()
          : DateTime.now(),
    );
  }
}
