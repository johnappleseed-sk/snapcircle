import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_card.dart';
import '../models/report_model.dart';

class AdminReportTile extends StatelessWidget {
  final ReportModel report;
  final ValueChanged<String> onStatusSelected;

  const AdminReportTile({
    super.key,
    required this.report,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${report.type.toUpperCase()} - ${report.reason}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
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
          Text(report.preview),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            'Status: ${report.status} - Reporter: ${report.reporter?.name ?? 'Unknown'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
