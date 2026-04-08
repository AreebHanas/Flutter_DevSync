import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService _service = TaskService();

  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  Stream<List<TaskModel>> watchProjectTasks(String projectId) {
    return _service.watchProjectTasks(projectId);
  }

  Future<List<TaskModel>> getTasksForProjects(List<String> ids) {
    return _service.getTasksForProjects(ids);
  }

  Future<void> addTask(TaskModel task) async {
    await _service.addTask(task);
  }

  Future<void> updateTask({
    required TaskModel oldTask,
    required TaskModel newTask,
  }) async {
    await _service.updateTask(oldTask: oldTask, newTask: newTask);
    final idx = _tasks.indexWhere((t) => t.id == newTask.id);
    if (idx != -1) {
      _tasks[idx] = newTask;
      notifyListeners();
    }
  }

  Future<void> deleteTask(TaskModel task) async {
    await _service.deleteTask(task);
    _tasks.removeWhere((t) => t.id == task.id);
    notifyListeners();
  }
}
