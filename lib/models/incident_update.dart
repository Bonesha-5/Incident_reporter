import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentUpdate {
  final String id;
  final String status;
  final String note;
  final String? staffId;
  final String? staffName;
  final DateTime createdAt;

  const IncidentUpdate({
    required this.id,
    required this.status,
    required this.note,
    this.staffId,
    this.staffName,
    required this.createdAt,
  });

  factory IncidentUpdate.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return IncidentUpdate(
      id: doc.id,
      status: data['status'] as String? ?? 'submitted',
      note: data['note'] as String? ?? '',
      staffId: data['staffId'] as String?,
      staffName: data['staffName'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
