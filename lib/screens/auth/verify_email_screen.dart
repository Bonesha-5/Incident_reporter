import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/primary_button.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  int _secondsLeft = 0;
  bool _justResent = false;

  @override
  void initState() {
    super.initState();
    _startCooldown(); // an email was just sent, so wait before resending
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _resend() async {
    final sent = await context.read<AuthProvider>().resendVerificationEmail();
    if (!mounted) return;
    setState(() => _justResent = sent);
    if (sent) _startCooldown();
  }

  Future<void> _checkVerified() async {
    setState(() => _justResent = false);
    // If verified, AuthGate moves to the home screen automatically.
    await context.read<AuthProvider>().checkEmailVerified();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final email = auth.pendingEmail ?? 'your email';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_unread_outlined,
                  size: 44,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Check your inbox',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'We sent a verification link to '),
                  TextSpan(
                    text: email,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const TextSpan(text: '. Open it, then come back here.'),
                ],
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.5,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            if (auth.errorMessage != null) ...[
              InfoBanner(
                message: auth.errorMessage!,
                type: InfoBannerType.error,
              ),
              const SizedBox(height: 16),
            ],
            if (_justResent && auth.errorMessage == null) ...[
              const InfoBanner(
                message: 'A new link is on its way. Check your inbox.',
                type: InfoBannerType.success,
              ),
              const SizedBox(height: 16),
            ],
            PrimaryButton(
              label: "I've verified my email",
              onPressed: _checkVerified,
              isLoading: auth.isBusy,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: (_secondsLeft > 0 || auth.isBusy) ? null : _resend,
              child: Text(
                _secondsLeft > 0
                    ? 'Resend email in ${_secondsLeft}s'
                    : 'Resend email',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Can't find it? Check your spam or junk folder.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => context.read<AuthProvider>().logout(),
              child: const Text('Wrong email? Go back'),
            ),
          ],
        ),
      ),
    );
  }
}
