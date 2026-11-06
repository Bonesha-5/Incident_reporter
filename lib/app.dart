import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'widgets/notification_banner_host.dart';

/// Lets the banner open screens from outside the normal navigation.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AluIncidentApp extends StatelessWidget {
  const AluIncidentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'ALU Incident Reporter',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      // The banner sits above every screen
      builder: (context, child) => NotificationBannerHost(
        navigatorKey: appNavigatorKey,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const AuthGate(),
    );
  }
}
