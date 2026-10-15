import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../l10n/l10n.dart';
import 'google_controller.dart';
import 'sheet_controller.dart';
import '../widgets/issue_notice.dart';

class GoogleSection extends StatelessWidget {
  const GoogleSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.watch<GoogleController>();

    Future<void> connect() async {
      await c.connect();
      if (context.mounted) await context.read<SheetController>().load();
    }

    Future<void> disconnect() async {
      await c.disconnect();
      if (context.mounted) await context.read<SheetController>().load();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (c.email != null)
          Text(l10n.googleConnectedAs(c.email!))
        else if (c.status.issue case final issue?)
          IssueNotice(issue: issue),
        if (AppConfig.googleWebClientId.isEmpty) ...[
          const SizedBox(height: 4),
          Text(l10n.googleWebClientMissing,
              style: Theme.of(context).textTheme.bodySmall),
        ],
        if (c.lastIssue != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: IssueNotice(issue: c.lastIssue!, isError: true),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton(
              onPressed: c.busy ? null : connect,
              child: c.busy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(c.email == null
                      ? l10n.actionConnectGoogle
                      : l10n.actionReconnectGoogle),
            ),
            if (c.email != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: c.busy ? null : disconnect,
                child: Text(l10n.googleDisconnect),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
