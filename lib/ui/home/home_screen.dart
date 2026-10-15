import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/sync_issue.dart';
import '../../l10n/l10n.dart';
import '../settings/settings_screen.dart';

/// Home screen skeleton (Phase 1). Sync actions, the calendar and the status
/// strip become live in Phase 4 (docs/implementation_plan.md §8).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openSettings(BuildContext context, [SettingsSection? section]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(initialSection: section),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: l10n.homeIntegrationsTitle,
            children: [
              Text(l10n.homeNotConfiguredYet),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _openSettings(context),
                  child: Text(l10n.homeOpenSettings),
                ),
              ),
            ],
          ),
          _SectionCard(
            title: l10n.homeLastSyncTitle,
            children: [Text(l10n.homeLastSyncNever)],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.sync),
            label: Text(l10n.homeQuickSyncButton),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: Text(
              l10n.homeQuickSyncSubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ),
          _SectionCard(
            title: l10n.homeCalendarTitle,
            children: [Text(l10n.homeComingSoon)],
          ),
          _SectionCard(
            title: l10n.homeAdvancedTitle,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: false,
                leading: const Icon(Icons.date_range_outlined),
                title: Text(l10n.homeRangeSync),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: false,
                leading: const Icon(Icons.history),
                title: Text(l10n.homeHistory),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
