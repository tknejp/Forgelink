import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../core/app_config.dart';
import '../core/app_log.dart';
import '../core/sync_issue.dart';
import 'google_auth.dart';
import 'sheets_gateway.dart';

@immutable
class DriveSpreadsheet {
  final String id;
  final String name;
  final String? owner;
  final DateTime? modified;
  final bool canEdit;

  const DriveSpreadsheet({
    required this.id,
    required this.name,
    required this.canEdit,
    this.owner,
    this.modified,
  });
}

/// "Vybrat z Google Disku" (plan Phase 7): lists spreadsheets the pinned
/// account can see, newest-viewed first. Uses the extra
/// `drive.metadata.readonly` scope, requested only here.
class DriveChooser {
  DriveChooser(this._auth, {http.Client Function()? httpClient})
    : _httpClient = httpClient ?? http.Client.new;

  final GoogleAuth _auth;
  final http.Client Function() _httpClient;

  static const _scopes = [AppConfig.sheetsScope, AppConfig.driveMetadataScope];

  /// Throws [SyncIssueException] (e.g. [DriveApiDisabled], [Offline],
  /// [GoogleReauthRequired]).
  Future<List<DriveSpreadsheet>> list({String nameContains = ''}) async {
    final token = await _auth.tokenForScopes(_scopes, interactive: true);
    final base = _httpClient();
    final client = authenticatedClient(
      base,
      AccessCredentials(
        AccessToken(
          'Bearer',
          token,
          DateTime.now().toUtc().add(const Duration(minutes: 50)),
        ),
        null,
        _scopes,
      ),
    );
    try {
      final res = await drive.DriveApi(client).files.list(
        q: query(nameContains),
        orderBy: 'viewedByMeTime desc,modifiedTime desc',
        pageSize: 50,
        $fields:
            'files(id,name,owners(displayName),modifiedTime,capabilities(canEdit))',
      );
      final files = [
        for (final f in res.files ?? const <drive.File>[])
          if (f.id != null)
            DriveSpreadsheet(
              id: f.id!,
              name: f.name ?? f.id!,
              owner: f.owners?.firstOrNull?.displayName,
              modified: f.modifiedTime,
              canEdit: f.capabilities?.canEdit ?? false,
            ),
      ];
      AppLog.sheets.info('Drive chooser: ${files.length} spreadsheets');
      return files;
    } catch (e, st) {
      final SyncIssue issue =
          e is drive.DetailedApiRequestError &&
              e.status == 403 &&
              '${e.jsonResponse}'.contains('SERVICE_DISABLED')
          ? const DriveApiDisabled()
          : classifySheetsError(e, email: await _auth.accountEmail());
      AppLog.sheets.error(
        'Drive chooser failed → ${issue.code}',
        err: e,
        stackTrace: issue is UnexpectedIssue ? st : null,
      );
      throw SyncIssueException(issue, e);
    } finally {
      client.close();
      base.close();
    }
  }

  /// Drive `q` for spreadsheets, optionally filtered by name. Pure.
  static String query(String nameContains) {
    final base =
        "mimeType='application/vnd.google-apps.spreadsheet' and trashed=false";
    final term = nameContains.trim();
    if (term.isEmpty) return base;
    final escaped = term.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
    return "$base and name contains '$escaped'";
  }
}
