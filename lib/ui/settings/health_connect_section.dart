import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/sync_issue.dart';
import '../../l10n/l10n.dart';
import '../../sources/health/hc_read_client.dart';
import '../widgets/issue_notice.dart';
import 'health_connect_controller.dart';

/// Body of Settings → Health Connect (the status pill sits in the header).
class HealthConnectSection extends StatelessWidget {
  const HealthConnectSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final c = context.watch<HealthConnectController>();
    final status = c.status;
    final issue = status.issue;

    VoidCallback? actionFor(IssueAction? action) => switch (action?.kind) {
          IssueActionKind.installHealthConnect => c.install,
          IssueActionKind.grantHcPermissions => c.grantPermissions,
          _ => null,
        };

    if (!c.loaded) return const LinearProgressIndicator();

    final available = c.availability == HcAvailability.available;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (issue != null)
          IssueNotice(
            issue: issue,
            onAction: c.busy ? null : actionFor(issue.action),
          )
        else
          Text(l10n.settingsHcAllGranted),
        if (available) ...[
          const SizedBox(height: 12),
          if (!c.historyAvailable)
            Text(l10n.settingsHcHistoryUnavailable,
                style: theme.textTheme.bodySmall)
          else if (c.historyAuthorized)
            Text(l10n.settingsHcHistoryGranted)
          else
            OutlinedButton.icon(
              icon: const Icon(Icons.history, size: 18),
              onPressed: c.busy ? null : c.grantHistory,
              label: Text(l10n.settingsHcHistory),
            ),
        ],
        const SizedBox(height: 4),
        TextButton.icon(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: Text(l10n.settingsOpenHealthConnect),
          onPressed: c.busy ? null : c.openSettings,
        ),
        Text(
          l10n.settingsHcPriorityHint,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
