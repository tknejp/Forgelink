import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../background/background_sync.dart';
import '../../core/log_buffer.dart';
import '../../l10n/l10n.dart';
import '../theme.dart';
import '../widgets/ds.dart';

/// Persisted warnings, errors and run summaries (newest first), for
/// troubleshooting. Copy / clear, and in debug builds a one-off test of the
/// background worker.
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  bool _issuesOnly = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = Palette.of(context);
    final buffer = context.watch<PersistentLogBuffer>();
    final entries = [
      for (final line in buffer.lines.reversed) LogEntry.parse(line),
    ].where((e) => !_issuesOnly || e.isIssue).take(200).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsSectionDiagnostics),
        actions: [
          IconButton(
            tooltip: l10n.diagnosticsCopy,
            icon: const Icon(Icons.content_copy_rounded, size: 22),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(
                ClipboardData(text: buffer.lines.join('\n')),
              );
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.diagnosticsCopied)),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Wrap(
              spacing: 8,
              children: [
                FilterPill(
                  label: l10n.diagFilterAll,
                  selected: !_issuesOnly,
                  onTap: () => setState(() => _issuesOnly = false),
                ),
                FilterPill(
                  label: l10n.diagFilterIssues,
                  selected: _issuesOnly,
                  onTap: () => setState(() => _issuesOnly = true),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Panel(
                  padding: EdgeInsets.zero,
                  child: entries.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 36,
                            horizontal: 16,
                          ),
                          child: Text(
                            l10n.diagnosticsEmpty,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: p.muted),
                          ),
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < entries.length; i++)
                              _LogRow(
                                entries[i],
                                last: i == entries.length - 1,
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: p.line)),
              ),
              child: Row(
                children: [
                  if (kDebugMode) ...[
                    Expanded(
                      child: _BarButton(
                        icon: Icons.science_rounded,
                        label: l10n.diagBgTestShort,
                        color: p.accentText,
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await BackgroundSync.runOnceForTest();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(l10n.diagnosticsBgTestScheduled),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else
                    const Spacer(),
                  _BarButton(
                    icon: Icons.delete_rounded,
                    label: l10n.diagnosticsClear,
                    color: p.err,
                    onTap: buffer.clear,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One persisted log line, split into its parts. Format from `AppLogger`:
/// `[HH:MM:SS.mmm][LEVEL][DOMAIN][scope] message  | payload  | err: …`.
@immutable
class LogEntry {
  final String time;
  final String level;
  final String tag;
  final String message;
  final String detail;

  const LogEntry(this.time, this.level, this.tag, this.message, this.detail);

  static final _re = RegExp(
    r'^\[([^\]]+)\]\[(\w+)\s*\]((?:\[[^\]]+\])+) (.*)$',
  );

  static LogEntry parse(String line) {
    final m = _re.firstMatch(line);
    if (m == null) return LogEntry('', 'INFO', '', line, '');
    final tags = m
        .group(3)!
        .replaceAll('][', ' · ')
        .replaceAll('[', '')
        .replaceAll(']', '');
    final parts = m.group(4)!.split('  | ');
    return LogEntry(
      m.group(1)!,
      m.group(2)!,
      tags,
      parts.first,
      parts.skip(1).join(' · '),
    );
  }

  bool get isIssue => level == 'WARN' || level == 'ERROR';
}

class _LogRow extends StatelessWidget {
  const _LogRow(this.entry, {required this.last});

  final LogEntry entry;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final (fg, bg) = switch (entry.level) {
      'OK' => (p.ok, p.okBg),
      'WARN' => (p.warn, p.warnBg),
      'ERROR' => (p.err, p.errBg),
      _ => (p.muted, p.surface2),
    };
    const mono = TextStyle(fontFamily: AppTheme.monoFamily, fontSize: 11);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: p.line)),
      ),
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(entry.time, style: mono.copyWith(color: p.faint)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    entry.level,
                    style: mono.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.tag,
                    overflow: TextOverflow.ellipsis,
                    style: mono.copyWith(color: p.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              entry.message,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (entry.detail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                entry.detail,
                style: mono.copyWith(color: p.muted, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Material(
      color: p.surface2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            widthFactor: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
