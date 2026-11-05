import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart'
    show User, FirebaseAuthException;
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

/// Which screen the app should show.
enum AuthStatus { loading, signedOut, unverified, signedIn }

/// Holds who is logged in, whether we're busy, and any error message.
/// Every screen listens to this, so they all update together.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service) {
    _subscription = _service.authStateChanges().listen(_handleAuthChange);
  }

  final AuthService _service;
  StreamSubscription<User?>? _subscription;

  AuthStatus _status = AuthStatus.loading;
  AppUser? _user;
  bool _isBusy = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  String? get pendingEmail => _service.currentUser?.email;

  Future<void> _handleAuthChange(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    if (!firebaseUser.emailVerified) {
      _user = null;
      _status = AuthStatus.unverified;
      notifyListeners();
      return;
    }
    await _loadProfile(firebaseUser);
  }

  Future<void> _loadProfile(User firebaseUser) async {
    try {
      _user = await _service.fetchOrCreateProfile(firebaseUser);
      _status = AuthStatus.signedIn;
      notifyListeners();
    } catch (_) {
      _errorMessage = "We couldn't load your profile. Check your internet and log in again.";
      await _service.logout();
    }
  }

  Future<bool> login(String email, String password) =>
      _run(() => _service.login(email: email, password: password));

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) => _run(
    () =>
        _service.register(fullName: fullName, email: email, password: password),
  );

  Future<bool> sendPasswordReset(String email) =>
      _run(() => _service.sendPasswordReset(email));

  Future<bool> resendVerificationEmail() =>
      _run(_service.resendVerificationEmail);

  /// The "I've verified my email" button. Firebase is asked again,
  /// so tapping it without verifying does nothing.
  Future<bool> checkEmailVerified() => _run(() async {
    final verified = await _service.reloadAndCheckVerified();
    if (!verified) {
      throw FirebaseAuthException(code: 'not-verified');
    }
    await _loadProfile(_service.currentUser!);
  });

  Future<void> logout() => _service.logout();

  /// The "Status update alerts" switch on Profile.
  /// Updates the screen at once, and undoes it if saving fails.
  Future<bool> setNotifyStatusUpdates(bool value) async {
    final previous = _user;
    if (previous == null) return false;
    _user = previous.copyWith(notifyStatusUpdates: value);
    notifyListeners();
    try {
      await _service.updateNotifyPreference(previous.uid, value);
      return true;
    } catch (_) {
      _user = previous;
      notifyListeners();
      return false;
    }
  }

  /// Clears an old error when a new screen opens.
  void clearError() => _errorMessage = null;

  /// Runs an action with loading and error handling.
  Future<bool> _run(Future<void> Function() action) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _friendlyMessage(e.code);
      return false;
    } on FirebaseException catch (_) {
      _errorMessage = 'Something went wrong on our side. Please try again.';
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Turns Firebase error codes into messages people understand.
  static String _friendlyMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return "That email address isn't valid.";
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in.';
      case 'weak-password':
        return 'That password is too weak. Use at least 8 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a few minutes and try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your Wi-Fi or mobile data.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'not-verified':
        return "Your email isn't verified yet. Open the link in your inbox first.";
      default:
        return 'Something went wrong ($code). Please try again.';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
