import 'package:flutter/material.dart';

/// One incident category, e.g. Water.
class IncidentCategory {
  final String id;
  final String label;
  final IconData icon;

  const IncidentCategory(this.id, this.label, this.icon);
}

/// Fixed lists shared by the whole app.
class AppConstants {
  AppConstants._();

  // Only these email domains can register
  static const String studentEmailDomain = 'alustudent.com';
  static const String staffEmailDomain = 'alueducation.com';

  // Firestore collection names (typed once, used everywhere)
  static const String usersCollection = 'users';
  static const String incidentsCollection = 'incidents';
  static const String updatesCollection = 'updates';
  static const String notificationsCollection = 'notifications';

  // Roles
  static const String roleStudent = 'student';
  static const String roleStaff = 'staff';

  static const List<IncidentCategory> categories = [
    IncidentCategory('water', 'Water', Icons.water_drop_outlined),
    IncidentCategory('electricity', 'Electricity', Icons.bolt_outlined),
    IncidentCategory('facilities', 'Facilities', Icons.apartment_outlined),
    IncidentCategory('furniture', 'Furniture', Icons.chair_outlined),
    IncidentCategory(
      'sanitation',
      'Sanitation',
      Icons.cleaning_services_outlined,
    ),
    IncidentCategory('safety', 'Safety', Icons.shield_outlined),
    IncidentCategory('internet', 'Internet', Icons.wifi_rounded),
    IncidentCategory('other', 'Other', Icons.more_horiz_rounded),
  ];

  static const Map<String, String> statuses = {
    'submitted': 'Submitted',
    'in_review': 'In review',
    'in_progress': 'In progress',
    'resolved': 'Resolved',
    'rejected': 'Rejected',
  };

  static const Map<String, String> urgencyLevels = {
    'low': 'Low',
    'medium': 'Medium',
    'high': 'High',
    'emergency': 'Emergency',
  };

  static const List<String> campusLocations = [
    'Student residence',
    'Library',
    'Leadership Commons',
    'Enterprise Commons',
    'Social Commons',
    'GreenHouse Area',
    'Cafeteria',
    'Sports area',
    'Outdoor paths & gate',
  ];
}
