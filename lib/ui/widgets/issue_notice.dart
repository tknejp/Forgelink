import 'package:flutter/material.dart';

import '../../core/sync_issue.dart';
import '../../l10n/l10n.dart';
import '../issue_presenter.dart';
import '../theme.dart';

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

  /// Red (error) instead of orange (needs attention).
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final presenter = IssuePresenter(context.l10n);
    final colors = StatusColors.of(context);
    final color = isError ? colors.error : colors.warn;
    final action = issue.action;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(presenter.message(issue)),
                if (action != null && onAction != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(presenter.actionLabel(action)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
