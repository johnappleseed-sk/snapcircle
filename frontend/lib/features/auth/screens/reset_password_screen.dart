import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final message = await context.read<AuthProvider>().resetPassword(
      email: _emailController.text.trim(),
      token: _tokenController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted || message == null) {
      return;
    }

    setState(() => _successMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Set a new password',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Text(
                  'Paste the reset token from your email and choose a new password.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_successMessage != null) ...[
                  const SizedBox(height: AppSizes.paddingLarge),
                  Text(
                    _successMessage!,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  AppButton(
                    label: 'Back to login',
                    icon: Icons.login,
                    onPressed: () => context.go('/login'),
                  ),
                ],
                if (authProvider.errorMessage != null) ...[
                  const SizedBox(height: AppSizes.paddingLarge),
                  Text(
                    authProvider.errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.paddingLarge),
                AppTextField(
                  label: 'Email',
                  controller: _emailController,
                  enabled: !authProvider.isLoading,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.alternate_email),
                  validator: _validateEmail,
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                AppTextField(
                  label: 'Reset token',
                  controller: _tokenController,
                  enabled: !authProvider.isLoading,
                  prefixIcon: const Icon(Icons.key_outlined),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Reset token is required.'
                      : null,
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                AppTextField(
                  label: 'New password',
                  controller: _passwordController,
                  enabled: !authProvider.isLoading,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                  validator: _validatePassword,
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                AppButton(
                  label: 'Reset password',
                  icon: Icons.lock_reset,
                  isLoading: authProvider.isLoading,
                  onPressed: () => _resetPassword(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required.';
    }
    if (!email.contains('@')) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }
}
