import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/primary_button.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    // On success, AuthGate switches screens automatically.
    await context.read<AuthProvider>().login(
      _emailController.text,
      _passwordController.text,
    );
  }

  void _openRegister() {
    context.read<AuthProvider>().clearError();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  void _openForgotPassword() {
    context.read<AuthProvider>().clearError();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ForgotPasswordScreen(initialEmail: _emailController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AuthHeader(
              icon: Icons.verified_user_outlined,
              title: 'Welcome back',
              subtitle: 'Log in with your ALU email to report and track campus issues.',
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        label: 'ALU email',
                        controller: _emailController,
                        hint: 'you@alustudent.com',
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: Validators.aluEmail,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Password',
                        controller: _passwordController,
                        hint: 'Enter your password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        autofillHints: const [AutofillHints.password],
                        validator: Validators.loginPassword,
                        suffix: IconButton(
                          tooltip: _hidePassword
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _openForgotPassword,
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (auth.errorMessage != null) ...[
                        InfoBanner(
                          message: auth.errorMessage!,
                          type: InfoBannerType.error,
                        ),
                        const SizedBox(height: 16),
                      ],
                      PrimaryButton(
                        label: 'Log in',
                        onPressed: _submit,
                        isLoading: auth.isBusy,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'New here?',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                          TextButton(
                            onPressed: _openRegister,
                            child: const Text('Create an account'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const InfoBanner(
                        icon: Icons.lock_outline_rounded,
                        message: 'Only @alustudent.com (students) and @alueducation.com (staff) emails can sign in.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
