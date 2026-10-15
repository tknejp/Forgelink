import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/log_buffer.dart';
import '../../core/sync_issue.dart';
import '../../l10n/l10n.dart';
import 'health_connect_controller.dart';
import 'health_connect_section.dart';
import 'kt_controller.dart';
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
  }

  Future<void> _reveal(SettingsSection section) async {
    final ctx = _keys[section]?.currentContext;
    if (ctx != null) {
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

    Widget section(SettingsSection s, String title, List<Widget> children) =>
        _SettingsSectionCard(
          key: _keys[s],
          title: title,
          highlighted: _highlighted == s,
          children: children,
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            section(
              SettingsSection.healthConnect,
              l10n.settingsSectionHealthConnect,
              const [HealthConnectSection()],
            ),
            section(SettingsSection.kt, l10n.settingsSectionKt, const [
              KtSection(),
            ]),
            section(SettingsSection.google, l10n.settingsSectionGoogle, const [
              GoogleSection(),
            ]),
            section(SettingsSection.sheet, l10n.settingsSectionSheet, const [
              SheetSection(),
            ]),
            section(SettingsSection.autoSync, l10n.settingsSectionAutoSync, [
              Text(l10n.settingsAutoSyncLater),
            ]),
            section(
              SettingsSection.diagnostics,
              l10n.settingsSectionDiagnostics,
              const [_DiagnosticsLog()],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({
    super.key,
    required this.title,
    required this.highlighted,
    required this.children,
  });

  final String title;
  final bool highlighted;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: highlighted
            ? scheme.primaryContainer
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _DiagnosticsLog extends StatelessWidget {
  const _DiagnosticsLog();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final buffer = context.watch<PersistentLogBuffer>();
    final lines = buffer.lines.reversed.take(100).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lines.isEmpty)
          Text(l10n.diagnosticsEmpty)
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            width: double.infinity,
            child: SingleChildScrollView(
              child: SelectableText(
                lines.join('\n'),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ),
        Row(
          children: [
            TextButton(
              onPressed: lines.isEmpty
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await Clipboard.setData(
                          ClipboardData(text: buffer.lines.join('\n')));
                      messenger.showSnackBar(
                          SnackBar(content: Text(l10n.diagnosticsCopied)));
                    },
              child: Text(l10n.diagnosticsCopy),
            ),
            TextButton(
              onPressed: lines.isEmpty ? null : buffer.clear,
              child: Text(l10n.diagnosticsClear),
            ),
          ],
        ),
      ],
    );
  }
}
