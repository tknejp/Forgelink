import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/log_buffer.dart';
import '../../core/sync_issue.dart';
import '../../l10n/l10n.dart';
import '../../sync/integration_status.dart';
import '../widgets/section_card.dart';
import '../widgets/status_pill.dart';
import 'health_connect_controller.dart';
import 'health_connect_section.dart';
import 'kt_controller.dart';
import 'auto_sync_controller.dart';
import 'auto_sync_section.dart';
import 'google_controller.dart';
import 'google_section.dart';
import 'kt_section.dart';
import 'sheet_controller.dart';
import 'sheet_section.dart';

/// Settings skeleton (Phase 1). Every section is addressable through
/// [initialSection]: the screen scrolls to it and briefly highlights it, so
/// error actions can deep-link straight to the right place.
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
    final hc = context.watch<HealthConnectController>().status;
    final kt = context.watch<KtController>().status;
    final google = context.watch<GoogleController>().status;
    final sheet = context.watch<SheetController>().status;

    Widget section(
      SettingsSection s,
      IconData icon,
      String title,
      List<Widget> children, {
      IntegrationStatus? status,
    }) => Padding(
      key: _keys[s],
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        icon: icon,
        title: title,
        highlighted: _highlighted == s,
        trailing: status == null ? null : StatusPill(status: status),
        children: children,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          children: [
            section(
              SettingsSection.healthConnect,
              Icons.favorite_outline,
              l10n.settingsSectionHealthConnect,
              const [HealthConnectSection()],
              status: hc,
            ),
            section(
              SettingsSection.kt,
              Icons.restaurant_outlined,
              l10n.settingsSectionKt,
              const [KtSection()],
              status: kt,
            ),
            section(
              SettingsSection.google,
              Icons.account_circle_outlined,
              l10n.settingsSectionGoogle,
              const [GoogleSection()],
              status: google,
            ),
            section(
              SettingsSection.sheet,
              Icons.table_chart_outlined,
              l10n.settingsSectionSheet,
              const [SheetSection()],
              status: sheet,
            ),
            section(
              SettingsSection.autoSync,
              Icons.schedule,
              l10n.settingsSectionAutoSync,
              const [AutoSyncSection()],
            ),
            section(
              SettingsSection.diagnostics,
              Icons.bug_report_outlined,
              l10n.settingsSectionDiagnostics,
              const [_DiagnosticsLog()],
            ),
          ],
        ),
      ),
    );
  }
}

/// Collapsed by default: technical lines are only for troubleshooting.
class _DiagnosticsLog extends StatefulWidget {
  const _DiagnosticsLog();

  @override
  State<_DiagnosticsLog> createState() => _DiagnosticsLogState();
}

class _DiagnosticsLogState extends State<_DiagnosticsLog> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final buffer = context.watch<PersistentLogBuffer>();
    final lines = buffer.lines.reversed.take(100).toList();

    if (lines.isEmpty) {
      return Text(
        l10n.diagnosticsEmpty,
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_expanded)
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                lines.join('\n'),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded
                    ? l10n.diagnosticsHide
                    : l10n.diagnosticsShow(lines.length),
              ),
            ),
            if (_expanded) ...[
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(
                    ClipboardData(text: buffer.lines.join('\n')),
                  );
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.diagnosticsCopied)),
                  );
                },
                child: Text(l10n.diagnosticsCopy),
              ),
              TextButton(
                onPressed: buffer.clear,
                child: Text(l10n.diagnosticsClear),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
