import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/sync_issue.dart';
import '../../l10n/l10n.dart';
import '../../sources/health/hc_read_client.dart';
import '../widgets/ds.dart';
import '../widgets/issue_notice.dart';
import '../widgets/section_card.dart';
import 'health_connect_controller.dart';

/// Body of Settings → Health Connect (the status pill sits in the header).
class HealthConnectSection extends StatelessWidget {
  const HealthConnectSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.watch<HealthConnectController>();
    final issue = c.status.issue;

    VoidCallback? actionFor(IssueAction? action) => switch (action?.kind) {
      IssueActionKind.installHealthConnect => c.install,
      IssueActionKind.grantHcPermissions => c.grantPermissions,
      _ => null,
    };

    if (!c.loaded) return const LinearProgressIndicator();

    final available = c.availability == HcAvailability.available;
    String perm(bool supported, bool granted) => !supported
        ? l10n.valueUnsupported
        : granted
        ? l10n.valueAllowed
        : l10n.valueNotAllowed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KvRow(l10n.rowReads, l10n.hcReadsValue),
        if (available) ...[
          KvRow(l10n.rowHistory, perm(c.historyAvailable, c.historyAuthorized)),
          KvRow(
            l10n.rowBackground,
            perm(c.backgroundAvailable, c.backgroundAuthorized),
          ),
        ],
        if (issue != null) ...[
          const SizedBox(height: 10),
          IssueNotice(
            issue: issue,
            onAction: c.busy ? null : actionFor(issue.action),
          ),
        ],
        CardNote(l10n.settingsHcPriorityHint),
        CardActions([
          if (available && c.historyAvailable && !c.historyAuthorized)
            CardAction(
              label: l10n.hcGrantHistoryShort,
              icon: Icons.history_rounded,
              onPressed: c.busy ? null : c.grantHistory,
            ),
          if (available && c.backgroundAvailable && !c.backgroundAuthorized)
            CardAction(
              label: l10n.hcGrantBackgroundShort,
              icon: Icons.nightlight_round,
              onPressed: c.busy ? null : c.grantBackground,
            ),
          CardAction(
            label: l10n.settingsOpenHealthConnect,
            icon: Icons.open_in_new_rounded,
            onPressed: c.busy ? null : c.openSettings,
          ),
        ]),
      ],
    );
  }
}
