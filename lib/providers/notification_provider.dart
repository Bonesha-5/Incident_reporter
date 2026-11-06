import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../services/notification_service.dart';

/// Listens to the user's notifications.
/// One listener feeds the bell badge, the list AND the pop-up banner.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._service);

  final NotificationService _service;
  StreamSubscription<List<AppNotification>>? _subscription;

  AppUser? _user;
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  bool _isFirstLoad = true;
  final Set<String> _seenIds = {};
  AppNotification? _pendingBanner;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void setUser(AppUser? user) {
    if (user?.uid == _user?.uid) {
      _user = user; // e.g. the alerts toggle changed
      return;
    }
    _user = user;
    _subscription?.cancel();
    _subscription = null;
    _notifications = [];
    _seenIds.clear();
    _isFirstLoad = true;
    _pendingBanner = null;

    // Staff never receive status alerts
    if (user == null || user.isStaff) {
      _isLoading = false;
      return;
    }

    _isLoading = true;
    _subscription = _service
        .streamForUser(user.uid)
        .listen(
          _handleData,
          onError: (e) {
            debugPrint('NOTIFICATIONS ERROR: $e');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void _handleData(List<AppNotification> items) {
    // only alerts that arrive while the student is using the app.
    if (!_isFirstLoad && (_user?.notifyStatusUpdates ?? false)) {
      final fresh = items
          .where((n) => !n.isRead && !_seenIds.contains(n.id))
          .toList();
      if (fresh.isNotEmpty) _pendingBanner = fresh.first;
    }
    _seenIds.addAll(items.map((n) => n.id));
    _isFirstLoad = false;
    _notifications = items;
    _isLoading = false;
    notifyListeners();
  }

  /// The banner takes the waiting alert (once).
  AppNotification? takeBanner() {
    final banner = _pendingBanner;
    _pendingBanner = null;
    return banner;
  }

  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead) return;
    try {
      await _service.markRead(notification.id);
    } catch (e) {
      debugPrint('MARK READ ERROR: $e');
    }
  }

  Future<void> markAllRead() async {
    final ids = _notifications
        .where((n) => !n.isRead)
        .map((n) => n.id)
        .toList();
    if (ids.isEmpty) return;
    try {
      await _service.markAllRead(ids);
    } catch (e) {
      debugPrint('MARK ALL READ ERROR: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
