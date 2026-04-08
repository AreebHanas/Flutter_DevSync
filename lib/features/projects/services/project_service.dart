import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';
import '../../auth/models/user_model.dart';

class ProjectService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _projects => _db.collection('projects');

  /// Stream of projects where the current user is a member.
  Stream<List<ProjectModel>> watchUserProjects(String uid) {
    return _projects
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ProjectModel.fromFirestore(d)).toList());
  }

  /// Get all project IDs the user is a member of (one-time fetch).
  Future<List<ProjectModel>> getUserProjects(String uid) async {
    final snap = await _projects
        .where('memberIds', arrayContains: uid)
        .get();
    return snap.docs.map((d) => ProjectModel.fromFirestore(d)).toList();
  }

  /// Fetch a single project document.
  Future<ProjectModel> getProject(String projectId) async {
    final doc = await _projects.doc(projectId).get();
    return ProjectModel.fromFirestore(doc);
  }

  /// Create a new project.
  Future<String> createProject(ProjectModel project) async {
    final ref = await _projects.add(project.toMap());
    return ref.id;
  }

  /// Update a project document.
  Future<void> updateProject(String projectId, Map<String, dynamic> data) {
    return _projects.doc(projectId).update(data);
  }

  /// Delete a project document.
  Future<void> deleteProject(String projectId) {
    return _projects.doc(projectId).delete();
  }

  /// Search users by email prefix (case-sensitive, up to 10 results).
  Future<List<UserModel>> searchUsersByEmail(String query) async {
    if (query.trim().isEmpty) return [];
    final snap = await _db
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: query.trim())
        .where('email', isLessThan: '${query.trim()}\uF8FF')
        .limit(10)
        .get();
    return snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
  }

  /// Add a user to a project's memberIds array.
  Future<void> addMemberToProject(String projectId, String userId) {
    return _projects.doc(projectId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
  }

  /// Fetch members of a project from the users collection.
  Future<List<Map<String, dynamic>>> getProjectMembers(
      List<String> memberIds) async {
    if (memberIds.isEmpty) return [];
    // Firestore 'whereIn' supports up to 30 values.
    final snap = await _db
        .collection('users')
        .where(FieldPath.documentId, whereIn: memberIds)
        .get();
    return snap.docs
        .map((d) => {'uid': d.id, ...d.data()})
        .toList();
  }
}
