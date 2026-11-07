import 'package:flutter_test/flutter_test.dart';
import 'package:alu_incident_reporter/core/utils/validators.dart';

void main() {
  group('ALU email', () {
    test('accepts student and staff domains', () {
      expect(Validators.aluEmail('aline@alustudent.com'), isNull);
      expect(Validators.aluEmail('staff@alueducation.com'), isNull);
    });

    test('ignores capital letters and spaces', () {
      expect(Validators.aluEmail('  Aline@ALUSTUDENT.com  '), isNull);
    });

    test('rejects other domains', () {
      expect(Validators.aluEmail('someone@gmail.com'), isNotNull);
      expect(Validators.aluEmail('aline@alustudent.org'), isNotNull);
    });

    test('rejects empty and badly formed emails', () {
      expect(Validators.aluEmail(''), 'Please enter your ALU email');
      expect(Validators.aluEmail('not-an-email'), isNotNull);
    });
  });

  group('Full name', () {
    test('requires a name of at least 3 characters', () {
      expect(Validators.fullName(''), 'Please enter your full name');
      expect(Validators.fullName('Al'), 'Name is too short');
      expect(Validators.fullName('Aline Uwase'), isNull);
    });
  });

  group('Passwords', () {
    test('new password needs at least 8 characters', () {
      expect(Validators.newPassword(''), 'Please create a password');
      expect(Validators.newPassword('short'), 'Use at least 8 characters');
      expect(Validators.newPassword('longenough'), isNull);
    });

    test('login password only needs to be filled in', () {
      expect(Validators.loginPassword(''), 'Please enter your password');
      expect(Validators.loginPassword('x'), isNull);
    });

    test('confirm password must match', () {
      final check = Validators.confirmPassword(() => 'Secret123');
      expect(check('Secret124'), 'Passwords do not match');
      expect(check(''), 'Please type your password again');
      expect(check('Secret123'), isNull);
    });

    test('strength goes from weak to strong', () {
      expect(Validators.passwordStrength(''), 0);
      expect(Validators.passwordStrength('abc'), 1);
      expect(Validators.passwordStrength('abcdefgh'), 1);
      expect(Validators.passwordStrength('Abcdefgh1'), 3);
      expect(Validators.passwordStrength('Abcdefgh1!'), 4);
    });
  });
}
