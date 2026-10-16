import '../../core/app_log.dart';
import '../../core/local_date.dart';
import '../../core/sync_issue.dart';
import 'kt_client.dart';

/// Kalorické tabulky as a sync source: session handling, one silent
/// refresh per run, and error classification into [SyncIssue]s.
///
/// Credentials are never wiped here (plan §3): a rejected login only becomes
/// [KtAuthRejected] so the user can update them.
class KtSource {
  KtSource(this._client);

  final KtClient _client;
  bool _refreshUsed = false;

  /// Call once at the start of every sync run.
  void beginRun() => _refreshUsed = false;

  Future<bool> hasCredentials() => _client.hasStoredCredentials();

  /// Fetches one day. Throws [SyncIssueException] with:
  /// - [KtCredentialsMissing] when nothing is stored,
  /// - [KtAuthRejected] when KT rejects the stored credentials,
  /// - [Offline] on transport failure,
  /// - [KtUnavailable] on any other KT/API error.
  Future<KtDayNutrition> fetchDay(LocalDate date) async {
    try {
      if (!_client.isLoggedIn) {
        final restored = await _client.restoreSession();
        if (!restored) {
          throw const SyncIssueException(KtCredentialsMissing());
        }
      }

      try {
        return await _client.fetchDaySummary(date);
      } on KtNetworkException {
        rethrow;
      } on KtApiException catch (e) {
        return await _refreshAndRetry(date, e);
      } on KtAuthException catch (e) {
        return await _refreshAndRetry(date, e);
      }
    } on SyncIssueException {
      rethrow;
    } catch (e, st) {
      throw SyncIssueException(_classify(e, st, date), e);
    }
  }

  Future<KtDayNutrition> _refreshAndRetry(LocalDate date, Object first) async {
    if (_refreshUsed) throw first;
    _refreshUsed = true;
    AppLog.kt.info(
      'KT fetch failed for $date — refreshing session once',
      payload: '$first',
    );
    final refreshed = await _client.refreshSession();
    if (!refreshed) throw const SyncIssueException(KtCredentialsMissing());
    return _client.fetchDaySummary(date);
  }

  SyncIssue _classify(Object e, StackTrace st, LocalDate date) {
    final SyncIssue issue = switch (e) {
      KtNetworkException() => const Offline(),
      KtAuthException() => const KtAuthRejected(),
      KtApiException() => const KtUnavailable(),
      _ => const UnexpectedIssue(),
    };
    AppLog.kt.error(
      'KT fetch for $date → ${issue.code}',
      err: e,
      stackTrace: issue is UnexpectedIssue ? st : null,
    );
    return issue;
  }
}
