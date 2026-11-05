import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final sent = await context.read<AuthProvider>().sendPasswordReset(
      _emailController.text,
    );
    if (mounted) setState(() => _sent = sent);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AuthHeader(
              showBack: true,
              icon: Icons.key_rounded,
              title: 'Forgot your password?',
              subtitle: "Enter your ALU email and we'll send you a link to set a new one.",
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: 'ALU email',
                      controller: _emailController,
                      hint: 'you@alustudent.com',
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: Validators.aluEmail,
                      enabled: !_sent,
                    ),
                    const SizedBox(height: 24),
                    if (auth.errorMessage != null && !_sent) ...[
                      InfoBanner(
                        message: auth.errorMessage!,
                        type: InfoBannerType.error,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_sent) ...[
                      InfoBanner(
                        message:
                            'If an account exists for ${_emailController.text.trim()}, '
                            'a reset link is on its way. Check your inbox and spam folder.',
                        type: InfoBannerType.success,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Back to log in'),
                      ),
                    ] else
                      PrimaryButton(
                        label: 'Send reset link',
                        onPressed: _submit,
                        isLoading: auth.isBusy,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
