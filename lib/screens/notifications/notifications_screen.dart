import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/status_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';
import '../reports/report_actions.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  bool _isToday(DateTime time) {
    final now = DateTime.now();
    return time.year == now.year &&
        time.month == now.month &&
        time.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final scheme = Theme.of(context).colorScheme;
    final all = provider.notifications;
    final today = all.where((n) => _isToday(n.createdAt)).toList();
    final earlier = all.where((n) => !_isToday(n.createdAt)).toList();

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  context.read<NotificationProvider>().markAllRead(),
              child: const Text('Mark all read'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (all.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 48,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "When staff update your reports, or reports you tapped Me too on, you'll see it here.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (today.isNotEmpty) ...[
                heading('TODAY'),
                ...today.map((n) => _NotificationTile(notification: n)),
              ],
              if (earlier.isNotEmpty) ...[
                heading('EARLIER'),
                ...earlier.map((n) => _NotificationTile(notification: n)),
              ],
              const SizedBox(height: 12),
              Text(
                'You get updates on your own reports and on reports you tapped Me too on.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});
  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (color, background) = StatusColors.of(
      notification.status,
      Theme.of(context).brightness,
    );
    final unread = !notification.isRead;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: unread ? scheme.primaryContainer : scheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.read<NotificationProvider>().markRead(notification);
            openReportDetails(context, notification.incidentId);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: unread
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${notification.incidentTitle}: “${notification.message}”',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: unread
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${Formatters.timeAgo(notification.createdAt)} · ${notification.reasonLabel}',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread)
                  Semantics(
                    label: 'Unread',
                    child: Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 6, left: 6),
                      decoration: BoxDecoration(
                        color: scheme.onPrimaryContainer,
                        shape: BoxShape.circle,
                      ),
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
