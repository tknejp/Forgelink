import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/local_date.dart';
import '../../core/sync_issue.dart';
import '../../l10n/l10n.dart';
import '../../sync/integration_status.dart';
import '../../sync/sync_controller.dart';
import '../../sync/sync_models.dart';
import '../history/history_screen.dart';
import '../issue_actions.dart';
import '../settings/google_controller.dart';
import '../settings/health_connect_controller.dart';
import '../settings/kt_controller.dart';
import '../settings/settings_screen.dart';
import '../settings/sheet_controller.dart';
import '../sync_text.dart';
import '../theme.dart';
import '../widgets/ds.dart';
import 'day_detail_sheet.dart';
import 'month_calendar.dart';
import 'range_screen.dart';
import 'sync_card.dart';
import 'sync_sheet.dart';

/// Home (docs/archive/implementation_plan.md §8): connection status,
/// calendar, range sync, history, Quick Sync — on one screen, no scrolling.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    context.read<HealthConnectController>().refresh();
    context.read<KtController>().load();
    context.read<GoogleController>().load();
    context.read<SheetController>().load();
    final sync = context.read<SyncController>();
    sync.reload();
    sync.refreshSheet();
  }

  Future<void> _openSettings([SettingsSection? section]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(initialSection: section),
      ),
    );
    _refresh();
  }

  void _openHistory() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const HistoryScreen()));

  /// Only problems get a toast (red, with the fix as its action); success
  /// shows in the calendar, the chips and a short "Hotovo" on the button.
  /// Failed days also turn red and their detail says why.
  void _toast(
    ScaffoldMessengerState messenger,
    RunResult result,
    VoidCallback retry,
  ) {
    if (result.status != RunStatus.partial &&
        result.status != RunStatus.failed) {
      return;
    }
    final text = SyncText(context.l10n);
    final p = Palette.of(context);
    final issue = [
      ...result.issues,
      for (final d in result.days) ...[
        ?d.issue,
        for (final f in d.fields.values) ?f.issue,
      ],
    ].firstOrNull;
    final action = issue?.action;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          backgroundColor: p.errBg,
          content: Row(
            children: [
              Icon(Icons.error_rounded, size: 20, color: p.err),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  issue == null
                      ? text.runSummary(result)
                      : text.presenter.message(issue),
                  style: TextStyle(color: p.text),
                ),
              ),
            ],
          ),
          action: action == null
              ? null
              : SnackBarAction(
                  label: text.presenter.actionLabel(action),
                  textColor: p.err,
                  onPressed: () {
                    if (!mounted) return;
                    runIssueAction(context, action, onRetry: retry);
                  },
                ),
        ),
      );
  }

  /// Calendar tap: syncs right away; problems come as a toast.
  Future<void> _sync(
    Future<RunResult?> Function(SyncController c) start,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await start(context.read<SyncController>());
    if (!mounted || result == null) return;
    _refresh();
    _toast(messenger, result, () => _sync(start));
  }

  /// Quick Sync and range sync: same as [_sync], with the progress sheet.
  /// The toast only comes when the sheet was swiped away before the end.
  Future<void> _syncWithSheet(
    String label,
    List<LocalDate> dates,
    Future<RunResult?> Function(SyncController c) start,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final c = context.read<SyncController>();
    final future = start(c);
    var sheetOpen = true;
    showSyncSheet(
      context,
      label: label,
      dates: dates,
      result: future,
      restart: () => start(c),
    ).whenComplete(() => sheetOpen = false);
    final result = await future;
    if (!mounted || result == null) return;
    _refresh();
    if (!sheetOpen) {
      _toast(messenger, result, () => _syncWithSheet(label, dates, start));
    }
  }

  void _quickSync() {
    final c = context.read<SyncController>();
    _syncWithSheet(
      context.l10n.triggerQuick,
      quickSyncDates(c.today),
      (c) => c.quickSync(),
    );
  }

  /// Range dragged on the calendar: confirm before syncing several days.
  Future<void> _confirmRange(LocalDate from, LocalDate to) async {
    final l10n = context.l10n;
    final text = SyncText(l10n);
    final count = from.daysUntil(to) + 1;
    if (count > AppConfig.maxRangeDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.rangeTooLong(AppConfig.maxRangeDays))),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.rangeConfirmTitle),
        content: Text(l10n.rangeConfirmBody(text.dates([from, to]), count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.ktCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.homeQuickSyncButton),
          ),
        ],
      ),
    );
    if (ok == true && mounted) _syncRange(from, to);
  }

  void _syncRange(LocalDate from, LocalDate to) => _syncWithSheet(
    context.l10n.triggerRange,
    [for (var i = 0; i <= from.daysUntil(to); i++) from.addDays(i)],
    (c) => c.syncRange(from, to),
  );

  Future<void> _pickRange() async {
    final picked = await RangeScreen.open(context);
    if (picked == null || !mounted) return;
    _syncRange(picked.$1, picked.$2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sync = context.watch<SyncController>();

    // Header, one status card, the calendar card taking the remaining
    // height (its rows stretch to fit 5 or 6 weeks), Quick Sync. Only a very
    // short window (landscape, split screen) falls back to scrolling.
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final fixed = box.maxHeight >= 640;
            final calendar = Panel(
              radius: 24,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: MonthCalendar(
                fill: fixed,
                onTapDay: (d) => _sync((c) => c.syncDate(d)),
                onLongPressDay: (d) => showDayDetail(
                  context,
                  d,
                  onSync: () => _sync((c) => c.syncDate(d)),
                ),
                onSelectRange: _confirmRange,
                actions: [
                  Tooltip(
                    message: l10n.homeRangeSync,
                    child: SoftChipButton(
                      label: l10n.calendarRangeButton,
                      icon: Icons.date_range_rounded,
                      onPressed: _pickRange,
                    ),
                  ),
                ],
              ),
            );
            final column = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 60,
                  child: Row(
                    children: [
                      Transform.translate(
                        offset: const Offset(-4, 0),
                        child: Image.asset(
                          'assets/branding/logo_fg_384.png',
                          width: 42,
                          height: 42,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          AppConfig.appName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      RoundIconButton(
                        icon: Icons.history_rounded,
                        tooltip: l10n.homeHistory,
                        onPressed: _openHistory,
                      ),
                      Transform.translate(
                        offset: const Offset(8, 0),
                        child: RoundIconButton(
                          icon: Icons.settings_rounded,
                          tooltip: l10n.settingsTitle,
                          onPressed: () => _openSettings(),
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusCard(
                  onFix: _openSettings,
                  onRetry: _quickSync,
                  issues: sync.openIssues,
                ),
                const SizedBox(height: 12),
                if (fixed) Expanded(child: calendar) else calendar,
                const SizedBox(height: 12),
                SyncCard(onQuickSync: _quickSync),
              ],
            );
            const padding = EdgeInsets.fromLTRB(16, 0, 16, 16);
            return fixed
                ? Padding(padding: padding, child: column)
                : SingleChildScrollView(padding: padding, child: column);
          },
        ),
      ),
    );
  }
}

/// One card in a fixed slot: "Vše připojeno" when everything is fine;
/// otherwise the most important problem — a persisted issue from an earlier
/// run (e.g. Google sign-in expired in the background; with its fix,
/// dismissable), or the integrations that still need setting up.
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.onFix,
    required this.onRetry,
    required this.issues,
  });

  final void Function(SettingsSection section) onFix;
  final VoidCallback onRetry;
  final List<SyncIssue> issues;

  static bool _ok(IntegrationStatus s) =>
      s.state == IntegrationState.configured ||
      s.state == IntegrationState.readVerified ||
      s.state == IntegrationState.verified;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = SyncText(l10n);

    final google = context.watch<GoogleController>().status;
    final sheet = context.watch<SheetController>().status;
    final items = <(String, IntegrationStatus, SettingsSection)>[
      (
        l10n.settingsSectionHealthConnect,
        context.watch<HealthConnectController>().status,
        SettingsSection.healthConnect,
      ),
      (
        l10n.settingsSectionKt,
        context.watch<KtController>().status,
        SettingsSection.kt,
      ),
      _ok(google)
          ? (l10n.homeIntegrationSheets, sheet, SettingsSection.sheet)
          : (l10n.homeIntegrationSheets, google, SettingsSection.google),
    ];
    final attention = items.where((i) => !_ok(i.$2)).toList();

    if (issues.isNotEmpty) {
      final issue = issues.first;
      final action = issue.action;
      return _StatusRow(
        tone: Tone.err,
        title: text.presenter.message(issue),
        sub: issues.length > 1 ? l10n.syncMoreDays(issues.length - 1) : null,
        actionLabel: action == null ? null : text.presenter.actionLabel(action),
        onAction: action == null
            ? null
            : () => runIssueAction(context, action, onRetry: onRetry),
        onDismiss: () => context.read<SyncController>().dismissIssue(issue),
      );
    }
    if (attention.isNotEmpty) {
      final anyError = attention.any(
        (i) => i.$2.state == IntegrationState.error,
      );
      return _StatusRow(
        tone: anyError ? Tone.err : Tone.warn,
        title: l10n.openIssuesTitle,
        sub: attention.map((i) => i.$1).join(' · '),
        actionLabel: l10n.homeFix,
        onAction: () => onFix(attention.first.$3),
      );
    }
    return _StatusRow(
      tone: Tone.ok,
      title: l10n.homeAllConnected,
      sub: items.map((i) => i.$1).join(' · '),
      onTap: () => onFix(SettingsSection.healthConnect),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.tone,
    required this.title,
    this.sub,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.onTap,
  });

  final Tone tone;
  final String title;
  final String? sub;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = Palette.of(context);
    final (fg, bg) = tone.colors(p);
    final isErr = tone == Tone.err;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap ?? onAction,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 12, onDismiss == null ? 14 : 4, 12),
          child: Row(
            children: [
              Icon(
                switch (tone) {
                  Tone.ok => Icons.check_circle_rounded,
                  Tone.err => Icons.error_rounded,
                  _ => Icons.warning_rounded,
                },
                color: fg,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                    if (sub != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sub!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: p.muted),
                      ),
                    ],
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                Material(
                  color: isErr ? p.err : p.accent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onAction,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          actionLabel!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isErr ? p.errInk : p.accentInk,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ] else if (onTap != null)
                Icon(Icons.chevron_right_rounded, size: 20, color: p.muted),
              if (onDismiss != null)
                IconButton(
                  tooltip: l10n.dismiss,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, size: 18, color: p.muted),
                  onPressed: onDismiss,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
