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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final settings = provider.settings;

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
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              children: [
                AppCard(
                  child: Column(
                    children: [
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                Text(
                  'Some privacy controls will be enforced more deeply in future updates.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
    );
  }
}
