import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _hidePassword = true;
  int _strength = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthProvider>().register(
      fullName: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    // Go back to the first screen; AuthGate is now showing "Verify email".
    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;

    final visibilityButton = IconButton(
      tooltip: _hidePassword ? 'Show password' : 'Hide password',
      icon: Icon(
        _hidePassword
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
      ),
      onPressed: () => setState(() => _hidePassword = !_hidePassword),
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AuthHeader(
              showBack: true,
              title: 'Create your account',
              subtitle: 'Use your ALU email so we know you are part of campus.',
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
                        label: 'Full name',
                        controller: _nameController,
                        hint: 'e.g. Aline Uwase',
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        validator: Validators.fullName,
                      ),
                      const SizedBox(height: 16),
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
                        hint: 'At least 8 characters',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: Validators.newPassword,
                        suffix: visibilityButton,
                        onChanged: (value) => setState(
                          () => _strength = Validators.passwordStrength(value),
                        ),
                      ),
                      if (_strength > 0) ...[
                        const SizedBox(height: 10),
                        _PasswordStrength(score: _strength),
                      ],
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Confirm password',
                        controller: _confirmController,
                        hint: 'Type it again',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: Validators.confirmPassword(
                          () => _passwordController.text,
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
                      PrimaryButton(
                        label: 'Create account',
                        onPressed: _submit,
                        isLoading: auth.isBusy,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Log in'),
                          ),
                        ],
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

/// Four bars + a label showing how strong the password is.
class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.score});

  final int score; // 1 to 4

  static const _labels = [
    '',
    'Weak password',
    'Okay password. Add a number or symbol.',
    'Good password',
    'Strong password',
  ];
  static const _colors = [
    Colors.transparent,
    Color(0xFFDC2626),
    Color(0xFFD97706),
    Color(0xFF2563EB),
    Color(0xFF059669),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < score ? _colors[score] : scheme.outline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          _labels[score],
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
