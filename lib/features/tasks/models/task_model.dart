import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String projectId;
  final String projectName;
  final String title;
  final String status; // "To Do", "In Progress", "Done"
  final DateTime dueDate;
  final String assignedTo;
  final String assigneeName;
  final String assigneeInitials;
  final String assigneeRole;

  const TaskModel({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.title,
    required this.status,
    required this.dueDate,
    required this.assignedTo,
    required this.assigneeName,
    required this.assigneeInitials,
    required this.assigneeRole,
  });

  bool get isDone => status == 'Done';

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ts = data['dueDate'];
    DateTime date = DateTime.now();
    if (ts is Timestamp) {
      date = ts.toDate();
    }
    return TaskModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      projectName: data['projectName'] ?? '',
      title: data['title'] ?? '',
      status: data['status'] ?? 'To Do',
      dueDate: date,
      assignedTo: data['assignedTo'] ?? '',
      assigneeName: data['assigneeName'] ?? '',
      assigneeInitials: data['assigneeInitials'] ?? '',
      assigneeRole: data['assigneeRole'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'projectId': projectId,
        'projectName': projectName,
        'title': title,
        'status': status,
        'dueDate': Timestamp.fromDate(dueDate),
        'assignedTo': assignedTo,
        'assigneeName': assigneeName,
        'assigneeInitials': assigneeInitials,
        'assigneeRole': assigneeRole,
      };

  TaskModel copyWith({
    String? id,
    String? projectId,
    String? projectName,
    String? title,
    String? status,
    DateTime? dueDate,
    String? assignedTo,
    String? assigneeName,
    String? assigneeInitials,
    String? assigneeRole,
  }) =>
      TaskModel(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        projectName: projectName ?? this.projectName,
        title: title ?? this.title,
        status: status ?? this.status,
        dueDate: dueDate ?? this.dueDate,
        assignedTo: assignedTo ?? this.assignedTo,
        assigneeName: assigneeName ?? this.assigneeName,
        assigneeInitials: assigneeInitials ?? this.assigneeInitials,
        assigneeRole: assigneeRole ?? this.assigneeRole,
      );
}
