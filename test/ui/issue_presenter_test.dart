import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/core/local_date.dart';
import 'package:forgelink/core/sync_issue.dart';
import 'package:forgelink/l10n/app_localizations.dart';
import 'package:forgelink/ui/issue_presenter.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  late IssuePresenter presenter;
  final date = LocalDate(2026, 10, 12);

  setUpAll(() async {
    await initializeDateFormatting('cs');
    presenter = IssuePresenter(lookupAppLocalizations(const Locale('cs')));
  });

  // One instance of every SyncIssue subtype. The sealed switch in
  // IssuePresenter.message guarantees exhaustiveness at compile time; this
  // list guarantees each subtype is actually exercised.
  final allIssues = <SyncIssue>[
    const KtCredentialsMissing(),
    const KtAuthRejected(),
    const KtUnavailable(),
    const GoogleNotConnected(),
    const GoogleReauthRequired(),
    const SheetNotConfigured(),
    const SheetNotFound(),
    const SheetNoEditAccess('t***@gmail.com'),
    const SheetsApiDisabled(),
    const SheetTabMissing('tracker'),
    const SheetLayoutChanged('tracker'),
    DateNotInSheet(date),
    DateDuplicated(date, const [883, 893]),
    const CellHasFormula('B883'),
    const SheetsUnavailable(),
    const HcNotAvailable(),
    const HcPermissionMissing({HcDataType.steps, HcDataType.weight}),
    const HcHistoryPermissionMissing(),
    const HcBackgroundPermissionMissing(),
    HcReadFailed(date),
    NoData(DataSource.kt, date),
    const Offline(),
    const UnexpectedIssue(),
  ];

  test('every issue has a non-empty message with placeholders filled', () {
    for (final issue in allIssues) {
      final msg = presenter.message(issue);
      expect(msg.trim(), isNotEmpty, reason: issue.code);
      expect(msg, isNot(contains('{')), reason: issue.code);
    }
  });

  test('every action has a label', () {
    for (final issue in allIssues) {
      final action = issue.action;
      if (action != null) {
        expect(presenter.actionLabel(action), isNotEmpty, reason: issue.code);
      }
    }
  });

  test('codes are unique', () {
    final codes = allIssues.map((i) => i.code).toList();
    expect(codes.toSet(), hasLength(codes.length));
  });

  test('parameters appear in the message', () {
    expect(presenter.message(DateNotInSheet(date)), contains('12. 10. 2026'));
    expect(
      presenter.message(const SheetTabMissing('tracker')),
      contains('tracker'),
    );
    expect(
      presenter.message(
        const HcPermissionMissing({HcDataType.steps, HcDataType.weight}),
      ),
      contains('váha, kroky'),
    );
    expect(presenter.message(const CellHasFormula('B883')), contains('B883'));
  });

  test('actions route to the right place', () {
    expect(
      const KtCredentialsMissing().action,
      const IssueAction.openSettings(SettingsSection.kt),
    );
    expect(
      const SheetNotConfigured().action,
      const IssueAction.openSettings(SettingsSection.sheet),
    );
    expect(
      const HcPermissionMissing({HcDataType.weight}).action.kind,
      IssueActionKind.grantHcPermissions,
    );
    expect(
      const GoogleReauthRequired().action.kind,
      IssueActionKind.reconnectGoogle,
    );
    expect(const Offline().action.kind, IssueActionKind.retry);
  });

  test('transient issues', () {
    final transient = allIssues
        .where((i) => i.isTransient)
        .map((i) => i.code)
        .toSet();
    expect(transient, {
      'ktUnavailable',
      'sheetsUnavailable',
      'hcReadFailed',
      'offline',
    });
  });
}
