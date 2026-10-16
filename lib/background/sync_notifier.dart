import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:meta/meta.dart';

import '../core/app_log.dart';
import '../core/prefs_store.dart';
import '../core/sync_issue.dart';
import '../l10n/app_localizations.dart';
import '../sync/sync_models.dart';
import '../ui/sync_text.dart';

enum NoticeKind { success, partial, failed }

@immutable
class SyncNotice {
  final NoticeKind kind;
  final String title;
  final String body;
  const SyncNotice(this.kind, this.title, this.body);
}

/// Notification after every automatic run: success (optional, on by
/// default), partial or failed — the last two tell the user to sync
/// manually. Each new run replaces the previous notification.
class SyncNotifier {
  SyncNotifier(this._prefs, {FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final PrefsStore _prefs;
  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'sync_results';
  static const _notificationId = 2001;

  /// What to show for [r]; null when nothing should be shown. Pure.
  static SyncNotice? noticeFor(
    RunResult r,
    AppLocalizations l10n, {
    required bool notifySuccess,
  }) {
    // Connection problems are retried automatically; only the final
    // result is worth a notification.
    if (r.onlyTemporaryProblems) return null;
    final text = SyncText(l10n);
    final dates = text.dates([for (final d in r.days) d.date]);
    String firstProblem() {
      final issue =
          r.issues.firstOrNull ??
          r.days.map((d) => d.issue).whereType<SyncIssue>().firstOrNull ??
          r.days
              .expand((d) => d.fields.values)
              .map((f) => f.issue)
              .whereType<SyncIssue>()
              .firstOrNull;
      return issue == null ? text.runSummary(r) : text.presenter.message(issue);
    }

    switch (r.status) {
      case RunStatus.success:
      case RunStatus.noData:
        if (!notifySuccess) return null;
        final cells = r.cellsWritten;
        return SyncNotice(
          NoticeKind.success,
          l10n.bgSuccessTitle,
          cells > 0
              ? l10n.bgSuccessBody(dates, cells)
              : l10n.bgUpToDateBody(dates),
        );
      case RunStatus.partial:
        return SyncNotice(
          NoticeKind.partial,
          l10n.bgPartialTitle,
          '${firstProblem()}\n${l10n.bgManualHint}',
        );
      case RunStatus.failed:
        return SyncNotice(
          NoticeKind.failed,
          l10n.bgFailureTitle,
          '${firstProblem()}\n${l10n.bgManualHint}',
        );
    }
  }

  Future<void> notify(RunResult result) async {
    final l10n = lookupAppLocalizations(const Locale('cs'));
    final notice = noticeFor(
      result,
      l10n,
      notifySuccess: await _prefs.notifySuccess(),
    );
    if (notice != null) await _show(notice, l10n);
  }

  Future<void> notifyCrash() async {
    final l10n = lookupAppLocalizations(const Locale('cs'));
    await _show(
      SyncNotice(
        NoticeKind.failed,
        l10n.bgFailureTitle,
        '${l10n.issueUnexpected}\n${l10n.bgManualHint}',
      ),
      l10n,
    );
  }

  Future<void> _show(SyncNotice notice, AppLocalizations l10n) async {
    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      await _plugin.show(
        _notificationId,
        notice.title,
        notice.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            l10n.bgChannelName,
            importance: notice.kind == NoticeKind.success
                ? Importance.low
                : Importance.defaultImportance,
            styleInformation: BigTextStyleInformation(notice.body),
          ),
        ),
      );
      AppLog.sync.info('Background result notified', payload: notice.kind.name);
    } catch (e, st) {
      AppLog.sync.error('Posting notification failed', err: e, stackTrace: st);
    }
  }
}
