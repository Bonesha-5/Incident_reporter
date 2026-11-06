import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../models/incident_update.dart';
import '../services/incident_service.dart';
import '../services/storage_service.dart';

/// Keeps the live list of reports and every action on them.
/// Home, Reports, My reports, Details and Profile all read from here.
class IncidentProvider extends ChangeNotifier {
  IncidentProvider(this._incidentService, this._storageService);

  final IncidentService _incidentService;
  final StorageService _storageService;
  StreamSubscription<List<Incident>>? _subscription;

  AppUser? _user;
  List<Incident> _allIncidents = [];
  bool _isLoading = false;
  String? _loadError;
  bool _isSubmitting = false;
  String? _submitError;

  List<Incident> get allIncidents => _allIncidents;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;

  /// Reports this user created
  List<Incident> get myIncidents => _user == null
      ? []
      : _allIncidents.where((i) => i.reporterId == _user!.uid).toList();

  /// Reports this user tapped "Me too" on
  List<Incident> get myMeTooIncidents => _user == null
      ? []
      : _allIncidents.where((i) => i.hasMeTooFrom(_user!.uid)).toList();

  Incident? incidentById(String id) {
    for (final incident in _allIncidents) {
      if (incident.id == id) return incident;
    }
    return null;
  }

  Stream<List<IncidentUpdate>> updatesFor(String incidentId) =>
      _incidentService.streamUpdates(incidentId);

  /// Called automatically whenever the logged-in user changes.
  void setUser(AppUser? user) {
    if (user?.uid == _user?.uid) {
      _user = user;
      return;
    }
    _user = user;
    _subscription?.cancel();
    _subscription = null;
    _allIncidents = [];
    _loadError = null;

    if (user == null) {
      _isLoading = false;
      return;
    }

    _isLoading = true;
    _subscription = _incidentService.streamAllIncidents().listen(
      (incidents) {
        _allIncidents = incidents;
        _isLoading = false;
        _loadError = null;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('LOAD INCIDENTS ERROR: $e');
        _isLoading = false;
        _loadError = "Couldn't load reports. Check your internet connection.";
        notifyListeners();
      },
    );
  }

  // ---------- Create ----------

  Future<Incident?> submitIncident({
    required AppUser reporter,
    required String title,
    required String description,
    required String category,
    String? otherCategory,
    required String location,
    String? locationDetail,
    required String urgency,
    required bool isAnonymous,
    XFile? photo,
  }) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      String? photoUrl;
      if (photo != null) {
        photoUrl = await _uploadPhoto(photo, reporter.uid);
        if (photoUrl == null) return null;
      }

      return await _incidentService.createIncident(
        reporter: reporter,
        title: title,
        description: description,
        category: category,
        otherCategory: otherCategory,
        location: location,
        locationDetail: locationDetail,
        urgency: urgency,
        isAnonymous: isAnonymous,
        photoUrl: photoUrl,
      );
    } catch (e) {
      debugPrint('SUBMIT ERROR: $e');
      _submitError =
          "Couldn't submit your report. Check your internet and try again.";
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ---------- Edit ----------

  Future<bool> updateIncident({
    required Incident existing,
    required String title,
    required String description,
    required String category,
    String? otherCategory,
    required String location,
    String? locationDetail,
    required String urgency,
    required bool isAnonymous,
    XFile? newPhoto,
    required bool keepExistingPhoto,
  }) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      String? photoUrl = keepExistingPhoto ? existing.photoUrl : null;
      if (newPhoto != null) {
        photoUrl = await _uploadPhoto(newPhoto, existing.reporterId);
        if (photoUrl == null) return false;
      }

      await _incidentService.updateIncident(existing.id, {
        'title': title.trim(),
        'description': description.trim(),
        'category': category,
        'otherCategory': category == 'other' ? otherCategory?.trim() : null,
        'location': location.trim(),
        'locationDetail': locationDetail?.trim(),
        'urgency': urgency,
        'isAnonymous': isAnonymous,
        'reporterName': isAnonymous ? null : _user?.fullName,
        'photoUrl': photoUrl,
      });
      return true;
    } catch (e) {
      debugPrint('UPDATE ERROR: $e');
      _submitError =
          "Couldn't save your changes. Check your internet and try again.";
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ---------- Delete ----------

  /// Returns an error message, or null if it worked.
  Future<String?> deleteIncident(String incidentId) async {
    try {
      await _incidentService.deleteIncident(incidentId);
      return null;
    } catch (e) {
      debugPrint('DELETE ERROR: $e');
      return "Couldn't delete the report. Check your internet and try again.";
    }
  }

  // ---------- Me too ----------

  /// Returns an error message, or null if it worked.
  Future<String?> toggleMeToo(Incident incident) async {
    final user = _user;
    if (user == null) return 'Please log in again.';
    try {
      await _incidentService.setMeToo(
        incidentId: incident.id,
        uid: user.uid,
        add: !incident.hasMeTooFrom(user.uid),
      );
      return null;
    } catch (e) {
      debugPrint('ME TOO ERROR: $e');
      return "Couldn't update. Check your internet and try again.";
    }
  }

  // ---------- Staff ----------

  final Map<String, String?> _nameCache = {};

  /// Staff only: the real name behind an anonymous report.
  Future<String?> reporterNameFor(String uid) async {
    if (_nameCache.containsKey(uid)) return _nameCache[uid];
    try {
      final name = await _incidentService.fetchUserName(uid);
      _nameCache[uid] = name;
      return name;
    } catch (e) {
      debugPrint('FETCH NAME ERROR: $e');
      return null;
    }
  }

  /// Returns an error message, or null if it worked.
  Future<String?> updateStatus(
    Incident incident,
    String newStatus,
    String note,
  ) async {
    final staff = _user;
    if (staff == null || !staff.isStaff) {
      return 'Only staff can update the status.';
    }
    try {
      await _incidentService.updateStatus(
        incident: incident,
        newStatus: newStatus,
        note: note,
        staff: staff,
      );
      return null;
    } catch (e) {
      debugPrint('UPDATE STATUS ERROR: $e');
      return "Couldn't update the status. Check your internet and try again.";
    }
  }

  // ---------- Helpers ----------

  /// Uploads a photo; returns its link, or null (with an error) if it failed.
  Future<String?> _uploadPhoto(XFile photo, String userId) async {
    try {
      return await _storageService.uploadIncidentPhoto(
        photo: photo,
        userId: userId,
      );
    } catch (e) {
      debugPrint('PHOTO UPLOAD ERROR: $e');
      _submitError = 'Photo upload failed. Try again, or remove the photo and continue without it.';
      return null;
    }
  }

  void clearSubmitError() => _submitError = null;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
