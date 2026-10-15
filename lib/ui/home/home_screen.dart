import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/sync_issue.dart';
import '../../l10n/l10n.dart';
import '../../sync/integration_status.dart';
import '../settings/google_controller.dart';
import '../settings/health_connect_controller.dart';
import '../settings/kt_controller.dart';
import '../settings/settings_screen.dart';
import '../settings/sheet_controller.dart';
import '../theme.dart';
import '../widgets/section_card.dart';

/// Home (docs/implementation_plan.md §8). Sync actions and the calendar
/// become live in Phase 4; the connection status is live already.
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
  }

  Future<void> _openSettings([SettingsSection? section]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(initialSection: section),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = TextStyle(color: theme.colorScheme.onSurfaceVariant);

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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _ConnectionsCard(onFix: _openSettings),
          const SizedBox(height: 12),
          SectionCard(
            icon: Icons.sync,
            title: l10n.homeLastSyncTitle,
            children: [
              Text(l10n.homeLastSyncNever, style: muted),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: null, // Phase 4
                  icon: const Icon(Icons.sync),
                  label: Text(l10n.homeQuickSyncButton),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    textStyle: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(l10n.homeQuickSyncSubtitle,
                    style: theme.textTheme.bodySmall?.merge(muted)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SectionCard(
            icon: Icons.calendar_month_outlined,
            title: l10n.homeCalendarTitle,
            children: [Text(l10n.homeComingSoon, style: muted)],
          ),
          const SizedBox(height: 12),
          SectionCard(
            icon: Icons.tune,
            title: l10n.homeAdvancedTitle,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: false, // Phase 4
                leading: const Icon(Icons.date_range_outlined),
                title: Text(l10n.homeRangeSync),
                trailing: const Icon(Icons.chevron_right),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: false, // Phase 4
                leading: const Icon(Icons.history),
                title: Text(l10n.homeHistory),
                trailing: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
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
        SettingsSection.healthConnect
      ),
      (
        l10n.settingsSectionKt,
        context.watch<KtController>().status,
        SettingsSection.kt
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
                  Text(l10n.homeAllConnected,
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.ok, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    items.map((i) => i.$1).join(' · '),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
