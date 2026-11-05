import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/validators.dart';
import '../providers/authentication_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/password_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authenticationProvider.notifier)
        .login(email: _email.text, password: _password.text);
    if (!mounted || !success) return;
    context.go(
      roleDashboardLocation(ref.read(authenticationProvider).user!.role),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authenticationProvider);
    final loading = auth.status == AuthenticationStatus.loading;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 30),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthHeader(
                        title: 'Welcome back',
                        subtitle: 'Sign in to connect with the people who grow your food.',
                      ),
                      const SizedBox(height: 30),
                      AuthTextField(
                        controller: _email,
                        label: 'Email address',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        validator: AppValidators.email,
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _password,
                        textInputAction: TextInputAction.done,
                        validator: (value) =>
                            AppValidators.required(value, 'Password'),
                      ),
                      if (auth.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        _AuthMessage(
                          message: auth.errorMessage!,
                          isError: true,
                        ),
                      ],
                      if (auth.successMessage != null) ...[
                        const SizedBox(height: 16),
                        _AuthMessage(
                          message: auth.successMessage!,
                          isError: false,
                        ),
                      ],
                      const SizedBox(height: 24),
                      AuthButton(
                        label: 'Sign in',
                        loading: loading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'New to FarmerLink? ',
                            style: TextStyle(
                              color: AppColors.darkGreen.withValues(alpha: .72),
                            ),
                          ),
                          TextButton(
                            onPressed: loading
                                ? null
                                : () => context.go('/register'),
                            child: const Text(
                              'Create account',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'GROWING STRONGER, TOGETHER',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.leafGreen,
                          letterSpacing: 1.7,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthMessage extends StatelessWidget {
  const _AuthMessage({required this.message, required this.isError});
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: isError ? const Color(0xFFFFEFEE) : const Color(0xFFEAF5E9),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      style: TextStyle(
        color: isError ? const Color(0xFF9B1C1C) : AppColors.primaryGreen,
        fontSize: 13,
        height: 1.4,
      ),
    ),
  );
}
