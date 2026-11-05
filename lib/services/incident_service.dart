import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/app_user.dart';
import '../models/incident.dart';
import '../models/incident_update.dart';

/// All Firestore work for incident reports.
class IncidentService {
  IncidentService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _db.collection(AppConstants.incidentsCollection);

  /// Live list of every report, newest first.
  Stream<List<Incident>> streamAllIncidents() => _incidents
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => Incident.fromDoc(doc)).toList(),
      );

  /// Live timeline of one report, oldest step first.
  Stream<List<IncidentUpdate>> streamUpdates(String incidentId) => _incidents
      .doc(incidentId)
      .collection(AppConstants.updatesCollection)
      .orderBy('createdAt')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => IncidentUpdate.fromDoc(doc)).toList(),
      );

  /// Saves a new report AND its first timeline entry together.
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

  /// Saves a student's edits to their own report.
  Future<void> updateIncident(String incidentId, Map<String, dynamic> fields) =>
      _incidents.doc(incidentId).update({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Deletes a report and its timeline.
  Future<void> deleteIncident(String incidentId) async {
    final ref = _incidents.doc(incidentId);
    final updates = await ref.collection(AppConstants.updatesCollection).get();
    final batch = _db.batch();
    for (final doc in updates.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(ref);
    await batch.commit();
  }

  /// Adds or removes a "Me too".
  /// A transaction reads the latest data first, so double taps
  /// can never count the same person twice.
  Future<void> setMeToo({
    required String incidentId,
    required String uid,
    required bool add,
  }) async {
    final ref = _incidents.doc(incidentId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final ids = List<String>.from(
        snapshot.data()?['meTooUserIds'] as List? ?? [],
      );
      final alreadyAdded = ids.contains(uid);
      if (add == alreadyAdded) return; // nothing to change

      transaction.update(ref, {
        'meTooUserIds': add
            ? FieldValue.arrayUnion([uid])
            : FieldValue.arrayRemove([uid]),
        'meTooCount': FieldValue.increment(add ? 1 : -1),
      });
    });
  }
}
