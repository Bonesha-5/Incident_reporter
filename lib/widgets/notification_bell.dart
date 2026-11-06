import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/notification_provider.dart';
import '../screens/notifications/notifications_screen.dart';

/// The bell on Home, with a red badge showing unread alerts.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;

    return IconButton(
      tooltip: unread == 0 ? 'Notifications' : '$unread unread notifications',
      onPressed: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Badge(
        isLabelVisible: unread > 0,
        backgroundColor: AppColors.red,
        label: Text(unread > 9 ? '9+' : '$unread'),
        child: const Icon(
          Icons.notifications_none_rounded,
          color: Colors.white,
        ),
      ),
    );
  }
}
