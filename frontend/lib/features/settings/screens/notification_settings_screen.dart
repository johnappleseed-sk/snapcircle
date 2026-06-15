import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
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
      SnackbarHelper.showSuccess(context, 'Notification settings updated.');
    } else {
      final error = context.read<SettingsProvider>().errorMessage;
      SnackbarHelper.showError(
        context,
        error ?? 'Unable to update notification settings.',
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
      appBar: AppBar(title: const Text('Notification Settings')),
      body: provider.isLoading && settings == null
          ? const LoadingView(message: 'Loading notification settings...')
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
                        value: settings?.pushNotificationsEnabled ?? true,
                        onChanged: provider.isSaving
                            ? null
                            : (value) => _update(
                                (settings ?? const SettingsModel()).copyWith(
                                  pushNotificationsEnabled: value,
                                ),
                              ),
                        title: const Text('Push notifications'),
                        subtitle: const Text(
                          'Likes, comments, follows, requests, approvals, and messages.',
                        ),
                        secondary: const Icon(Icons.notifications_outlined),
                      ),
                      const Divider(),
                      SwitchListTile.adaptive(
                        value: settings?.emailNotificationsEnabled ?? false,
                        onChanged: provider.isSaving
                            ? null
                            : (value) => _update(
                                (settings ?? const SettingsModel()).copyWith(
                                  emailNotificationsEnabled: value,
                                ),
                              ),
                        title: const Text('Email notifications'),
                        subtitle: const Text(
                          'Receive important account and activity emails.',
                        ),
                        secondary: const Icon(Icons.mark_email_unread_outlined),
                      ),
                      const Divider(),
                      SwitchListTile.adaptive(
                        value: settings?.marketingEmailsEnabled ?? false,
                        onChanged: provider.isSaving
                            ? null
                            : (value) => _update(
                                (settings ?? const SettingsModel()).copyWith(
                                  marketingEmailsEnabled: value,
                                ),
                              ),
                        title: const Text('Product/news emails'),
                        subtitle: const Text(
                          'Get occasional SnapCircle product updates.',
                        ),
                        secondary: const Icon(Icons.campaign_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                Text(
                  'Push delivery requires Android Firebase setup on this device.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
    );
  }
}
