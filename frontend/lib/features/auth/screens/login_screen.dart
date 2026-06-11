import 'package:flutter/foundation.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _loginWithDemo(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithDemo();

    if (success && context.mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical -
                  AppSizes.paddingLarge * 2,
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
                if (kDebugMode ||
                    defaultTargetPlatform == TargetPlatform.android) ...[
                  const SizedBox(height: AppSizes.paddingMedium),
                  const _DemoCredentialsCard(),
                  const SizedBox(height: AppSizes.paddingMedium),
                  AppButton(
                    label: 'Use local demo account',
                    icon: Icons.bolt_outlined,
                    variant: AppButtonVariant.outline,
                    onPressed: authProvider.isLoading
                        ? null
                        : () => _loginWithDemo(context),
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

class _DemoCredentialsCard extends StatelessWidget {
  const _DemoCredentialsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Android demo account',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Email: maya@snapcircle.local',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            'Password: password',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
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
          height: 76,
          width: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(Icons.camera_alt, color: Colors.white, size: 34),
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
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
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
