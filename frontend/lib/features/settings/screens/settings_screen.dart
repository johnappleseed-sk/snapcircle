import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final userRole = context.watch<AuthProvider>().user?.role;
    final canAccessAdmin = userRole == 'admin' || userRole == 'moderator';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: RefreshIndicator(
        onRefresh: provider.fetchSettings,
        child: provider.isLoading && provider.settings == null
            ? const LoadingView(message: 'Loading settings...')
            : provider.errorMessage != null && provider.settings == null
            ? ListView(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                children: [
                  const SizedBox(height: 96),
                  ErrorView(
                    message: provider.errorMessage!,
                    onRetry: provider.fetchSettings,
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                children: [
                  _SectionLabel('Account'),
                  SettingsTile(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Account Settings',
                    subtitle: 'Status, logout, and account actions',
                    onTap: () => context.push('/settings/account'),
                  ),
                  if (canAccessAdmin) ...[
                    const SizedBox(height: AppSizes.paddingSmall),
                    SettingsTile(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Admin Panel',
                      subtitle: 'Reports, users, and moderation tools',
                      onTap: () => context.push('/admin'),
                    ),
                  ],
                  const SizedBox(height: AppSizes.paddingMedium),
                  _SectionLabel('Privacy'),
                  SettingsTile(
                    icon: Icons.lock_outline,
                    title: 'Privacy Settings',
                    subtitle: 'Messages and profile visibility',
                    onTap: () => context.push('/settings/privacy'),
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  _SectionLabel('Notifications'),
                  SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notification Settings',
                    subtitle: 'Push, email, and product updates',
                    onTap: () => context.push('/settings/notifications'),
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  _SectionLabel('About'),
                  const SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Terms & Privacy',
                    subtitle: 'Coming soon',
                    iconColor: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSizes.paddingSmall),
                  const SettingsTile(
                    icon: Icons.info_outline,
                    title: 'App Version',
                    subtitle: 'SnapCircle 1.0.0',
                    iconColor: AppColors.textSecondary,
                  ),
                ],
              ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSizes.paddingSmall),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
