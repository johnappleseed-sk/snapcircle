import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_report_tile.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() {
    return context.read<AdminProvider>().fetchReports(status: _status);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          itemCount: provider.reports.isEmpty ? 2 : provider.reports.length + 1,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSizes.paddingMedium),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _StatusFilter(
                value: _status,
                onChanged: (value) {
                  setState(() => _status = value);
                  _fetch();
                },
              );
            }

            if (provider.isLoading && provider.reports.isEmpty) {
              return const SizedBox(
                height: 280,
                child: LoadingView(message: 'Loading reports...'),
              );
            }

            if (provider.errorMessage != null && provider.reports.isEmpty) {
              return ErrorView(
                message: provider.errorMessage!,
                onRetry: _fetch,
              );
            }

            if (provider.reports.isEmpty) {
              return const EmptyView(
                icon: Icons.flag_outlined,
                title: 'No reports',
                subtitle: 'Reports matching this filter will appear here.',
              );
            }

            final report = provider.reports[index - 1];
            return AdminReportTile(
              report: report,
              onStatusSelected: (status) async {
                final success = await provider.updateReportStatus(
                  report.id,
                  status,
                );
                if (!context.mounted) return;
                if (success) {
                  SnackbarHelper.showSuccess(context, 'Report updated.');
                } else {
                  SnackbarHelper.showError(
                    context,
                    provider.errorMessage ?? 'Unable to update report.',
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StatusFilter({required this.value, required this.onChanged});

  static const statuses = [
    'all',
    'pending',
    'reviewed',
    'dismissed',
    'action_taken',
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Status'),
      items: statuses
          .map((status) => DropdownMenuItem(value: status, child: Text(status)))
          .toList(),
      onChanged: (value) => onChanged(value ?? 'pending'),
    );
  }
}
