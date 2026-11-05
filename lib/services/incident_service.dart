import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/app_user.dart';
import '../models/incident.dart';

class IncidentService {
  IncidentService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _db.collection(AppConstants.incidentsCollection);

  Stream<List<Incident>> streamAllIncidents() => _incidents
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => Incident.fromDoc(doc)).toList(),
      );

  Future<Incident> createIncident({
    required AppUser reporter,
    required String title,
    required String description,
    required String category,
    String? otherCategory,
    required String location,
    String? locationDetail,
    required String urgency,
    required bool isAnonymous,
    String? photoUrl,
  }) async {
    final ref = _incidents.doc();
    final now = DateTime.now();

    final incident = Incident(
      id: ref.id,
      refCode: 'ALU-${ref.id.substring(0, 6).toUpperCase()}',
      title: title.trim(),
      description: description.trim(),
      category: category,
      otherCategory: otherCategory?.trim(),
      location: location.trim(),
      locationDetail: locationDetail?.trim(),
      urgency: urgency,
      photoUrl: photoUrl,
      status: 'submitted',
      reporterId: reporter.uid,
      isAnonymous: isAnonymous,
      reporterName: isAnonymous ? null : reporter.fullName,
      createdAt: now,
      updatedAt: now,
    );

    final batch = _db.batch();
    batch.set(ref, incident.toNewMap());
    batch.set(ref.collection(AppConstants.updatesCollection).doc(), {
      'status': 'submitted',
      'note': 'Report received.',
      'staffId': null,
      'staffName': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    return incident;
  }
}
