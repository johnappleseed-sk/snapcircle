import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../providers/report_provider.dart';

enum ReportTargetType { post, comment, user }

class ReportDialog extends StatefulWidget {
  final ReportTargetType targetType;
  final int targetId;

  const ReportDialog({
    super.key,
    required this.targetType,
    required this.targetId,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();

  static Future<void> show(
    BuildContext context, {
    required ReportTargetType targetType,
    required int targetId,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ReportDialog(targetType: targetType, targetId: targetId),
    );
  }
}

class _ReportDialogState extends State<ReportDialog> {
  final _descriptionController = TextEditingController();
  String _reason = _reasons.first.$1;

  static const _reasons = [
    ('spam', 'Spam'),
    ('harassment', 'Harassment'),
    ('inappropriate_content', 'Inappropriate content'),
    ('fake_account', 'Fake account'),
    ('violence', 'Violence'),
    ('other', 'Other'),
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final provider = context.read<ReportProvider>();
    final description = _descriptionController.text.trim();

    final success = switch (widget.targetType) {
      ReportTargetType.post => await provider.reportPost(
        widget.targetId,
        reason: _reason,
        description: description,
      ),
      ReportTargetType.comment => await provider.reportComment(
        widget.targetId,
        reason: _reason,
        description: description,
      ),
      ReportTargetType.user => await provider.reportUser(
        widget.targetId,
        reason: _reason,
        description: description,
      ),
    };

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop();
      SnackbarHelper.showSuccess(context, 'Report submitted for review.');
      return;
    }

    final message = provider.errorMessage ?? 'Unable to submit report.';
    SnackbarHelper.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<ReportProvider>().isSubmitting;

    return AlertDialog(
      title: const Text('Report content'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose the reason that best matches this report.'),
            const SizedBox(height: AppSizes.paddingMedium),
            DropdownButtonFormField<String>(
              value: _reason,
              decoration: const InputDecoration(labelText: 'Reason'),
              items: _reasons
                  .map(
                    (reason) => DropdownMenuItem(
                      value: reason.$1,
                      child: Text(reason.$2),
                    ),
                  )
                  .toList(),
              onChanged: isSubmitting
                  ? null
                  : (value) => setState(() => _reason = value ?? _reason),
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            TextField(
              controller: _descriptionController,
              enabled: !isSubmitting,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
                hintText: 'Add any helpful context for moderators.',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isSubmitting ? null : _submit,
          child: isSubmitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
