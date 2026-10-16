import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/log_buffer.dart';
import '../../core/sync_issue.dart';
import '../../l10n/l10n.dart';
import '../../sync/integration_status.dart';
import '../history/history_screen.dart';
import '../theme.dart';
import '../widgets/ds.dart';
import '../widgets/section_card.dart';
import '../widgets/status_pill.dart';
import 'auto_sync_controller.dart';
import 'auto_sync_section.dart';
import 'diagnostics_screen.dart';
import 'google_controller.dart';
import 'google_section.dart';
import 'health_connect_controller.dart';
import 'health_connect_section.dart';
import 'kt_controller.dart';
import 'kt_section.dart';
import 'sheet_controller.dart';
import 'sheet_section.dart';

/// Settings: one card per integration (status chip, label → value rows,
/// actions), automatic sync, history and diagnostics. Every section is
/// addressable through [initialSection]: the screen scrolls to it and
/// briefly highlights it, so error actions can deep-link straight to the
/// right place.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.initialSection});

  final SettingsSection? initialSection;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final Map<SettingsSection, GlobalKey> _keys = {
    for (final s in SettingsSection.values) s: GlobalKey(),
  };
  SettingsSection? _highlighted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshLocalStatus();
    final target = widget.initialSection;
    if (target != null) {
      _highlighted = target;
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(target));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Permission changes happen in other apps (Health Connect), so re-check
  // local status whenever the user comes back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshLocalStatus();
  }

  void _refreshLocalStatus() {
    context.read<HealthConnectController>().refresh();
    context.read<KtController>().load();
    context.read<GoogleController>().load();
    context.read<SheetController>().load();
    context.read<AutoSyncController>().load();
  }

  Future<void> _reveal(SettingsSection section) async {
    // Sections above may still grow while their status loads, so scroll
    // twice: right away and once the content has settled.
    for (final wait in const [Duration.zero, Duration(milliseconds: 400)]) {
      await Future<void>.delayed(wait);
      final ctx = _keys[section]?.currentContext;
      if (ctx == null || !ctx.mounted) return;
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        alignment: 0.1,
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _highlighted = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = Palette.of(context);
    final hc = context.watch<HealthConnectController>().status;
    final kt = context.watch<KtController>().status;
    final google = context.watch<GoogleController>().status;
    final sheet = context.watch<SheetController>().status;
    final logCount = context.watch<PersistentLogBuffer>().lines.length;

    Widget section(
      SettingsSection s,
      IconData icon,
      String title,
      Widget body, {
      IntegrationStatus? status,
      String? logo,
    }) => Padding(
      key: _keys[s],
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        icon: icon,
        logo: logo,
        title: title,
        highlighted: _highlighted == s,
        trailing: status == null ? null : StatusPill(status: status),
        children: [body],
      ),
    );

    Widget tile(
      IconData icon,
      String label,
      VoidCallback onTap, {
      String? trailing,
      bool last = false,
    }) => InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: p.line)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: p.accentText),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: p.muted,
                ),
              ),
            Icon(Icons.chevron_right_rounded, size: 20, color: p.muted),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      // Not lazy: deep links must reach sections below the fold.
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GroupLabel(l10n.settingsGroupSources),
            section(
              SettingsSection.healthConnect,
              Icons.favorite_rounded,
              l10n.settingsSectionHealthConnect,
              const HealthConnectSection(),
              status: hc,
              logo: BrandLogos.healthConnect,
            ),
            section(
              SettingsSection.kt,
              Icons.restaurant_rounded,
              l10n.settingsSectionKt,
              const KtSection(),
              status: kt,
              logo: BrandLogos.kt,
            ),
            GroupLabel(l10n.settingsGroupTarget),
            section(
              SettingsSection.google,
              Icons.account_circle_rounded,
              l10n.settingsSectionGoogle,
              const GoogleSection(),
              status: google,
              logo: BrandLogos.google,
            ),
            section(
              SettingsSection.sheet,
              Icons.table_chart_rounded,
              l10n.settingsSectionSheet,
              const SheetSection(),
              status: sheet,
              logo: BrandLogos.sheets,
            ),
            GroupLabel(l10n.settingsSectionAutoSync),
            Padding(
              key: _keys[SettingsSection.autoSync],
              padding: const EdgeInsets.only(bottom: 10),
              child: Panel(
                border: _highlighted == SettingsSection.autoSync
                    ? p.accent
                    : null,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                child: const AutoSyncSection(),
              ),
            ),
            GroupLabel(l10n.settingsGroupOther),
            Panel(
              key: _keys[SettingsSection.diagnostics],
              padding: EdgeInsets.zero,
              border: _highlighted == SettingsSection.diagnostics
                  ? p.accent
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      tile(
                        Icons.history_rounded,
                        l10n.historyTitle,
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const HistoryScreen(),
                          ),
                        ),
                      ),
                      tile(
                        Icons.bug_report_rounded,
                        l10n.settingsSectionDiagnostics,
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DiagnosticsScreen(),
                          ),
                        ),
                        trailing: l10n.diagnosticsCount(logCount),
                        last: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                l10n.settingsFooter(AppConfig.version),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: p.faint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
