import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../sync/integration_status.dart';
import 'ds.dart';

/// Compact "● Ověřeno" chip for an integration state.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final IntegrationStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (Tone tone, String label) = switch (status.state) {
      IntegrationState.notConfigured => (
        status.issue == null ? Tone.neutral : Tone.warn,
        l10n.statusNotConfigured,
      ),
      IntegrationState.configured => (Tone.ok, l10n.statusConfigured),
      IntegrationState.readVerified => (Tone.ok, l10n.statusReadVerified),
      IntegrationState.verified => (Tone.ok, l10n.statusVerified),
      IntegrationState.error => (Tone.err, l10n.statusError),
    };
    return TonePill(label, tone, dot: true);
  }
}
