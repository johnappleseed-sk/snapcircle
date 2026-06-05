import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 76,
                      width: 76,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusLarge,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),
                  Text(AppStrings.appName, style: AppTextStyles.headingLarge),
                  const SizedBox(height: AppSizes.paddingSmall),
                  Text(
                    'Share moments. Build your circle.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (authProvider.errorMessage != null) ...[
                    const SizedBox(height: AppSizes.paddingLarge),
                    _AuthErrorMessage(
                      message: authProvider.errorMessage!,
                      onDismissed: authProvider.clearError,
                    ),
                  ],
                  const SizedBox(height: AppSizes.paddingXL),
                  AppButton(
                    label: 'Continue with Google',
                    icon: Icons.g_mobiledata,
                    isLoading: authProvider.isLoading,
                    onPressed: () => _loginWithGoogle(context),
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  AppButton(
                    label: 'Continue with Facebook',
                    icon: Icons.facebook,
                    isLoading: authProvider.isLoading,
                    onPressed: () => _loginWithFacebook(context),
                    variant: AppButtonVariant.secondary,
                  ),
                  if (kDebugMode) ...[
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
                  Text(
                    'Login securely with your social account to continue.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
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
