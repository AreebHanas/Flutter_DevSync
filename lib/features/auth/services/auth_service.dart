import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register user with Firebase Auth then persist extra fields in Firestore.
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String studentId,
    required String role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final user = UserModel(
      uid: uid,
      fullName: fullName,
      studentId: studentId,
      role: role,
      email: email,
    );
    await _db.collection('users').doc(uid).set(user.toMap());
    return user;
  }

  /// Login and fetch user document from Firestore.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    return fetchUser(uid);
  }

  /// Retrieve user document from Firestore by uid.
  Future<UserModel> fetchUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return UserModel.fromFirestore(doc);
  }

  Future<void> signOut() => _auth.signOut();
}
