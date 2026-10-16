import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/sync_issue.dart';
import '../../l10n/l10n.dart';
import '../widgets/ds.dart';
import '../widgets/issue_notice.dart';
import '../widgets/section_card.dart';
import 'google_controller.dart';
import 'sheet_controller.dart';

class GoogleSection extends StatelessWidget {
  const GoogleSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.watch<GoogleController>();
    final needsReconnect =
        c.email == null || c.lastIssue is GoogleReauthRequired;

    Future<void> connect() async {
      await c.connect();
      if (context.mounted) await context.read<SheetController>().load();
    }

    Future<void> disconnect() async {
      await c.disconnect();
      if (context.mounted) await context.read<SheetController>().load();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KvRow(l10n.rowAccount, c.email ?? '—'),
        KvRow(l10n.rowAccess, l10n.googleAccessValue),
        if (c.email == null)
          if (c.status.issue case final issue?) ...[
            const SizedBox(height: 10),
            IssueNotice(issue: issue),
          ],
        if (AppConfig.googleWebClientId.isEmpty)
          CardNote(l10n.googleWebClientMissing),
        if (c.lastIssue != null) ...[
          const SizedBox(height: 10),
          IssueNotice(issue: c.lastIssue!, isError: true),
        ],
        CardActions([
          CardAction(
            label: c.email == null
                ? l10n.googleConnect
                : l10n.actionReconnectGoogle,
            icon: Icons.refresh_rounded,
            primary: needsReconnect,
            busy: c.busy,
            onPressed: connect,
          ),
          if (c.email != null)
            CardAction(
              label: l10n.googleDisconnect,
              icon: Icons.link_off_rounded,
              onPressed: c.busy ? null : disconnect,
            ),
        ]),
      ],
    );
  }
}
