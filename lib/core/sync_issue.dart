import 'package:meta/meta.dart';

import 'local_date.dart';

/// Settings sections addressable by deep links (`SettingsScreen(initialSection:)`).
enum SettingsSection { healthConnect, kt, google, sheet, autoSync, diagnostics }

/// Data sources that feed the sheet.
enum DataSource { healthConnect, kt }

/// Health Connect read types Forgelink needs.
enum HcDataType { steps, weight }

/// What the user can do about an issue. Labels live in the UI layer.
enum IssueActionKind {
  openSettings,
  installHealthConnect,
  grantHcPermissions,
  grantHcHistory,
  grantHcBackground,
  connectGoogle,
  reconnectGoogle,
  retry,
}

@immutable
class IssueAction {
  final IssueActionKind kind;

  /// Target for [IssueActionKind.openSettings].
  final SettingsSection? section;

  const IssueAction(this.kind, {this.section});

  const IssueAction.openSettings(SettingsSection this.section)
      : kind = IssueActionKind.openSettings;

  @override
  bool operator ==(Object other) =>
      other is IssueAction && other.kind == kind && other.section == section;

  @override
  int get hashCode => Object.hash(kind, section);

  @override
  String toString() =>
      section == null ? 'IssueAction($kind)' : 'IssueAction($kind, $section)';
}

/// Everything that can go wrong (or be worth reporting) during a sync.
///
/// Each subtype carries its parameters; the user-facing Czech text is produced
/// by `IssuePresenter` from ARB strings. Technical detail (HTTP status,
/// exception) goes to `AppLog` only — never into the message.
/// See docs/implementation_plan.md §6.
@immutable
sealed class SyncIssue {
  const SyncIssue();

  /// The recovery action offered next to the message, if any.
  IssueAction? get action;

  /// Transient issues are worth retrying automatically (drives Phase 6 retries).
  bool get isTransient => false;

  /// Stable code for persistence and logs.
  String get code;

  /// Rebuilds a persisted issue from its [code]. Only parameterless issues
  /// can be restored; anything else returns null.
  static SyncIssue? parameterlessFromCode(String code) => switch (code) {
        'ktCredentialsMissing' => const KtCredentialsMissing(),
        'ktAuthRejected' => const KtAuthRejected(),
        'ktUnavailable' => const KtUnavailable(),
        'googleNotConnected' => const GoogleNotConnected(),
        'googleReauthRequired' => const GoogleReauthRequired(),
        'sheetNotConfigured' => const SheetNotConfigured(),
        'sheetNotFound' => const SheetNotFound(),
        'sheetsApiDisabled' => const SheetsApiDisabled(),
        'sheetsUnavailable' => const SheetsUnavailable(),
        'hcNotAvailable' => const HcNotAvailable(),
        'hcHistoryPermissionMissing' => const HcHistoryPermissionMissing(),
        'hcBackgroundPermissionMissing' =>
          const HcBackgroundPermissionMissing(),
        'offline' => const Offline(),
        'unexpected' => const UnexpectedIssue(),
        _ => null,
      };
}

/// Carries a classified [SyncIssue] out of a source or the sheet layer.
class SyncIssueException implements Exception {
  final SyncIssue issue;
  final Object? cause;
  const SyncIssueException(this.issue, [this.cause]);

  @override
  String toString() =>
      'SyncIssueException(${issue.code}${cause == null ? '' : ', cause: $cause'})';
}

// ─── Kalorické tabulky ────────────────────────────────────────────────────────

final class KtCredentialsMissing extends SyncIssue {
  const KtCredentialsMissing();
  @override
  IssueAction get action => const IssueAction.openSettings(SettingsSection.kt);
  @override
  String get code => 'ktCredentialsMissing';
}

final class KtAuthRejected extends SyncIssue {
  const KtAuthRejected();
  @override
  IssueAction get action => const IssueAction.openSettings(SettingsSection.kt);
  @override
  String get code => 'ktAuthRejected';
}

final class KtUnavailable extends SyncIssue {
  const KtUnavailable();
  @override
  IssueAction get action => const IssueAction(IssueActionKind.retry);
  @override
  bool get isTransient => true;
  @override
  String get code => 'ktUnavailable';
}

// ─── Google ───────────────────────────────────────────────────────────────────

final class GoogleNotConnected extends SyncIssue {
  const GoogleNotConnected();
  @override
  IssueAction get action => const IssueAction(IssueActionKind.connectGoogle);
  @override
  String get code => 'googleNotConnected';
}

final class GoogleReauthRequired extends SyncIssue {
  const GoogleReauthRequired();
  @override
  IssueAction get action => const IssueAction(IssueActionKind.reconnectGoogle);
  @override
  String get code => 'googleReauthRequired';
}

// ─── Destination sheet ────────────────────────────────────────────────────────

final class SheetNotConfigured extends SyncIssue {
  const SheetNotConfigured();
  @override
  IssueAction get action =>
      const IssueAction.openSettings(SettingsSection.sheet);
  @override
  String get code => 'sheetNotConfigured';
}

final class SheetNotFound extends SyncIssue {
  const SheetNotFound();
  @override
  IssueAction get action =>
      const IssueAction.openSettings(SettingsSection.sheet);
  @override
  String get code => 'sheetNotFound';
}

final class SheetNoEditAccess extends SyncIssue {
  final String email;
  const SheetNoEditAccess(this.email);
  @override
  IssueAction get action =>
      const IssueAction.openSettings(SettingsSection.google);
  @override
  String get code => 'sheetNoEditAccess';
}

final class SheetsApiDisabled extends SyncIssue {
  const SheetsApiDisabled();
  @override
  IssueAction? get action => null;
  @override
  String get code => 'sheetsApiDisabled';
}

final class SheetTabMissing extends SyncIssue {
  final String tab;
  const SheetTabMissing(this.tab);
  @override
  IssueAction get action =>
      const IssueAction.openSettings(SettingsSection.sheet);
  @override
  String get code => 'sheetTabMissing';
}

final class SheetLayoutChanged extends SyncIssue {
  final String tab;
  const SheetLayoutChanged(this.tab);
  @override
  IssueAction? get action => null;
  @override
  String get code => 'sheetLayoutChanged';
}

final class DateNotInSheet extends SyncIssue {
  final LocalDate date;
  const DateNotInSheet(this.date);
  @override
  IssueAction? get action => null;
  @override
  String get code => 'dateNotInSheet';
}

final class DateDuplicated extends SyncIssue {
  final LocalDate date;

  /// 1-based sheet rows holding this date.
  final List<int> rows;
  const DateDuplicated(this.date, [this.rows = const []]);
  @override
  IssueAction? get action => null;
  @override
  String get code => 'dateDuplicated';
}

final class CellHasFormula extends SyncIssue {
  /// A1 reference, e.g. `B883`.
  final String cell;
  const CellHasFormula(this.cell);
  @override
  IssueAction? get action => null;
  @override
  String get code => 'cellHasFormula';
}

final class SheetsUnavailable extends SyncIssue {
  const SheetsUnavailable();
  @override
  IssueAction get action => const IssueAction(IssueActionKind.retry);
  @override
  bool get isTransient => true;
  @override
  String get code => 'sheetsUnavailable';
}

// ─── Health Connect ───────────────────────────────────────────────────────────

final class HcNotAvailable extends SyncIssue {
  const HcNotAvailable();
  @override
  IssueAction get action =>
      const IssueAction(IssueActionKind.installHealthConnect);
  @override
  String get code => 'hcNotAvailable';
}

final class HcPermissionMissing extends SyncIssue {
  final Set<HcDataType> types;
  const HcPermissionMissing(this.types);
  @override
  IssueAction get action =>
      const IssueAction(IssueActionKind.grantHcPermissions);
  @override
  String get code => 'hcPermissionMissing';
}

final class HcHistoryPermissionMissing extends SyncIssue {
  const HcHistoryPermissionMissing();
  @override
  IssueAction get action => const IssueAction(IssueActionKind.grantHcHistory);
  @override
  String get code => 'hcHistoryPermissionMissing';
}

final class HcBackgroundPermissionMissing extends SyncIssue {
  const HcBackgroundPermissionMissing();
  @override
  IssueAction get action =>
      const IssueAction(IssueActionKind.grantHcBackground);
  @override
  String get code => 'hcBackgroundPermissionMissing';
}

final class HcReadFailed extends SyncIssue {
  final LocalDate date;
  const HcReadFailed(this.date);
  @override
  IssueAction get action => const IssueAction(IssueActionKind.retry);
  @override
  bool get isTransient => true;
  @override
  String get code => 'hcReadFailed';
}

// ─── Generic ──────────────────────────────────────────────────────────────────

final class NoData extends SyncIssue {
  final DataSource source;
  final LocalDate date;
  const NoData(this.source, this.date);
  @override
  IssueAction? get action => null;
  @override
  String get code => 'noData';
}

final class Offline extends SyncIssue {
  const Offline();
  @override
  IssueAction get action => const IssueAction(IssueActionKind.retry);
  @override
  bool get isTransient => true;
  @override
  String get code => 'offline';
}

final class UnexpectedIssue extends SyncIssue {
  const UnexpectedIssue();
  @override
  IssueAction get action => const IssueAction(IssueActionKind.retry);
  @override
  String get code => 'unexpected';
}
