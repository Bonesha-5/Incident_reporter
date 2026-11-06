import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/status_colors.dart';
import '../models/app_notification.dart';
import '../providers/notification_provider.dart';
import '../screens/reports/incident_details_screen.dart';

/// Sits above every screen and slides a banner down from the top
/// when staff update a report while the student is using the app.
class NotificationBannerHost extends StatefulWidget {
  const NotificationBannerHost({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<NotificationBannerHost> createState() => _NotificationBannerHostState();
}

class _NotificationBannerHostState extends State<NotificationBannerHost> {
  NotificationProvider? _provider;
  AppNotification? _current;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<NotificationProvider>();
    if (provider != _provider) {
      _provider?.removeListener(_checkForBanner);
      _provider = provider..addListener(_checkForBanner);
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_checkForBanner);
    _timer?.cancel();
    super.dispose();
  }

  void _checkForBanner() {
    if (!mounted || _current != null) return;
    final next = _provider?.takeBanner();
    if (next == null) return;
    setState(() => _current = next);
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 5), _hide); // hides by itself
  }

  void _hide() {
    _timer?.cancel();
    if (!mounted) return;
    setState(() => _current = null);
    _checkForBanner(); // show the next one, if another arrived
  }

  void _open() {
    final notification = _current;
    if (notification == null) return;
    _hide();
    _provider?.markRead(notification);
    widget.navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) =>
            IncidentDetailsScreen(incidentId: notification.incidentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween(
                    begin: const Offset(0, -1.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: _current == null
                    ? const SizedBox.shrink()
                    : _BannerCard(
                        key: ValueKey(_current!.id),
                        notification: _current!,
                        onTap: _open,
                        onClose: _hide,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onClose,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (color, background) = StatusColors.of(
      notification.status,
      Theme.of(context).brightness,
    );

    return Semantics(
      liveRegion: true,
      child: Material(
        color: scheme.surface,
        elevation: 8,
        shadowColor: Colors.black54,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(notification.icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.headline,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${notification.incidentTitle}: “${notification.message}”',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to view',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                    semanticLabel: 'Dismiss',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
