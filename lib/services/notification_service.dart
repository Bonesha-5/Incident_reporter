import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/app_notification.dart';

/// Reads and updates the "notifications" collection.
class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection(AppConstants.notificationsCollection);

  /// Live list of one user's notifications, newest first.
  Stream<List<AppNotification>> streamForUser(String uid) => _notifications
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((snapshot) {
        final list =
            snapshot.docs.map((doc) => AppNotification.fromDoc(doc)).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  Future<void> markRead(String id) =>
      _notifications.doc(id).update({'isRead': true});

  Future<void> markAllRead(List<String> ids) async {
    final batch = _db.batch();
    for (final id in ids) {
      batch.update(_notifications.doc(id), {'isRead': true});
    }
    await batch.commit();
  }
}
