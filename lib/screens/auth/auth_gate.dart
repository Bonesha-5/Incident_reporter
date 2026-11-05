import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../home/home_placeholder_screen.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';

/// Watches the login state and shows the right screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    return switch (status) {
      AuthStatus.loading => const _SplashView(),
      AuthStatus.signedOut => const LoginScreen(),
      AuthStatus.unverified => const VerifyEmailScreen(),
      AuthStatus.signedIn => const HomePlaceholderScreen(),
    };
  }
}

/// Shown for a moment while the app checks the login state.
class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkHeader : AppColors.navy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                size: 36,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ALU Incident Reporter',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
