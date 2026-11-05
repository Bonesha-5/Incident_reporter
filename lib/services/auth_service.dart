import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';
import '../models/app_user.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(AppConstants.usersCollection);

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(fullName.trim());

    // Everyone starts as a student. Staff are promoted in the Console.
    final profile = AppUser(
      uid: user.uid,
      fullName: fullName.trim(),
      email: user.email ?? email.trim().toLowerCase(),
      role: AppConstants.roleStudent,
    );
    await _users.doc(user.uid).set(profile.toNewUserMap());
    await user.sendEmailVerification();
  }

  Future<void> login({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

  Future<void> logout() => _auth.signOut();

  Future<void> updateNotifyPreference(String uid, bool value) =>
      _users.doc(uid).update({'notifyStatusUpdates': value});

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());

  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<bool> reloadAndCheckVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final verified = _auth.currentUser?.emailVerified ?? false;
    if (verified) {
      // Refresh the login token so security rules see "verified" too
      await _auth.currentUser?.getIdToken(true);
    }
    return verified;
  }

  /// Loads the user's profile, creating it if it's missing.
  Future<AppUser> fetchOrCreateProfile(User user) async {
    final ref = _users.doc(user.uid);
    final snapshot = await ref.get();
    if (snapshot.exists) return AppUser.fromDoc(snapshot);

    final profile = AppUser(
      uid: user.uid,
      fullName: user.displayName ?? '',
      email: user.email ?? '',
      role: AppConstants.roleStudent,
    );
    await ref.set(profile.toNewUserMap());
    return profile;
  }
}
