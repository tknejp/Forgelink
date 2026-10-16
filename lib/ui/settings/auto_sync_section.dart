import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../sync/sync_controller.dart';
import '../../sync/sync_models.dart';
import '../sync_text.dart';
import '../theme.dart';
import '../widgets/ds.dart';
import '../widgets/section_card.dart';
import 'auto_sync_controller.dart';
import 'health_connect_controller.dart';

/// Body of Settings → Automatická synchronizace (Phase 6).
class AutoSyncSection extends StatelessWidget {
  const AutoSyncSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = Palette.of(context);
    final c = context.watch<AutoSyncController>();
    final hc = context.watch<HealthConnectController>();
    final runs = context.watch<SyncController>().runs;
    final text = SyncText(l10n);
    final now = DateTime.now();

    final lastBg = runs
        .where((r) => r.trigger == SyncTrigger.background)
        .firstOrNull;

    Widget row(String k, String v, {Color? color}) => Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 108,
            child: Text(k, style: TextStyle(fontSize: 13.5, color: p.muted)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: color ?? p.text,
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToggleRow(
          label: l10n.autoSyncSwitch,
          sub: l10n.autoSyncSub,
          value: c.enabled,
          onChanged: c.setEnabled,
        ),
        if (c.enabled) ...[
          ToggleRow(
            label: l10n.autoSyncNotifySuccess,
            sub: l10n.notifySuccessSub,
            value: c.notifySuccess,
            onChanged: c.setNotifySuccess,
          ),
          row(l10n.rowNextRun, switch (c.nextRun) {
            final next? => text.when(next, now: now),
            null => '—',
          }),
          row(
            l10n.rowLastRun,
            lastBg == null
                ? l10n.valueNever
                : '${text.when(lastBg.finishedAt, now: now)} · '
                      '${text.runStatus(lastBg.status)}',
          ),
          row(
            l10n.rowBattery,
            c.ignoringBattery ? l10n.batteryOk : l10n.batteryOn,
            color: c.ignoringBattery ? p.ok : p.warn,
          ),
          if (hc.loaded && !hc.backgroundAuthorized)
            CardNote(l10n.autoSyncNeedsHcBackground, color: p.warn),
          CardNote(l10n.autoSyncDelayHint),
          CardActions([
            if (!c.ignoringBattery)
              CardAction(
                label: l10n.batteryButton,
                icon: Icons.battery_saver_rounded,
                onPressed: c.requestBatteryExemption,
              ),
            CardAction(
              label: l10n.appSettingsButton,
              icon: Icons.open_in_new_rounded,
              onPressed: c.openAppDetails,
            ),
          ]),
        ] else
          CardNote(l10n.autoSyncDescription),
      ],
    );
  }
}
