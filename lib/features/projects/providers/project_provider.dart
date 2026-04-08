import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';
import '../../auth/models/user_model.dart';

class ProjectProvider extends ChangeNotifier {
  final ProjectService _service = ProjectService();

  List<ProjectModel> _projects = [];
  ProjectModel? _selectedProject;
  bool _isLoading = false;
  String? _errorMessage;

  List<ProjectModel> get projects => _projects;
  ProjectModel? get selectedProject => _selectedProject;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void selectProject(ProjectModel p) {
    _selectedProject = p;
    notifyListeners();
  }

  Stream<List<ProjectModel>> watchUserProjects(String uid) {
    return _service.watchUserProjects(uid);
  }

  Future<void> loadUserProjects(String uid) async {
    _setLoading(true);
    try {
      _projects = await _service.getUserProjects(uid);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<List<UserModel>> searchUsersByEmail(String query) {
    return _service.searchUsersByEmail(query);
  }

  Future<void> addMemberToProject(String projectId, String userId) async {
    await _service.addMemberToProject(projectId, userId);
    // Refresh local list
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx != -1) {
      final updated = _projects[idx];
      final newIds = [...updated.memberIds, userId];
      _projects[idx] = updated.copyWith(memberIds: newIds);
      notifyListeners();
    }
  }

  Future<void> createProject({
    required String title,
    required String description,
    required String createdBy,
    required List<String> memberIds,
  }) async {
    final project = ProjectModel(
      id: '',
      title: title,
      description: description,
      createdBy: createdBy,
      memberIds: memberIds,
      totalTaskCount: 0,
      completedTaskCount: 0,
    );
    final id = await _service.createProject(project);
    _projects.add(project.copyWith(id: id));
    notifyListeners();
  }
}
