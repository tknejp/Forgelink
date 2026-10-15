import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../sync/integration_status.dart';
import '../theme.dart';

/// Compact "● Ověřeno" chip for an integration state.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final IntegrationStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = StatusColors.of(context);
    final (Color color, String label) = switch (status.state) {
      IntegrationState.notConfigured => (
          status.issue == null ? colors.neutral : colors.warn,
          l10n.statusNotConfigured
        ),
      IntegrationState.configured => (colors.ok, l10n.statusConfigured),
      IntegrationState.readVerified => (colors.ok, l10n.statusReadVerified),
      IntegrationState.verified => (colors.ok, l10n.statusVerified),
      IntegrationState.error => (colors.error, l10n.statusError),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
