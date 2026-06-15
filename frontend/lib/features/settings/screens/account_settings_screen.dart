import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SettingsProvider>();
      if (provider.settings == null) {
        provider.fetchSettings();
      }
    });
  }

  Future<void> _logout() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Log out?',
      message: 'Your local session will be cleared on this device.',
      confirmLabel: 'Log out',
      isDestructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

    await context.read<AuthProvider>().logout();
    if (mounted) {
      context.go('/login');
    }
  }

  Future<void> _deactivate() async {
    final confirmed = await _confirm(
      title: 'Deactivate account?',
      message:
          'Your account will be marked deactivated and your session will end. Your posts and data are not deleted.',
      action: 'Deactivate',
    );
    if (!confirmed || !mounted) {
      return;
    }

    final success = await context.read<SettingsProvider>().deactivateAccount();
    if (success && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        context.go('/login');
      }
    } else if (mounted) {
      SnackbarHelper.showError(
        context,
        context.read<SettingsProvider>().errorMessage ??
            'Unable to deactivate account.',
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _confirm(
      title: 'Request account deletion?',
      message:
          'For this MVP, deletion safely deactivates your account to avoid breaking posts, messages, and relationships.',
      action: 'Request deletion',
    );
    if (!confirmed || !mounted) {
      return;
    }

    final success = await context.read<SettingsProvider>().deleteAccount();
    if (success && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        context.go('/login');
      }
    } else if (mounted) {
      SnackbarHelper.showError(
        context,
        context.read<SettingsProvider>().errorMessage ??
            'Unable to update account.',
      );
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    return showConfirmationDialog(
      context: context,
      title: title,
      message: message,
      confirmLabel: action,
      isDestructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final settings = provider.settings;
    final horizontalPadding = MediaQuery.sizeOf(context).width < 380
        ? AppSizes.paddingSmall
        : AppSizes.paddingMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body: provider.isLoading && settings == null
          ? const LoadingView(message: 'Loading account settings...')
          : settings == null && provider.errorMessage != null
          ? ErrorView(
              message: provider.errorMessage!,
              onRetry: provider.fetchSettings,
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSizes.paddingMedium,
                horizontalPadding,
                AppSizes.paddingXL,
              ),
              children: [
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.10),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.18),
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSmall,
                          ),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account status',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 3),
                            Text(settings?.accountStatus ?? 'active'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                AppButton(
                  label: 'Logout',
                  icon: Icons.logout,
                  variant: AppButtonVariant.outline,
                  onPressed: _logout,
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                AppButton(
                  label: 'Deactivate Account',
                  icon: Icons.person_off_outlined,
                  variant: AppButtonVariant.danger,
                  isLoading: provider.isDeleting,
                  onPressed: provider.isDeleting ? null : _deactivate,
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                AppButton(
                  label: 'Request Account Deletion',
                  icon: Icons.delete_outline,
                  variant: AppButtonVariant.outline,
                  isLoading: provider.isDeleting,
                  onPressed: provider.isDeleting ? null : _deleteAccount,
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                Text(
                  'Full deletion workflow is planned for a later privacy release.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
    );
  }
}
