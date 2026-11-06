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

  /// STAFF ONLY: changes the status, adds a timeline step, and creates
  /// a notification for the reporter and everyone who tapped Me too.
  /// A batch saves all of it together, or none of it.
  Future<void> updateStatus({
    required Incident incident,
    required String newStatus,
    required String note,
    required AppUser staff,
  }) async {
    final ref = _incidents.doc(incident.id);
    final batch = _db.batch();

    batch.update(ref, {
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(ref.collection(AppConstants.updatesCollection).doc(), {
      'status': newStatus,
      'note': note.trim(),
      'staffId': staff.uid,
      'staffName': staff.fullName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final recipients = {incident.reporterId, ...incident.meTooUserIds}
      ..remove(staff.uid);
    for (final userId in recipients) {
      batch.set(_db.collection(AppConstants.notificationsCollection).doc(), {
        'userId': userId,
        'incidentId': incident.id,
        'incidentTitle': incident.title,
        'status': newStatus,
        'message': note.trim(),
        'reason': userId == incident.reporterId ? 'reporter' : 'me_too',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// STAFF ONLY: looks up a user's name (for anonymous reports).
  Future<String?> fetchUserName(String uid) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    return doc.data()?['fullName'] as String?;
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
