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
import '../widgets/issue_notice.dart';
import '../widgets/section_card.dart';
import 'day_detail_sheet.dart';
import 'month_calendar.dart';
import 'sync_card.dart';

/// Home (docs/archive/implementation_plan.md §8): connections, open issues, Quick
/// Sync, calendar, range sync, history.
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
    context.read<SyncController>().reload();
  }

  Future<void> _openSettings([SettingsSection? section]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(initialSection: section),
      ),
    );
    _refresh();
  }

  /// Runs a sync and gives the plan §8 feedback: a snackbar for success /
  /// nothing-to-write; partial and failed results stay in the sync card.
  Future<void> _sync(
    Future<RunResult?> Function(SyncController c) start,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final text = SyncText(context.l10n);
    final result = await start(context.read<SyncController>());
    if (!mounted || result == null) return;
    _refresh();
    if (result.status == RunStatus.success ||
        result.status == RunStatus.noData) {
      messenger.showSnackBar(SnackBar(content: Text(text.runSummary(result))));
    }
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
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.homeQuickSyncButton),
          ),
        ],
      ),
    );
    if (ok == true && mounted) await _sync((c) => c.syncRange(from, to));
  }

  Future<void> _pickRange() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final today = context.read<SyncController>().today;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 2),
      lastDate: today.startOfDay,
      helpText: l10n.rangePickerHelp,
      locale: const Locale('cs'),
    );
    if (picked == null || !mounted) return;
    final from = LocalDate.fromDateTime(picked.start);
    final to = LocalDate.fromDateTime(picked.end);
    if (from.daysUntil(to) + 1 > AppConfig.maxRangeDays) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.rangeTooLong(AppConfig.maxRangeDays))),
      );
      return;
    }
    await _sync((c) => c.syncRange(from, to));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sync = context.watch<SyncController>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset('assets/branding/logo_256.png', width: 30, height: 30),
            const SizedBox(width: 10),
            const Text(AppConfig.appName),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettings(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        // Fills the screen so the sync card sits at the bottom (near the
        // thumb); scrolls only when extra cards (open issues) don't fit.
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ConnectionsCard(onFix: _openSettings),
                    if (sync.openIssues.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _OpenIssuesCard(
                        issues: sync.openIssues,
                        onRetry: () => _sync((c) => c.quickSync()),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: MonthCalendar(
                        onTapDay: (d) => _sync((c) => c.syncDate(d)),
                        onLongPressDay: (d) => showDayDetail(
                          context,
                          d,
                          onSync: () => _sync((c) => c.syncDate(d)),
                        ),
                        onSelectRange: _confirmRange,
                        actions: [
                          IconButton(
                            tooltip: l10n.homeRangeSync,
                            visualDensity: VisualDensity.compact,
                            onPressed: _pickRange,
                            icon: const Icon(Icons.date_range_outlined),
                          ),
                          IconButton(
                            tooltip: l10n.homeHistory,
                            visualDensity: VisualDensity.compact,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const HistoryScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.history),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 10),
                    SyncCard(onQuickSync: () => _sync((c) => c.quickSync())),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Persisted problems from earlier runs (incl. background) with their
/// actions; dismissable (plan §6 open issues).
class _OpenIssuesCard extends StatelessWidget {
  const _OpenIssuesCard({required this.issues, required this.onRetry});

  final List<SyncIssue> issues;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.read<SyncController>();
    return SectionCard(
      icon: Icons.warning_amber_rounded,
      title: l10n.openIssuesTitle,
      children: [
        for (final issue in issues)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: IssueNotice(
                    issue: issue,
                    onAction: issue.action == null
                        ? null
                        : () => runIssueAction(
                            context,
                            issue.action!,
                            onRetry: onRetry,
                          ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.dismiss,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => c.dismissIssue(issue),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One line when everything is fine ("Vše připojeno"), otherwise one row per
/// integration that needs attention, each with a direct link to its section.
class _ConnectionsCard extends StatelessWidget {
  const _ConnectionsCard({required this.onFix});

  final void Function(SettingsSection section) onFix;

  static bool _ok(IntegrationStatus s) =>
      s.state == IntegrationState.configured ||
      s.state == IntegrationState.readVerified ||
      s.state == IntegrationState.verified;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = StatusColors.of(context);

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

    if (attention.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.ok.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: colors.ok, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeAllConnected,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.ok,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    items.map((i) => i.$1).join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SectionCard(
      icon: Icons.link,
      title: l10n.homeIntegrationsTitle,
      children: [
        for (final (name, status, section) in attention)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  status.state == IntegrationState.error
                      ? Icons.error
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: status.state == IntegrationState.error
                      ? colors.error
                      : colors.warn,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(name)),
                TextButton(
                  onPressed: () => onFix(section),
                  child: Text(l10n.homeFix),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
