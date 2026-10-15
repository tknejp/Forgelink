import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../l10n/l10n.dart';
import '../issue_presenter.dart';
import 'google_controller.dart';
import 'sheet_controller.dart';
import 'status_line.dart';

class GoogleSection extends StatelessWidget {
  const GoogleSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.watch<GoogleController>();
    final presenter = IssuePresenter(l10n);

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
        StatusLine(status: c.status),
        if (c.email != null) ...[
          const SizedBox(height: 4),
          Text(l10n.googleConnectedAs(c.email!)),
        ],
        if (AppConfig.googleWebClientId.isEmpty) ...[
          const SizedBox(height: 4),
          Text(l10n.googleWebClientMissing,
              style: Theme.of(context).textTheme.bodySmall),
        ],
        if (c.lastIssue != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(presenter.message(c.lastIssue!),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        const SizedBox(height: 8),
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
