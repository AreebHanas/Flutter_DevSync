import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final List<String> memberIds;
  final int totalTaskCount;
  final int completedTaskCount;

  const ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.memberIds,
    required this.totalTaskCount,
    required this.completedTaskCount,
  });

  double get progressPercent {
    if (totalTaskCount == 0) return 0.0;
    return completedTaskCount / totalTaskCount;
  }

  int get progressPercentInt => (progressPercent * 100).round();

  int get pendingTaskCount =>
      totalTaskCount - completedTaskCount < 0
          ? 0
          : totalTaskCount - completedTaskCount;

  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      totalTaskCount: (data['totalTaskCount'] ?? 0) as int,
      completedTaskCount: (data['completedTaskCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'createdBy': createdBy,
        'memberIds': memberIds,
        'totalTaskCount': totalTaskCount,
        'completedTaskCount': completedTaskCount,
      };

  ProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    List<String>? memberIds,
    int? totalTaskCount,
    int? completedTaskCount,
  }) =>
      ProjectModel(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        createdBy: createdBy ?? this.createdBy,
        memberIds: memberIds ?? this.memberIds,
        totalTaskCount: totalTaskCount ?? this.totalTaskCount,
        completedTaskCount: completedTaskCount ?? this.completedTaskCount,
      );
}
