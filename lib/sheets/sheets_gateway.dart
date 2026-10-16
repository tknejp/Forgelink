import 'dart:async';
import 'dart:io';

import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;

import '../core/app_config.dart';
import '../core/app_log.dart';
import '../core/sync_issue.dart';
import 'google_auth.dart';

/// Thin Sheets v4 wrapper: one fresh `AuthClient` per call, auth retry,
/// backoff for 429/5xx, and error classification into [SyncIssue]s
/// (docs/archive/implementation_plan.md §6). Every failure leaves as
/// [SyncIssueException].
class SheetsGateway {
  SheetsGateway(
    this._tokens, {
    http.Client Function()? httpClient,
    Future<void> Function(Duration)? delay,
    this.interactive = true,
  }) : _httpClient = httpClient ?? http.Client.new,
       _delay = delay ?? Future<void>.delayed;

  final TokenProvider _tokens;
  final http.Client Function() _httpClient;
  final Future<void> Function(Duration) _delay;

  /// Foreground runs may show Google UI to recover authorization.
  final bool interactive;

  static const _maxAttempts = 4;

  Future<Spreadsheet> metadata(String spreadsheetId) => _run(
    'metadata',
    (api) => api.spreadsheets.get(
      spreadsheetId,
      $fields:
          'properties(title,locale,timeZone),'
          'sheets(properties(sheetId,title),'
          'tables(tableId,name,range,rowsProperties(footerColorStyle),'
          'columnProperties(columnIndex,columnName,columnType)))',
    ),
  );

  Future<ValueRange> values(
    String spreadsheetId,
    String range, {
    required String valueRenderOption,
    String? dateTimeRenderOption,
  }) => _run(
    'values.get $range ($valueRenderOption)',
    (api) => api.spreadsheets.values.get(
      spreadsheetId,
      range,
      valueRenderOption: valueRenderOption,
      dateTimeRenderOption: dateTimeRenderOption,
      majorDimension: 'ROWS',
    ),
  );

  /// Values-only write (`RAW`, never `USER_ENTERED`).
  Future<BatchUpdateValuesResponse> writeValues(
    String spreadsheetId,
    List<ValueRange> data,
  ) => _run(
    'values.batchUpdate (${data.length} ranges)',
    (api) => api.spreadsheets.values.batchUpdate(
      BatchUpdateValuesRequest(valueInputOption: 'RAW', data: data),
      spreadsheetId,
      $fields: 'totalUpdatedCells',
    ),
  );

  Future<T> _run<T>(String label, Future<T> Function(SheetsApi api) op) async {
    var tokenRetried = false;
    for (var attempt = 1; ; attempt++) {
      final token = await _tokens.accessToken(interactive: interactive);
      final base = _httpClient();
      final client = authenticatedClient(
        base,
        AccessCredentials(
          // The Play-services token carries no expiry; use a short synthetic one.
          AccessToken(
            'Bearer',
            token,
            DateTime.now().toUtc().add(const Duration(minutes: 50)),
          ),
          null,
          const [AppConfig.sheetsScope],
        ),
      );
      try {
        return await op(SheetsApi(client));
      } on AccessDeniedException catch (e) {
        final msg = e.message;
        if (msg.contains('insufficient_scope')) {
          AppLog.sheets.warn('$label: insufficient scope', payload: msg);
          throw SyncIssueException(const GoogleReauthRequired(), e);
        }
        if (!tokenRetried) {
          tokenRetried = true;
          AppLog.sheets.info(
            '$label: token rejected, clearing and retrying once',
            payload: msg,
          );
          await _tokens.invalidate(token);
          continue;
        }
        throw SyncIssueException(const GoogleReauthRequired(), e);
      } on DetailedApiRequestError catch (e) {
        final status = e.status ?? 0;
        if ((status == 429 || status >= 500) && attempt < _maxAttempts) {
          final wait = status == 429
              ? const Duration(seconds: 60)
              : Duration(seconds: 1 << attempt);
          AppLog.sheets.warn('$label: HTTP $status, retry $attempt in $wait');
          await _delay(wait);
          continue;
        }
        final issue = classifySheetsError(
          e,
          email: await _tokens.accountEmail(),
        );
        AppLog.sheets.error(
          '$label → ${issue.code}',
          payload: 'status=$status, json=${e.jsonResponse}',
          err: e,
        );
        throw SyncIssueException(issue, e);
      } on SyncIssueException {
        rethrow;
      } catch (e, st) {
        final issue = classifySheetsError(e);
        AppLog.sheets.error(
          '$label → ${issue.code}',
          err: e,
          stackTrace: issue is UnexpectedIssue ? st : null,
        );
        throw SyncIssueException(issue, e);
      } finally {
        client.close();
        base.close();
      }
    }
  }
}

/// Maps a Sheets failure to a [SyncIssue] (plan §6). Pure, for tests.
SyncIssue classifySheetsError(Object e, {String? email}) {
  if (e is DetailedApiRequestError) {
    final status = e.status ?? 0;
    final reasons = _errorReasons(e.jsonResponse);
    if (status == 403 && reasons.contains('SERVICE_DISABLED')) {
      return const SheetsApiDisabled();
    }
    if (status == 403 && reasons.contains('ACCESS_TOKEN_SCOPE_INSUFFICIENT')) {
      return const GoogleReauthRequired();
    }
    if (status == 401) return const GoogleReauthRequired();
    if (status == 403) return SheetNoEditAccess(email ?? '');
    if (status == 404) return const SheetNotFound();
    if (status == 429 || status >= 500) return const SheetsUnavailable();
    return const UnexpectedIssue();
  }
  if (e is AccessDeniedException) return const GoogleReauthRequired();
  if (e is SocketException ||
      e is http.ClientException ||
      e is TimeoutException ||
      e is HandshakeException) {
    return const Offline();
  }
  return const UnexpectedIssue();
}

Set<String> _errorReasons(Map<String, dynamic>? json) {
  final error = json?['error'];
  if (error is! Map) return const {};
  final details = error['details'];
  return {
    if (details is List)
      for (final d in details)
        if (d is Map && d['reason'] is String) d['reason'] as String,
  };
}
