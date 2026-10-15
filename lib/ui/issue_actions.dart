import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/sync_issue.dart';
import 'settings/google_controller.dart';
import 'settings/health_connect_controller.dart';
import 'settings/settings_screen.dart';

/// Performs an issue's recovery action (plan §6 navigation rules):
/// settings deep link, Health Connect grant/install, Google (re)connect, or
/// [onRetry].
Future<void> runIssueAction(
  BuildContext context,
  IssueAction action, {
  VoidCallback? onRetry,
}) async {
  final hc = context.read<HealthConnectController>();
  final google = context.read<GoogleController>();
  switch (action.kind) {
    case IssueActionKind.openSettings:
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(initialSection: action.section),
      ));
    case IssueActionKind.installHealthConnect:
      await hc.install();
    case IssueActionKind.grantHcPermissions:
      await hc.grantPermissions();
    case IssueActionKind.grantHcHistory:
      await hc.grantHistory();
    case IssueActionKind.grantHcBackground:
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) =>
            const SettingsScreen(initialSection: SettingsSection.healthConnect),
      ));
    case IssueActionKind.connectGoogle:
    case IssueActionKind.reconnectGoogle:
      await google.connect();
    case IssueActionKind.retry:
      onRetry?.call();
  }
}
