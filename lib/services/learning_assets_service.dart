import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skill_swap/models/learning_asset.dart';
import 'package:skill_swap/models/swap_model.dart';

class LearningAssetsService {
  LearningAssetsService({
    FirebaseFirestore? firestore,
    SupabaseClient? supabase,
  }) : _db = firestore ?? FirebaseFirestore.instance,
        _supabase = supabase ?? Supabase.instance.client;

  final FirebaseFirestore _db;
  final SupabaseClient _supabase;

  static const String _bucketName = 'learning-assets';

  Stream<List<LearningAsset>> watchCourseAssets(String courseId) {
    return _db
        .collection('assets')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snap) {
      final assets = snap.docs.map(LearningAsset.fromDoc).toList();
      assets.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return assets;
    });
  }

  Future<void> uploadAsset({
    required SwapModel course,
    required String teacherId,
    required String teacherName,
    required String documentTitle,
    required String fileName,
    required String fileType,
    required Uint8List fileBytes,
  }) async {
    final assetRef = _db.collection('assets').doc();
    final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]+'), '_');
    final filePath = '${course.id}/${assetRef.id}_$safeName';

    await _supabase.storage
        .from(_bucketName)
        .uploadBinary(
      filePath,
      fileBytes,
      fileOptions: FileOptions(
        contentType: _resolveMimeType(fileType, fileName),
      ),
    );

    final fileUrl = _supabase.storage
        .from(_bucketName)
        .getPublicUrl(filePath);

    final documentName = documentTitle.trim().isEmpty
        ? fileName
        : documentTitle.trim();

    final assetData = {
      'assetId': assetRef.id,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'courseId': course.id,
      'courseName': course.skillName,
      'assetName': documentName,
      'documentName': documentName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'uploadedAt': FieldValue.serverTimestamp(),
    };

    final batch = _db.batch();
    batch.set(assetRef, assetData);

    final learnerIds = <String>{course.learnerId}
      ..removeWhere((id) => id.isEmpty || id == teacherId);

    for (final learnerId in learnerIds) {
      final notificationRef = _db.collection('notifications').doc();
      final message =
          '$teacherName uploaded \'$documentName\' for ${course.skillName}.';
      batch.set(notificationRef, {
        'notificationId': notificationRef.id,
        'receiverId': learnerId,
        'senderId': teacherId,
        'senderName': teacherName,
        'type': 'asset_upload',
        'courseId': course.id,
        'courseName': course.skillName,
        'assetId': assetRef.id,
        'title': 'New Learning Asset',
        'message': message,
        'body': message,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'actionRoute': '/course-assets',
        'actionId': assetRef.id,
        'data': {
          'type': 'asset_upload',
          'courseId': course.id,
          'courseName': course.skillName,
          'assetId': assetRef.id,
          'senderName': teacherName,
        },
      });
    }

    await batch.commit();
  }

  /// Ensures we always send a proper MIME type (e.g. "application/pdf")
  /// to Supabase Storage, even if [fileType] only holds a raw extension
  /// like "pdf" from the file picker.
  String _resolveMimeType(String fileType, String fileName) {
    final normalized = fileType.trim().toLowerCase();
    if (normalized.contains('/')) {
      // Already a valid-looking MIME type (e.g. "application/pdf").
      return normalized;
    }

    final ext = normalized.isNotEmpty
        ? normalized.replaceAll('.', '')
        : fileName.split('.').last.toLowerCase();

    const mimeMap = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'zip': 'application/zip',
    };

    return mimeMap[ext] ?? 'application/octet-stream';
  }

  Future<void> renameAsset({
    required String assetId,
    required String documentName,
  }) async {
    await _db.collection('assets').doc(assetId).update({
      'assetName': documentName.trim(),
      'documentName': documentName.trim(),
    });
  }

  Future<void> deleteAsset(LearningAsset asset) async {
    await _db.collection('assets').doc(asset.id).delete();
    try {
      final uri = Uri.parse(asset.fileUrl);

      final path = uri.pathSegments
          .skipWhile((segment) => segment != _bucketName)
          .skip(1)
          .join('/');

      if (path.isNotEmpty) {
        await _supabase.storage.from(_bucketName).remove([path]);
      }
    } catch (_) {}
  }
}