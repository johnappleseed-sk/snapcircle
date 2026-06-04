import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                height: 68,
                width: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share moments, follow friends, and keep your circle close.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (authProvider.errorMessage != null) ...[
                const SizedBox(height: 20),
                _AuthErrorMessage(
                  message: authProvider.errorMessage!,
                  onDismissed: authProvider.clearError,
                ),
              ],
              const SizedBox(height: 32),
              AppButton(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata,
                isLoading: authProvider.isLoading,
                onPressed: () => _loginWithGoogle(context),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Continue with Facebook',
                icon: Icons.facebook,
                isLoading: authProvider.isLoading,
                onPressed: () => _loginWithFacebook(context),
              ),
              const SizedBox(height: 18),
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
        color: AppColors.danger.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismissed,
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.danger,
            tooltip: 'Dismiss error',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
