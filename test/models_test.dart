import 'package:flutter_test/flutter_test.dart';
import 'package:alu_incident_reporter/core/utils/formatters.dart';
import 'package:alu_incident_reporter/models/app_user.dart';
import 'package:alu_incident_reporter/models/incident.dart';

Incident makeIncident({
  String category = 'water',
  String? otherCategory,
  String status = 'submitted',
  String? locationDetail,
  List<String> meTooUserIds = const [],
  int meTooCount = 0,
}) {
  final time = DateTime(2026, 11, 3, 8, 10);
  return Incident(
    id: 'abc123',
    refCode: 'ALU-ABC123',
    title: 'No water in residence',
    description: 'No running water since this morning.',
    category: category,
    otherCategory: otherCategory,
    location: 'Library',
    locationDetail: locationDetail,
    urgency: 'high',
    status: status,
    reporterId: 'user-1',
    isAnonymous: false,
    meTooUserIds: meTooUserIds,
    meTooCount: meTooCount,
    createdAt: time,
    updatedAt: time,
  );
}

void main() {
  group('AppUser', () {
    AppUser user(String name, {String role = 'student'}) => AppUser(
      uid: 'u',
      fullName: name,
      email: 'a@alustudent.com',
      role: role,
    );

    test('initials use the first and last name', () {
      expect(user('Aline Uwase').initials, 'AU');
      expect(user('Aline Marie Uwase').initials, 'AU');
      expect(user('aline').initials, 'A');
      expect(user('').initials, '?');
    });

    test('isStaff follows the role', () {
      expect(user('A B').isStaff, isFalse);
      expect(user('A B', role: 'staff').isStaff, isTrue);
    });
  });

  group('Incident', () {
    test('category label shows the typed text for Other', () {
      expect(makeIncident().categoryLabel, 'Water');
      expect(
        makeIncident(category: 'other', otherCategory: 'Insects').categoryLabel,
        'Insects',
      );
      expect(makeIncident(category: 'other').categoryLabel, 'Other');
    });

    test('affected count includes the reporter', () {
      expect(makeIncident().affectedCount, 1);
      expect(makeIncident(meTooCount: 2).affectedCount, 3);
    });

    test('full location adds the exact spot when given', () {
      expect(makeIncident().fullLocation, 'Library');
      expect(
        makeIncident(locationDetail: '2nd floor').fullLocation,
        'Library · 2nd floor',
      );
    });

    test('can only be edited while submitted', () {
      expect(makeIncident().canBeEdited, isTrue);
      expect(makeIncident(status: 'in_review').canBeEdited, isFalse);
      expect(makeIncident(status: 'resolved').canBeEdited, isFalse);
    });

    test('knows its reporter and its Me too followers', () {
      final incident = makeIncident(meTooUserIds: ['user-2'], meTooCount: 1);
      expect(incident.isReportedBy('user-1'), isTrue);
      expect(incident.hasMeTooFrom('user-2'), isTrue);
      expect(incident.hasMeTooFrom('user-3'), isFalse);
    });

    test('status label is readable', () {
      expect(makeIncident(status: 'in_progress').statusLabel, 'In progress');
    });
  });

  group('Formatters', () {
    test('timeAgo gives short relative times', () {
      final now = DateTime.now();
      expect(
        Formatters.timeAgo(now.subtract(const Duration(seconds: 20))),
        'just now',
      );
      expect(
        Formatters.timeAgo(now.subtract(const Duration(minutes: 5))),
        '5m ago',
      );
      expect(
        Formatters.timeAgo(now.subtract(const Duration(hours: 3))),
        '3h ago',
      );
      expect(
        Formatters.timeAgo(now.subtract(const Duration(days: 2))),
        '2d ago',
      );
    });

    test('dateTime prints day, month and time', () {
      expect(Formatters.dateTime(DateTime(2026, 11, 3, 8, 5)), '3 Nov, 08:05');
    });
  });
}
