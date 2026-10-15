import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Captured real response (Forgetrack docs/integrations/kt_api_reference.md,
/// 09.04.2026): kcal 2700, protein 216.009, carbs 308.422, fat 61.2185,
/// fiber 26.645.
Map<String, dynamic> loadSummaryFixture() => jsonDecode(
      File('test/fixtures/kt_summary_2026-04-09.json').readAsStringSync(),
    ) as Map<String, dynamic>;

http.Response jsonResponse(Object body,
        {int status = 200, Map<String, String>? headers}) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8', ...?headers},
    );

http.Response loginOk() => jsonResponse(
      {'code': 0, 'message': null},
      headers: {'set-cookie': 'PHPSESSID=abc123; path=/; HttpOnly'},
    );

http.Response loginRejected() =>
    jsonResponse({'code': 1, 'message': 'Neplatné přihlašovací údaje'});

/// A summary payload built from the fixture with [mutate] applied to `data`.
http.Response summary([void Function(Map<String, dynamic> data)? mutate]) {
  final body = loadSummaryFixture();
  mutate?.call(body['data'] as Map<String, dynamic>);
  return jsonResponse(body);
}

bool isLogin(http.Request r) =>
    r.method == 'POST' && r.url.path.contains('/login/create');

bool isSummary(http.Request r) =>
    r.method == 'GET' && r.url.path.contains('/user/diary/summary/');
