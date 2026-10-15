import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/log_buffer.dart';
import '../../core/sync_issue.dart';
import '../../core/system_intents.dart';
import '../../l10n/l10n.dart';

/// Settings skeleton (Phase 1). Every section is addressable through
/// [initialSection]: the screen scrolls to it and briefly highlights it, so
/// error actions can deep-link straight to the right place.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.initialSection});

  final SettingsSection? initialSection;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<SettingsSection, GlobalKey> _keys = {
    for (final s in SettingsSection.values) s: GlobalKey(),
  };
  SettingsSection? _highlighted;

  @override
  void initState() {
    super.initState();
    final target = widget.initialSection;
    if (target != null) {
      _highlighted = target;
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(target));
    }
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
              [
                _StatusLine(text: l10n.statusNotConfigured),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l10n.settingsOpenHealthConnect),
                    onPressed: () => context
                        .read<SystemIntents>()
                        .openHealthConnectSettings(),
                  ),
                ),
              ],
            ),
            section(SettingsSection.kt, l10n.settingsSectionKt, [
              _StatusLine(text: l10n.statusNotConfigured),
            ]),
            section(SettingsSection.google, l10n.settingsSectionGoogle, [
              _StatusLine(text: l10n.statusNotConfigured),
            ]),
            section(SettingsSection.sheet, l10n.settingsSectionSheet, [
              _StatusLine(text: l10n.statusNotConfigured),
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

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle_outlined,
            size: 12, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 8),
        Text(text),
      ],
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
