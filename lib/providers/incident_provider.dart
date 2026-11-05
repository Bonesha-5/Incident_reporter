import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../services/incident_service.dart';
import '../services/storage_service.dart';

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

  List<Incident> get myIncidents => _user == null
      ? []
      : _allIncidents.where((i) => i.reporterId == _user!.uid).toList();

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
      onError: (_) {
        _isLoading = false;
        _loadError = "Couldn't load reports. Check your internet connection.";
        notifyListeners();
      },
    );
  }

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
        try {
          photoUrl = await _storageService.uploadIncidentPhoto(
            photo: photo,
            userId: reporter.uid,
          );
        } catch (e) {
          debugPrint('PHOTO UPLOAD ERROR: $e');
          _submitError = 'Photo upload failed. Try again, or remove the photo and submit without it.';
          return null;
        }
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
    } catch (_) {
      _submitError =
          "Couldn't submit your report. Check your internet and try again.";
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearSubmitError() => _submitError = null;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
