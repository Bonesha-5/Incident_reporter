import '../constants/app_constants.dart';

/// All form checks in one place, reused by every screen.
class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? fullName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter your full name';
    if (text.length < 3) return 'Name is too short';
    return null;
  }

  static bool isAluEmail(String email) {
    final e = email.trim().toLowerCase();
    return e.endsWith('@${AppConstants.studentEmailDomain}') ||
        e.endsWith('@${AppConstants.staffEmailDomain}');
  }

  static String? aluEmail(String? value) {
    final text = value?.trim().toLowerCase() ?? '';
    if (text.isEmpty) return 'Please enter your ALU email';
    if (!_emailPattern.hasMatch(text)) {
      return "That doesn't look like an email address";
    }
    if (!isAluEmail(text)) {
      return 'Please use your @${AppConstants.studentEmailDomain} '
          'or @${AppConstants.staffEmailDomain} email';
    }
    return null;
  }

  static String? newPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Please create a password';
    if (text.length < 8) return 'Use at least 8 characters';
    return null;
  }

  static String? loginPassword(String? value) =>
      (value == null || value.isEmpty) ? 'Please enter your password' : null;

  static String? Function(String?) confirmPassword(
    String Function() getPassword,
  ) {
    return (value) {
      if (value == null || value.isEmpty) {
        return 'Please type your password again';
      }
      if (value != getPassword()) return 'Passwords do not match';
      return null;
    };
  }

  /// 0 = empty, 1 = weak, 2 = okay, 3 = good, 4 = strong
  static int passwordStrength(String password) {
    if (password.isEmpty) return 0;
    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return score == 0 ? 1 : score;
  }
}
