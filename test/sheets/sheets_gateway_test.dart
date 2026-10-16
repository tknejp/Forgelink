import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/core/local_date.dart';
import 'package:forgelink/core/sync_issue.dart';
import 'package:forgelink/sheets/google_auth.dart';
import 'package:forgelink/sheets/sheets_gateway.dart';
import 'package:forgelink/sheets/tracker_index.dart';
import 'package:forgelink/sheets/tracker_sheet.dart';
import 'package:forgelink/sheets/write_plan.dart';
import 'package:forgelink/core/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'tracker_fixture.dart';

class FakeTokens implements TokenProvider {
  int issued = 0;
  final invalidated = <String>[];
  String? email = 'tom@example.com';

  @override
  Future<String?> accountEmail() async => email;

  @override
  Future<String> accessToken({required bool interactive}) async =>
      'token-${++issued}';

  @override
  Future<void> invalidate(String token) async => invalidated.add(token);
}

http.Response json(
  Object body, {
  int status = 200,
  Map<String, String>? headers,
}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json', ...?headers},
);

http.Response apiError(int status, String errStatus, [String? reason]) => json({
  'error': {
    'code': status,
    'message': 'err',
    'status': errStatus,
    if (reason != null)
      'details': [
        {'@type': 'type.googleapis.com/google.rpc.ErrorInfo', 'reason': reason},
      ],
  },
}, status: status);

void main() {
  const id = 'sheet-id';
  late FakeTokens tokens;
  final delays = <Duration>[];

  setUp(() {
    tokens = FakeTokens();
    delays.clear();
  });

  SheetsGateway gatewayWith(Future<http.Response> Function(http.Request) h) =>
      SheetsGateway(
        tokens,
        httpClient: () => MockClient(h),
        delay: (d) async => delays.add(d),
      );

  Future<SyncIssue?> issueOf(Future<Object?> f) => f.then<SyncIssue?>(
    (_) => null,
    onError: (Object e) => (e as SyncIssueException).issue,
  );

  test('sends the bearer token', () async {
    String? auth;
    final g = gatewayWith((r) async {
      auth = r.headers['Authorization'];
      return json({'sheets': []});
    });
    await g.metadata(id);
    expect(auth, 'Bearer token-1');
  });

  test('401 invalid_token → token cleared, one retry succeeds', () async {
    var calls = 0;
    final g = gatewayWith((r) async {
      if (++calls == 1) {
        return http.Response(
          '',
          401,
          headers: {'www-authenticate': 'Bearer error="invalid_token"'},
        );
      }
      return json({'sheets': []});
    });
    await g.metadata(id);
    expect(tokens.invalidated, ['token-1']);
    expect(calls, 2);
  });

  test('persistent invalid_token → GoogleReauthRequired', () async {
    final g = gatewayWith(
      (r) async => http.Response(
        '',
        401,
        headers: {'www-authenticate': 'Bearer error="invalid_token"'},
      ),
    );
    expect(await issueOf(g.metadata(id)), isA<GoogleReauthRequired>());
  });

  test(
    'insufficient_scope → GoogleReauthRequired without retry loop',
    () async {
      var calls = 0;
      final g = gatewayWith((r) async {
        calls++;
        return http.Response(
          '',
          403,
          headers: {'www-authenticate': 'Bearer error="insufficient_scope"'},
        );
      });
      expect(await issueOf(g.metadata(id)), isA<GoogleReauthRequired>());
      expect(calls, 1);
    },
  );

  test('403 SERVICE_DISABLED → SheetsApiDisabled', () async {
    final g = gatewayWith(
      (r) async => apiError(403, 'PERMISSION_DENIED', 'SERVICE_DISABLED'),
    );
    expect(await issueOf(g.metadata(id)), isA<SheetsApiDisabled>());
  });

  test('plain 403 → SheetNoEditAccess naming the account', () async {
    final g = gatewayWith((r) async => apiError(403, 'PERMISSION_DENIED'));
    final issue = await issueOf(g.metadata(id));
    expect(issue, isA<SheetNoEditAccess>());
    expect((issue as SheetNoEditAccess).email, 'tom@example.com');
  });

  test('404 → SheetNotFound', () async {
    final g = gatewayWith((r) async => apiError(404, 'NOT_FOUND'));
    expect(await issueOf(g.metadata(id)), isA<SheetNotFound>());
  });

  test('503 retried with backoff, then SheetsUnavailable', () async {
    var calls = 0;
    final g = gatewayWith((r) async {
      calls++;
      return apiError(503, 'UNAVAILABLE');
    });
    expect(await issueOf(g.metadata(id)), isA<SheetsUnavailable>());
    expect(calls, 4);
    expect(delays, [
      const Duration(seconds: 2),
      const Duration(seconds: 4),
      const Duration(seconds: 8),
    ]);
  });

  test('429 waits at least 60 s', () async {
    var calls = 0;
    final g = gatewayWith(
      (r) async => ++calls == 1
          ? apiError(429, 'RESOURCE_EXHAUSTED')
          : json({'sheets': []}),
    );
    await g.metadata(id);
    expect(delays, [const Duration(seconds: 60)]);
  });

  test('socket error → Offline', () async {
    final g = gatewayWith((r) async => throw const SocketException('down'));
    expect(await issueOf(g.metadata(id)), isA<Offline>());
  });

  test('not connected → GoogleNotConnected surfaces unchanged', () async {
    final g = SheetsGateway(
      _NoAccount(),
      httpClient: () => MockClient((r) async => json({})),
    );
    expect(await issueOf(g.metadata(id)), isA<GoogleNotConnected>());
  });

  group('TrackerSheet over HTTP', () {
    Map<String, dynamic> metadataJson({String tab = 'tracker'}) => {
      'sheets': [
        {
          'properties': {'sheetId': 1, 'title': 'weightlog'},
        },
        {
          'properties': {'sheetId': 2, 'title': tab},
          'tables': [
            {
              'tableId': 't63',
              'name': 'Tabulka63',
              'range': {
                'sheetId': 2,
                'startRowIndex': 881,
                'endRowIndex': 890,
                'startColumnIndex': 0,
                'endColumnIndex': 12,
              },
              'rowsProperties': {
                'footerColorStyle': {
                  'rgbColor': {'red': 1},
                },
              },
              'columnProperties': [
                for (final (i, n) in const [
                  'DATUM', 'VÁHA', 'KCAL', 'BÍLKOVINY', 'SACHARIDY', //
                  'TUKY', 'VLÁKNINA', 'KROKY',
                ].indexed)
                  {'columnIndex': i, 'columnName': n},
              ],
            },
          ],
        },
      ],
    };

    test('loadIndex reads metadata + A:H and builds the index', () async {
      final requested = <Uri>[];
      final g = gatewayWith((r) async {
        requested.add(r.url);
        if (r.url.path.endsWith('/$id')) return json(metadataJson());
        return json({
          'range': "'tracker'!A1:H890",
          'majorDimension': 'ROWS',
          'values': trackerValues(),
        });
      });
      final index = await TrackerSheet(g).loadIndex(id, 'tracker');
      expect(index.rows[LocalDate(2026, 10, 12)]!.row, 883);
      expect(index.weekTables, 1);

      final valuesCall = requested.last;
      expect(
        valuesCall.queryParameters['valueRenderOption'],
        'UNFORMATTED_VALUE',
      );
      expect(
        valuesCall.queryParameters['dateTimeRenderOption'],
        'SERIAL_NUMBER',
      );
      expect(Uri.decodeComponent(valuesCall.path), contains("'tracker'!A:H"));
      // Table with only A..H headers → read A:H.
    });

    test('missing tab → SheetTabMissing', () async {
      final g = gatewayWith((r) async => json(metadataJson(tab: 'other')));
      final issue = await issueOf(TrackerSheet(g).loadIndex(id, 'tracker'));
      expect(issue, isA<SheetTabMissing>());
    });

    test(
      'write sends one RAW batchUpdate with only the planned ranges',
      () async {
        Map<String, dynamic>? body;
        var calls = 0;
        final g = gatewayWith((r) async {
          calls++;
          body = jsonDecode(r.body) as Map<String, dynamic>;
          return json({'totalUpdatedCells': 7});
        });
        final plan = buildWritePlan(
          tab: 'tracker',
          index: _indexFor(),
          values: {
            LocalDate(2026, 10, 12): {
              SheetColumn.weight: 106.3,
              SheetColumn.kcal: 2700,
              SheetColumn.steps: 8432,
            },
          },
        );
        final updated = await TrackerSheet(g).write(id, plan);
        expect(updated, 7);
        expect(calls, 1);
        expect(body!['valueInputOption'], 'RAW');
        expect(
          [for (final d in body!['data'] as List) (d as Map)['range']],
          ["'tracker'!B883:C883", "'tracker'!H883"],
        );
      },
    );

    test('no writes → no request at all', () async {
      var calls = 0;
      final g = gatewayWith((r) async {
        calls++;
        return json({});
      });
      final plan = buildWritePlan(
        tab: 'tracker',
        index: _indexFor(),
        values: const {},
      );
      expect(await TrackerSheet(g).write(id, plan), 0);
      expect(calls, 0);
    });
  });
}

class _NoAccount implements TokenProvider {
  @override
  Future<String?> accountEmail() async => null;
  @override
  Future<String> accessToken({required bool interactive}) async =>
      throw const SyncIssueException(GoogleNotConnected());
  @override
  Future<void> invalidate(String token) async {}
}

TrackerIndex _indexFor() =>
    TrackerIndex.build(tables: [weekTable()], values: trackerValues());
