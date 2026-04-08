import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _tasks => _db.collection('tasks');
  CollectionReference get _projects => _db.collection('projects');

  // ------------------------------------------------------------------ reads

  /// Stream all tasks for a project.
  Stream<List<TaskModel>> watchProjectTasks(String projectId) {
    return _tasks
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map((s) => s.docs.map((d) => TaskModel.fromFirestore(d)).toList());
  }

  /// One-time fetch of tasks across multiple projects (for deadlines screen).
  Future<List<TaskModel>> getTasksForProjects(
      List<String> projectIds) async {
    if (projectIds.isEmpty) return [];

    // Firestore whereIn supports up to 30 items; chunk if needed.
    final List<TaskModel> results = [];
    const chunkSize = 30;
    for (var i = 0; i < projectIds.length; i += chunkSize) {
      final chunk = projectIds.sublist(
          i,
          i + chunkSize > projectIds.length
              ? projectIds.length
              : i + chunkSize);
      final snap = await _tasks
          .where('projectId', whereIn: chunk)
          .orderBy('dueDate')
          .get();
      results.addAll(snap.docs.map((d) => TaskModel.fromFirestore(d)));
    }
    return results;
  }

  // ----------------------------------------------------------------- writes

  /// Add a new task. Also increments totalTaskCount on the project.
  Future<void> addTask(TaskModel task) async {
    final batch = _db.batch();
    final taskRef = _tasks.doc();
    batch.set(taskRef, task.toMap());
    batch.update(_projects.doc(task.projectId), {
      'totalTaskCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  /// Update task fields. Handles completion count changes via batch write.
  Future<void> updateTask({
    required TaskModel oldTask,
    required TaskModel newTask,
  }) async {
    final batch = _db.batch();
    batch.update(_tasks.doc(newTask.id), newTask.toMap());

    final wasD = oldTask.isDone;
    final isD = newTask.isDone;

    if (!wasD && isD) {
      // Became done → increment completed count
      batch.update(_projects.doc(newTask.projectId), {
        'completedTaskCount': FieldValue.increment(1),
      });
    } else if (wasD && !isD) {
      // Reverted from done → decrement completed count
      batch.update(_projects.doc(newTask.projectId), {
        'completedTaskCount': FieldValue.increment(-1),
      });
    }

    await batch.commit();
  }

  /// Delete a task. Decrements project counts atomically in a batch write.
  Future<void> deleteTask(TaskModel task) async {
    final batch = _db.batch();
    batch.delete(_tasks.doc(task.id));

    final Map<String, dynamic> countUpdates = {
      'totalTaskCount': FieldValue.increment(-1),
    };
    if (task.isDone) {
      countUpdates['completedTaskCount'] = FieldValue.increment(-1);
    }
    batch.update(_projects.doc(task.projectId), countUpdates);

    await batch.commit();
  }
}
