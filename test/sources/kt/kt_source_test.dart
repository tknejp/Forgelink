import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/core/local_date.dart';
import 'package:forgelink/core/sync_issue.dart';
import 'package:forgelink/sources/kt/kt_client.dart';
import 'package:forgelink/sources/kt/kt_source.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'kt_test_helpers.dart';

void main() {
  const storage = FlutterSecureStorage();
  final day = LocalDate(2026, 4, 9);
  const storedCreds = {
    'kt_email': 'jan@example.com',
    'kt_pwd_hash': '5ebe2294ecd0e0f08eab7690d2a6ee69',
  };

  KtSource sourceWith(Future<http.Response> Function(http.Request) handler) =>
      KtSource(KtClient(storage: storage, client: MockClient(handler)))
        ..beginRun();

  Future<SyncIssue?> issueOf(Future<Object?> f) => f.then<SyncIssue?>(
    (_) => null,
    onError: (Object e) => (e as SyncIssueException).issue,
  );

  test('no stored credentials → KtCredentialsMissing', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final s = sourceWith((r) async => loginOk());
    expect(await issueOf(s.fetchDay(day)), isA<KtCredentialsMissing>());
  });

  test('restores the session from stored credentials and fetches', () async {
    FlutterSecureStorage.setMockInitialValues(storedCreds);
    final s = sourceWith((r) async => isLogin(r) ? loginOk() : summary());
    final n = await s.fetchDay(day);
    expect(n.kcal, 2700.0);
  });

  test('expired session → one silent refresh, then success', () async {
    FlutterSecureStorage.setMockInitialValues(storedCreds);
    var logins = 0;
    var gets = 0;
    final s = sourceWith((r) async {
      if (isLogin(r)) {
        logins++;
        return loginOk();
      }
      gets++;
      return gets == 1 ? http.Response('', 401) : summary();
    });
    final n = await s.fetchDay(day);
    expect(n.hasData, isTrue);
    expect(logins, 2); // restore + refresh
  });

  test('refresh rejected → KtAuthRejected, credentials kept', () async {
    FlutterSecureStorage.setMockInitialValues(storedCreds);
    var logins = 0;
    final s = sourceWith((r) async {
      if (isLogin(r)) return ++logins == 1 ? loginOk() : loginRejected();
      return http.Response('', 401);
    });
    expect(await issueOf(s.fetchDay(day)), isA<KtAuthRejected>());
    expect(await storage.read(key: 'kt_email'), 'jan@example.com');
    expect(await storage.read(key: 'kt_pwd_hash'), isNotNull);
  });

  test('only one refresh per run', () async {
    FlutterSecureStorage.setMockInitialValues(storedCreds);
    var logins = 0;
    final s = sourceWith((r) async {
      if (isLogin(r)) {
        logins++;
        return loginOk();
      }
      return http.Response('', 500);
    });
    expect(await issueOf(s.fetchDay(day)), isA<KtUnavailable>());
    expect(await issueOf(s.fetchDay(day.addDays(1))), isA<KtUnavailable>());
    expect(logins, 2); // restore + a single refresh
  });

  test('network failure → Offline, no refresh attempt', () async {
    FlutterSecureStorage.setMockInitialValues(storedCreds);
    var logins = 0;
    final s = sourceWith((r) async {
      if (isLogin(r)) {
        logins++;
        return loginOk();
      }
      throw const SocketException('no route');
    });
    expect(await issueOf(s.fetchDay(day)), isA<Offline>());
    expect(logins, 1);
  });
}
