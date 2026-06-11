import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../models/report_model.dart';
import '../providers/admin_provider.dart';

class AdminReportDetailScreen extends StatefulWidget {
  final int reportId;

  const AdminReportDetailScreen({super.key, required this.reportId});

  @override
  State<AdminReportDetailScreen> createState() =>
      _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends State<AdminReportDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() {
    return context.read<AdminProvider>().fetchReport(widget.reportId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final report = provider.selectedReport;

    return Scaffold(
      appBar: AppBar(title: const Text('Report detail')),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: provider.isLoading && report == null
            ? const LoadingView(message: 'Loading report...')
            : provider.errorMessage != null && report == null
            ? ListView(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                children: [
                  const SizedBox(height: 96),
                  ErrorView(message: provider.errorMessage!, onRetry: _fetch),
                ],
              )
            : report == null
            ? const _MissingReportView()
            : ListView(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                children: [
                  _ReportSummary(report: report),
                  const SizedBox(height: AppSizes.paddingMedium),
                  _StatusActions(
                    currentStatus: report.status,
                    isLoading: provider.isLoading,
                    onSelected: (status) => _updateStatus(provider, status),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _updateStatus(AdminProvider provider, String status) async {
    final success = await provider.updateReportStatus(widget.reportId, status);
    if (!mounted) return;

    if (success) {
      SnackbarHelper.showSuccess(context, 'Report updated.');
    } else {
      SnackbarHelper.showError(
        context,
        provider.errorMessage ?? 'Unable to update report.',
      );
    }
  }
}

class _ReportSummary extends StatelessWidget {
  final ReportModel report;

  const _ReportSummary({required this.report});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(label: 'Type', value: report.type),
          _DetailRow(label: 'Reason', value: report.reason),
          _DetailRow(label: 'Status', value: report.status),
          _DetailRow(
            label: 'Reporter',
            value: report.reporter?.name ?? 'Unknown',
          ),
          _DetailRow(
            label: 'Created',
            value: report.createdAt == null
                ? 'Unknown'
                : DateFormatter.timeAgo(report.createdAt),
          ),
          _DetailRow(label: 'Target', value: report.preview),
          if (report.description?.trim().isNotEmpty == true)
            _DetailRow(label: 'Details', value: report.description!),
          if (report.actionTaken?.trim().isNotEmpty == true)
            _DetailRow(label: 'Action taken', value: report.actionTaken!),
          if (report.reviewer != null)
            _DetailRow(label: 'Reviewer', value: report.reviewer!.name),
        ],
      ),
    );
  }
}

class _StatusActions extends StatelessWidget {
  final String currentStatus;
  final bool isLoading;
  final ValueChanged<String> onSelected;

  const _StatusActions({
    required this.currentStatus,
    required this.isLoading,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const statuses = ['reviewed', 'dismissed', 'action_taken'];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Moderation status',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Wrap(
            spacing: AppSizes.paddingSmall,
            runSpacing: AppSizes.paddingSmall,
            children: statuses.map((status) {
              return ChoiceChip(
                label: Text(status),
                selected: currentStatus == status,
                onSelected: isLoading ? null : (_) => onSelected(status),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }
}

class _MissingReportView extends StatelessWidget {
  const _MissingReportView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      children: const [
        SizedBox(height: 96),
        ErrorView(message: 'This report could not be found.'),
      ],
    );
  }
}
