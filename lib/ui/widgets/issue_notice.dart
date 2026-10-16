import 'package:flutter/material.dart';

import '../../core/sync_issue.dart';
import '../../l10n/l10n.dart';
import '../issue_presenter.dart';
import 'ds.dart';

/// A tinted box with the issue's message and (optionally) its action.
class IssueNotice extends StatelessWidget {
  const IssueNotice({
    super.key,
    required this.issue,
    this.onAction,
    this.isError = false,
  });

  final SyncIssue issue;

  /// Called for the issue's action button; null hides the button.
  final VoidCallback? onAction;

  /// Red (error) instead of amber (needs attention).
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final presenter = IssuePresenter(context.l10n);
    final action = issue.action;

    return Callout(
      text: presenter.message(issue),
      tone: isError ? Tone.err : Tone.warn,
      icon: isError ? Icons.error_rounded : Icons.info_rounded,
      action: action != null && onAction != null
          ? CardAction(
              label: presenter.actionLabel(action),
              icon: Icons.arrow_forward_rounded,
              onPressed: onAction,
            )
          : null,
    );
  }
}
