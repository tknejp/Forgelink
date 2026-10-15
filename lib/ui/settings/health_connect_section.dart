import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/sync_issue.dart';
import '../../l10n/l10n.dart';
import '../../sources/health/hc_read_client.dart';
import 'health_connect_controller.dart';
import 'status_line.dart';

class HealthConnectSection extends StatelessWidget {
  const HealthConnectSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.watch<HealthConnectController>();
    final status = c.status;

    VoidCallback? actionFor(IssueAction? action) => switch (action?.kind) {
          IssueActionKind.installHealthConnect => c.install,
          IssueActionKind.grantHcPermissions => c.grantPermissions,
          _ => null,
        };

    final available = c.availability == HcAvailability.available;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!c.loaded)
          const LinearProgressIndicator()
        else
          StatusLine(
            status: status,
            onAction: c.busy ? null : actionFor(status.issue?.action),
          ),
        if (c.loaded && available && c.missing.isEmpty) ...[
          const SizedBox(height: 4),
          Text(l10n.settingsHcAllGranted),
        ],
        if (c.loaded && available) ...[
          const SizedBox(height: 8),
          if (!c.historyAvailable)
            Text(l10n.settingsHcHistoryUnavailable)
          else if (c.historyAuthorized)
            Text(l10n.settingsHcHistoryGranted)
          else
            OutlinedButton(
              onPressed: c.busy ? null : c.grantHistory,
              child: Text(l10n.settingsHcHistory),
            ),
        ],
        const SizedBox(height: 4),
        TextButton.icon(
          icon: const Icon(Icons.open_in_new),
          label: Text(l10n.settingsOpenHealthConnect),
          onPressed: c.busy ? null : c.openSettings,
        ),
        Text(l10n.settingsHcPriorityHint,
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
