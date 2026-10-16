import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/app_log.dart';
import '../core/local_date.dart';
import '../core/prefs_store.dart';
import '../core/sync_issue.dart';
import '../l10n/app_localizations.dart';
import '../sync/sync_models.dart';
import '../ui/issue_presenter.dart';

/// Posts a notification when a background run hits a problem the user has
/// to fix (credentials, permissions, Google re-auth, sheet access…).
/// Successful runs never notify; the same problems notify at most once a day.
class FailureNotifier {
  FailureNotifier(this._prefs, {FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final PrefsStore _prefs;
  final FlutterLocalNotificationsPlugin _plugin;

  static const _kLastNotified = 'bg.last_notified';
  static const _channelId = 'sync_problems';
  static const _notificationId = 2001;

  /// Issues worth a notification: the user can act on them and they won't
  /// go away by themselves.
  static List<SyncIssue> actionable(RunResult r) => [
    for (final i in r.issues)
      if (!i.isTransient && i.action != null && i is! NoData) i,
  ];

  Future<void> notifyIfNeeded(RunResult result) async {
    final issues = actionable(result);
    if (issues.isEmpty) return;

    final key =
        '${LocalDate.today().isoKey}|${(issues.map((i) => i.code).toList()..sort()).join(',')}';
    if (await _prefs.rawString(_kLastNotified) == key) return;

    final l10n = lookupAppLocalizations(const Locale('cs'));
    final body = IssuePresenter(l10n).message(issues.first);
    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      await _plugin.show(
        _notificationId,
        l10n.bgFailureTitle,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            l10n.bgChannelName,
            importance: Importance.defaultImportance,
            styleInformation: BigTextStyleInformation(body),
          ),
        ),
      );
      await _prefs.setRawString(_kLastNotified, key);
      AppLog.sync.info(
        'Background failure notified',
        payload: issues.map((i) => i.code).join(','),
      );
    } catch (e, st) {
      AppLog.sync.error(
        'Posting failure notification failed',
        err: e,
        stackTrace: st,
      );
    }
  }
}
