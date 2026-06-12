import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_stat_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final dashboard = provider.dashboard;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: RefreshIndicator(
        onRefresh: provider.fetchDashboard,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          children: [
            if (provider.isLoading && dashboard == null)
              const SizedBox(
                height: 320,
                child: LoadingView(message: 'Loading admin dashboard...'),
              )
            else if (provider.errorMessage != null && dashboard == null)
              ErrorView(
                message: provider.errorMessage!,
                onRetry: provider.fetchDashboard,
              )
            else if (dashboard != null) ...[
              AdminStatCard(
                label: 'Total users',
                value: dashboard.totalUsers,
                icon: Icons.people_outline,
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              AdminStatCard(
                label: 'Pending reports',
                value: dashboard.pendingReports,
                icon: Icons.flag_outlined,
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              AdminStatCard(
                label: 'Total posts',
                value: dashboard.totalPosts,
                icon: Icons.dynamic_feed_outlined,
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              AdminStatCard(
                label: 'Total comments',
                value: dashboard.totalComments,
                icon: Icons.chat_bubble_outline,
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              AdminStatCard(
                label: 'Banned users',
                value: dashboard.bannedUsers,
                icon: Icons.block,
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              AdminStatCard(
                label: 'Posts today',
                value: dashboard.newPostsToday,
                icon: Icons.dynamic_feed_outlined,
              ),
              const SizedBox(height: AppSizes.paddingLarge),
              AppButton(
                label: 'Manage Reports',
                icon: Icons.flag_outlined,
                onPressed: () => context.push('/admin/reports'),
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              AppButton(
                label: 'Manage Users',
                icon: Icons.admin_panel_settings_outlined,
                variant: AppButtonVariant.outline,
                onPressed: () => context.push('/admin/users'),
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              AppButton(
                label: 'Moderate Posts',
                icon: Icons.dynamic_feed_outlined,
                variant: AppButtonVariant.outline,
                onPressed: () => context.push('/admin/posts'),
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              AppButton(
                label: 'Moderate Comments',
                icon: Icons.chat_bubble_outline,
                variant: AppButtonVariant.outline,
                onPressed: () => context.push('/admin/comments'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
