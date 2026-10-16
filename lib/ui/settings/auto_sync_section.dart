import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../sync/sync_controller.dart';
import '../../sync/sync_models.dart';
import '../sync_text.dart';
import '../theme.dart';
import 'auto_sync_controller.dart';
import 'health_connect_controller.dart';

/// Body of Settings → Automatická synchronizace (Phase 6).
class AutoSyncSection extends StatelessWidget {
  const AutoSyncSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = StatusColors.of(context);
    final c = context.watch<AutoSyncController>();
    final hc = context.watch<HealthConnectController>();
    final runs = context.watch<SyncController>().runs;
    final text = SyncText(l10n);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final lastBg = runs
        .where((r) => r.trigger == SyncTrigger.background)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.autoSyncSwitch),
          value: c.enabled,
          onChanged: c.setEnabled,
        ),
        Text(l10n.autoSyncDescription, style: muted),
        if (c.enabled) ...[
          const SizedBox(height: 10),
          Text(
            lastBg == null
                ? l10n.autoSyncNeverRan
                : l10n.autoSyncLastRun(
                    text.when(lastBg.finishedAt, now: DateTime.now()),
                    text.runStatus(lastBg.status),
                  ),
          ),
          if (hc.loaded && !hc.backgroundAuthorized) ...[
            const SizedBox(height: 8),
            Text(
              l10n.autoSyncNeedsHcBackground,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.warn),
            ),
          ],
          const SizedBox(height: 10),
          if (c.ignoringBattery)
            Text(l10n.autoSyncBatteryOk)
          else
            OutlinedButton.icon(
              icon: const Icon(Icons.battery_saver_outlined, size: 18),
              onPressed: c.requestBatteryExemption,
              label: Text(l10n.autoSyncBattery),
            ),
          const SizedBox(height: 8),
          Text(l10n.autoSyncUnusedHint, style: muted),
          TextButton.icon(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            icon: const Icon(Icons.open_in_new, size: 18),
            onPressed: c.openAppDetails,
            label: Text(l10n.autoSyncUnused),
          ),
        ],
      ],
    );
  }
}
