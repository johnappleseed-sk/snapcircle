import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final message = await context.read<AuthProvider>().forgotPassword(
      _emailController.text.trim(),
    );

    if (!mounted || message == null) {
      return;
    }

    setState(() => _successMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final horizontalPadding = MediaQuery.sizeOf(context).width < 380
        ? AppSizes.paddingMedium
        : AppSizes.paddingLarge;

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSizes.paddingLarge,
            horizontalPadding,
            AppSizes.paddingLarge + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Reset your password',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Text(
                  'Enter the email for your SnapCircle account.',
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
                const SizedBox(height: AppSizes.paddingLarge),
                AppButton(
                  label: 'Send reset link',
                  icon: Icons.mark_email_read_outlined,
                  isLoading: authProvider.isLoading,
                  onPressed: () => _sendResetLink(context),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                TextButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () => context.push('/reset-password'),
                  child: const Text('I have a reset token'),
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
}
