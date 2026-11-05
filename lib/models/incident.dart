import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';

/// One report, as stored in the Firestore "incidents" collection.
class Incident {
  final String id;
  final String refCode;
  final String title;
  final String description;
  final String category;
  final String? otherCategory;
  final String location;
  final String? locationDetail;
  final String urgency;
  final String? photoUrl;
  final String status;
  final String reporterId;
  final bool isAnonymous;
  final String? reporterName;
  final List<String> meTooUserIds;
  final int meTooCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Incident({
    required this.id,
    required this.refCode,
    required this.title,
    required this.description,
    required this.category,
    this.otherCategory,
    required this.location,
    this.locationDetail,
    required this.urgency,
    this.photoUrl,
    required this.status,
    required this.reporterId,
    required this.isAnonymous,
    this.reporterName,
    this.meTooUserIds = const [],
    this.meTooCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // ---------- Handy getters used by the screens ----------

  IncidentCategory get categoryInfo => AppConstants.categories.firstWhere(
    (c) => c.id == category,
    orElse: () => AppConstants.categories.last,
  );

  /// "Water", or the typed text when the category is "Other"
  String get categoryLabel =>
      (category == 'other' && (otherCategory ?? '').isNotEmpty)
      ? otherCategory!
      : categoryInfo.label;

  String get statusLabel => AppConstants.statuses[status] ?? status;
  String get urgencyLabel => AppConstants.urgencyLevels[urgency] ?? urgency;

  /// Reporter + everyone who tapped Me too
  int get affectedCount => meTooCount + 1;

  /// "Student residence · 2nd floor bathrooms"
  String get fullLocation =>
      (locationDetail ?? '').isEmpty ? location : '$location · $locationDetail';

  /// Students can only edit or delete while staff haven't started
  bool get canBeEdited => status == 'submitted';

  bool isReportedBy(String uid) => reporterId == uid;
  bool hasMeTooFrom(String uid) => meTooUserIds.contains(uid);

  // ---------- Firestore conversion ----------

  factory Incident.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime readDate(String field) =>
        (data[field] as Timestamp?)?.toDate() ?? DateTime.now();

    return Incident(
      id: doc.id,
      refCode: data['refCode'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'other',
      otherCategory: data['otherCategory'] as String?,
      location: data['location'] as String? ?? '',
      locationDetail: data['locationDetail'] as String?,
      urgency: data['urgency'] as String? ?? 'medium',
      photoUrl: data['photoUrl'] as String?,
      status: data['status'] as String? ?? 'submitted',
      reporterId: data['reporterId'] as String? ?? '',
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      reporterName: data['reporterName'] as String?,
      meTooUserIds: List<String>.from(data['meTooUserIds'] as List? ?? []),
      meTooCount: (data['meTooCount'] as num?)?.toInt() ?? 0,
      createdAt: readDate('createdAt'),
      updatedAt: readDate('updatedAt'),
    );
  }

  /// Fields for a brand-new report
  Map<String, dynamic> toNewMap() => {
    'refCode': refCode,
    'title': title,
    'description': description,
    'category': category,
    'otherCategory': otherCategory,
    'location': location,
    'locationDetail': locationDetail,
    'urgency': urgency,
    'photoUrl': photoUrl,
    'status': status,
    'reporterId': reporterId,
    'isAnonymous': isAnonymous,
    'reporterName': reporterName,
    'meTooUserIds': meTooUserIds,
    'meTooCount': meTooCount,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
