import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
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

  Future<void> _update(SettingsModel settings) async {
    final success = await context.read<SettingsProvider>().updateSettings(
      settings,
    );
    if (!mounted) {
      return;
    }

    if (success) {
      SnackbarHelper.showSuccess(context, 'Privacy settings updated.');
    } else {
      final error = context.read<SettingsProvider>().errorMessage;
      SnackbarHelper.showError(
        context,
        error ?? 'Unable to update privacy settings.',
      );
    }
  }

  Future<void> _updatePrivateAccount(bool value) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: value ? 'Make account private?' : 'Make account public?',
      message: value
          ? 'Only approved followers will be able to see your posts and stories.'
          : 'Anyone on SnapCircle will be able to see your posts and stories.',
      confirmLabel: value ? 'Make private' : 'Make public',
    );
    if (!confirmed || !mounted) {
      return;
    }

    final success = await context.read<SettingsProvider>().updatePrivateAccount(
      value,
    );
    if (!mounted) {
      return;
    }

    if (success) {
      SnackbarHelper.showSuccess(
        context,
        value ? 'Private account enabled.' : 'Your account is public.',
      );
    } else {
      SnackbarHelper.showError(
        context,
        context.read<SettingsProvider>().errorMessage ??
            'Unable to update account privacy.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final settings = provider.settings;
    final horizontalPadding = MediaQuery.sizeOf(context).width < 380
        ? AppSizes.paddingSmall
        : AppSizes.paddingMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: provider.isLoading && settings == null
          ? const LoadingView(message: 'Loading privacy settings...')
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
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        value: settings?.isPrivate ?? false,
                        onChanged: provider.isSaving
                            ? null
                            : _updatePrivateAccount,
                        title: const Text('Private account'),
                        subtitle: const Text(
                          'When your account is private, only approved followers can see your posts and stories.',
                        ),
                        secondary: const Icon(Icons.lock_outline),
                      ),
                      const Divider(),
                      SwitchListTile.adaptive(
                        value: settings?.allowMessages ?? true,
                        onChanged: provider.isSaving
                            ? null
                            : (value) => _update(
                                (settings ?? const SettingsModel()).copyWith(
                                  allowMessages: value,
                                ),
                              ),
                        title: const Text('Allow messages from users'),
                        subtitle: const Text(
                          'When off, your profile message button is disabled.',
                        ),
                        secondary: const Icon(Icons.chat_bubble_outline),
                      ),
                      const Divider(),
                      SwitchListTile.adaptive(
                        value: settings?.showEmail ?? false,
                        onChanged: provider.isSaving
                            ? null
                            : (value) => _update(
                                (settings ?? const SettingsModel()).copyWith(
                                  showEmail: value,
                                ),
                              ),
                        title: const Text('Show email on profile'),
                        subtitle: const Text(
                          'Your own profile can still show your email.',
                        ),
                        secondary: const Icon(Icons.alternate_email),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                Text(
                  'Private account visibility is enforced by the SnapCircle API for feed, profile posts, stories, and direct post access.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
    );
  }
}
