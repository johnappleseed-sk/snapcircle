import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController(text: '+16505553434');
  final _otpController = TextEditingController();
  bool _otpRequested = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && context.mounted) {
      context.go('/home');
    }
  }

  Future<void> _loginWithGoogle(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithGoogle();

    if (success && context.mounted) {
      context.go('/home');
    }
  }

  Future<void> _loginWithFacebook(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithFacebook();

    if (success && context.mounted) {
      context.go('/home');
    }
  }

  Future<void> _sendPhoneOtp(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendPhoneOtp(_phoneController.text);

    if (success && context.mounted) {
      setState(() => _otpRequested = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent. Enter the SMS code.')),
      );
    }
  }

  Future<void> _verifyPhoneOtp(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyPhoneOtp(_otpController.text);

    if (success && context.mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final horizontalPadding = MediaQuery.sizeOf(context).width < 380
        ? AppSizes.paddingMedium
        : AppSizes.paddingLarge;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSizes.paddingLarge,
            horizontalPadding,
            AppSizes.paddingLarge + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical -
                  AppSizes.paddingLarge * 2 -
                  MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSizes.paddingXL),
                const _AuthHeader(),
                if (authProvider.errorMessage != null) ...[
                  const SizedBox(height: AppSizes.paddingLarge),
                  _AuthErrorMessage(
                    message: authProvider.errorMessage!,
                    onDismissed: authProvider.clearError,
                  ),
                ],
                const SizedBox(height: AppSizes.paddingLarge),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Email',
                        hint: 'you@snapcircle.app',
                        controller: _emailController,
                        enabled: !authProvider.isLoading,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.alternate_email),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: AppSizes.paddingMedium),
                      AppTextField(
                        label: 'Password',
                        controller: _passwordController,
                        enabled: !authProvider.isLoading,
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_outline),
                        validator: _validatePassword,
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () => context.push('/forgot-password'),
                    child: const Text('Forgot password?'),
                  ),
                ),
                AppButton(
                  label: 'Log in',
                  icon: Icons.login,
                  isLoading: authProvider.isLoading,
                  onPressed: () => _loginWithEmail(context),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                AppButton(
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata,
                  isLoading: authProvider.isLoading,
                  onPressed: () => _loginWithGoogle(context),
                  variant: AppButtonVariant.secondary,
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                AppButton(
                  label: 'Continue with Facebook',
                  icon: Icons.facebook,
                  isLoading: authProvider.isLoading,
                  onPressed: () => _loginWithFacebook(context),
                  variant: AppButtonVariant.outline,
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                AppTextField(
                  label: 'Phone number',
                  hint: '+16505553434',
                  controller: _phoneController,
                  enabled: !authProvider.isLoading,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                AppButton(
                  label: _otpRequested ? 'Send OTP again' : 'Send phone OTP',
                  icon: Icons.sms_outlined,
                  isLoading: authProvider.isLoading,
                  onPressed: () => _sendPhoneOtp(context),
                  variant: AppButtonVariant.secondary,
                ),
                if (_otpRequested) ...[
                  const SizedBox(height: AppSizes.paddingMedium),
                  AppTextField(
                    label: 'OTP code',
                    hint: '123456',
                    controller: _otpController,
                    enabled: !authProvider.isLoading,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.pin_outlined),
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  AppButton(
                    label: 'Verify OTP',
                    icon: Icons.verified_user_outlined,
                    isLoading: authProvider.isLoading,
                    onPressed: () => _verifyPhoneOtp(context),
                  ),
                ],
                const SizedBox(height: AppSizes.paddingLarge),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New to SnapCircle?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () => context.push('/register'),
                      child: const Text('Create account'),
                    ),
                  ],
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
    if ((value ?? '').isEmpty) {
      return 'Password is required.';
    }
    return null;
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 68,
          width: 68,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.info, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.camera_alt, color: Colors.white, size: 31),
        ),
        const SizedBox(height: AppSizes.paddingLarge),
        Text(AppStrings.appName, style: AppTextStyles.headingLarge),
        const SizedBox(height: AppSizes.paddingSmall),
        Text(
          'Share moments. Build your circle.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _AuthErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback onDismissed;

  const _AuthErrorMessage({required this.message, required this.onDismissed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismissed,
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.error,
            tooltip: 'Dismiss error',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
