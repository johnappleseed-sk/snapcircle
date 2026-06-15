import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_card.dart';
import '../models/report_model.dart';

class AdminReportTile extends StatelessWidget {
  final ReportModel report;
  final ValueChanged<String> onStatusSelected;
  final VoidCallback? onTap;

  const AdminReportTile({
    super.key,
    required this.report,
    required this.onStatusSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${report.type.toUpperCase()} - ${report.reason}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Moderation action',
                onSelected: onStatusSelected,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'reviewed', child: Text('Reviewed')),
                  PopupMenuItem(value: 'dismissed', child: Text('Dismissed')),
                  PopupMenuItem(
                    value: 'action_taken',
                    child: Text('Action taken'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(report.preview, maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSizes.paddingSmall),
          Wrap(
            spacing: AppSizes.paddingSmall,
            runSpacing: AppSizes.paddingXS,
            children: [
              _ReportMetaPill(label: report.status),
              _ReportMetaPill(
                label: 'Reporter: ${report.reporter?.name ?? 'Unknown'}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportMetaPill extends StatelessWidget {
  final String label;

  const _ReportMetaPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
