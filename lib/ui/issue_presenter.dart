import 'package:intl/intl.dart';

import '../core/local_date.dart';
import '../core/sync_issue.dart';
import '../l10n/app_localizations.dart';

/// Turns a [SyncIssue] into user-facing Czech text and an action label.
/// Pure (no BuildContext), so it also works for Phase 6 notifications via
/// `lookupAppLocalizations(const Locale('cs'))`.
class IssuePresenter {
  const IssuePresenter(this.l10n);

  final AppLocalizations l10n;

  static final DateFormat _dateFormat = DateFormat('d. M. yyyy', 'cs');

  String formatDate(LocalDate date) => _dateFormat.format(date.startOfDay);

  String message(SyncIssue issue) => switch (issue) {
    KtCredentialsMissing() => l10n.issueKtCredentialsMissing,
    KtAuthRejected() => l10n.issueKtAuthRejected,
    KtUnavailable() => l10n.issueKtUnavailable,
    GoogleNotConnected() => l10n.issueGoogleNotConnected,
    GoogleReauthRequired() => l10n.issueGoogleReauthRequired,
    SheetNotConfigured() => l10n.issueSheetNotConfigured,
    SheetNotFound() => l10n.issueSheetNotFound,
    SheetNoEditAccess(:final email) => l10n.issueSheetNoEditAccess(email),
    SheetsApiDisabled() => l10n.issueSheetsApiDisabled,
    SheetTabMissing(:final tab) => l10n.issueSheetTabMissing(tab),
    SheetLayoutChanged(:final tab) => l10n.issueSheetLayoutChanged(tab),
    DateNotInSheet(:final date) => l10n.issueDateNotInSheet(formatDate(date)),
    DateDuplicated(:final date, :final rows) => l10n.issueDateDuplicated(
      formatDate(date),
      rows.join(', '),
    ),
    CellHasFormula(:final cell) => l10n.issueCellHasFormula(cell),
    SheetsUnavailable() => l10n.issueSheetsUnavailable,
    HcNotAvailable() => l10n.issueHcNotAvailable,
    HcPermissionMissing(:final types) => l10n.issueHcPermissionMissing(
      hcTypes(types),
    ),
    HcHistoryPermissionMissing() => l10n.issueHcHistoryPermissionMissing,
    HcBackgroundPermissionMissing() => l10n.issueHcBackgroundPermissionMissing,
    HcReadFailed(:final date) => l10n.issueHcReadFailed(formatDate(date)),
    NoData(:final source, :final date) => l10n.issueNoData(
      dataSource(source),
      formatDate(date),
    ),
    Offline() => l10n.issueOffline,
    UnexpectedIssue() => l10n.issueUnexpected,
  };

  String actionLabel(IssueAction action) => switch (action.kind) {
    IssueActionKind.openSettings => l10n.actionOpenSettings,
    IssueActionKind.installHealthConnect => l10n.actionInstallHealthConnect,
    IssueActionKind.grantHcPermissions ||
    IssueActionKind.grantHcHistory ||
    IssueActionKind.grantHcBackground => l10n.actionGrantPermissions,
    IssueActionKind.connectGoogle => l10n.actionConnectGoogle,
    IssueActionKind.reconnectGoogle => l10n.actionReconnectGoogle,
    IssueActionKind.retry => l10n.actionRetry,
  };

  String dataSource(DataSource source) => switch (source) {
    DataSource.healthConnect => l10n.dataSourceHealthConnect,
    DataSource.kt => l10n.dataSourceKt,
  };

  /// Comma-separated, in a stable order (weight before steps).
  String hcTypes(Set<HcDataType> types) => [
    if (types.contains(HcDataType.weight)) l10n.hcTypeWeight,
    if (types.contains(HcDataType.steps)) l10n.hcTypeSteps,
  ].join(', ');
}
