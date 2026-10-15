import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../sync/integration_status.dart';
import '../issue_presenter.dart';

/// "nenastaveno / nastaveno / čtení ověřeno / ověřeno / chyba" plus the
/// issue message and its action button (plan §8).
class StatusLine extends StatelessWidget {
  const StatusLine({super.key, required this.status, this.onAction});

  final IntegrationStatus status;

  /// Called when the issue's action button is pressed. Null hides the button.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final presenter = IssuePresenter(l10n);

    final (IconData icon, Color color, String label) = switch (status.state) {
      IntegrationState.notConfigured => (
          Icons.circle_outlined,
          scheme.outline,
          l10n.statusNotConfigured
        ),
      IntegrationState.configured =>
        (Icons.check_circle_outline, scheme.primary, l10n.statusConfigured),
      IntegrationState.readVerified =>
        (Icons.check_circle_outline, scheme.primary, l10n.statusReadVerified),
      IntegrationState.verified =>
        (Icons.check_circle, scheme.primary, l10n.statusVerified),
      IntegrationState.error => (Icons.error, scheme.error, l10n.statusError),
    };

    final issue = status.issue;
    final action = issue?.action;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
        if (issue != null) ...[
          const SizedBox(height: 4),
          Text(presenter.message(issue)),
          if (action != null && onAction != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onAction,
                child: Text(presenter.actionLabel(action)),
              ),
            ),
        ],
      ],
    );
  }
}
