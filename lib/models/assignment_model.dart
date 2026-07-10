import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentModel {
  final String id;
  final String swapId;
  final String title;
  final String description;
  final DateTime dueDate;
  final int xp;
  final DateTime createdAt;

  AssignmentModel({
    required this.id,
    required this.swapId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.xp,
    required this.createdAt,
  });

  factory AssignmentModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final dueField = d['dueDate'];
    final createdField = d['createdAt'];
    return AssignmentModel(
      id: doc.id,
      swapId: d['swapId'] ?? '',
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      dueDate: dueField is Timestamp ? dueField.toDate() : DateTime.now(),
      xp: d['xp'] ?? 50,
      createdAt: createdField is Timestamp ? createdField.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': id,
      'swapId': swapId,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'xp': xp,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AssignmentModel copyWith({
    String? id,
    String? swapId,
    String? title,
    String? description,
    DateTime? dueDate,
    int? xp,
    DateTime? createdAt,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      swapId: swapId ?? this.swapId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      xp: xp ?? this.xp,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
