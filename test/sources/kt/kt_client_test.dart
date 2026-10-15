import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/core/local_date.dart';
import 'package:forgelink/sources/kt/kt_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'kt_test_helpers.dart';

void main() {
  const storage = FlutterSecureStorage();
  final day = LocalDate(2026, 4, 9);

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  KtClient clientWith(Future<http.Response> Function(http.Request) handler) =>
      KtClient(storage: storage, client: MockClient(handler));

  group('summary parsing', () {
    Future<KtDayNutrition> parse(
        [void Function(Map<String, dynamic>)? mutate]) async {
      final c = clientWith((r) async => isLogin(r) ? loginOk() : summary(mutate));
      await c.login('jan@example.com', 'secret');
      return c.fetchDaySummary(day);
    }

    test('captured fixture → all five values', () async {
      final n = await parse();
      expect(n.kcal, 2700.0);
      expect(n.protein!.round(), 216);
      expect(n.carbs!.round(), 308);
      expect(n.fat!.round(), 61);
      expect(n.fiber!.round(), 27);
      expect(n.hasData, isTrue);
    });

    test('absent nutrient code → null, never 0', () async {
      final n = await parse((data) {
        for (final group in data['itemsDynamic'] as List) {
          (group as List).removeWhere((e) => (e as Map)['code'] == 'fiber');
        }
      });
      expect(n.fiber, isNull);
      expect(n.protein, isNotNull);
    });

    test('kcal falls back to the "total" item (localized "2 700")', () async {
      final n = await parse((data) => data.remove('foodstuffEnergyTotal'));
      expect(n.kcal, 2700.0);
    });

    test('a present 0 is a real zero', () async {
      final n = await parse((data) {
        final first = (data['itemsDynamic'] as List).first as List;
        final fiber = first.firstWhere((e) => (e as Map)['code'] == 'fiber')
            as Map<String, dynamic>;
        fiber['actualValue'] = 0.0;
        fiber['actual'] = '0';
      });
      expect(n.fiber, 0.0);
      expect(n.hasData, isTrue);
    });

    test('empty day → hasData false', () async {
      final n = await parse((data) {
        data['foodstuffEnergyTotal'] = 0.0;
        for (final item in data['items'] as List) {
          (item as Map)['actual'] = '0';
        }
        for (final group in data['itemsDynamic'] as List) {
          for (final e in group as List) {
            (e as Map)['actualValue'] = 0.0;
            e['actual'] = '0';
          }
        }
      });
      expect(n.hasData, isFalse);
    });

    test('kJ energy unit is converted to kcal', () async {
      final n = await parse((data) {
        data['energyUnit'] = 'kJ';
        data['foodstuffEnergyTotal'] = 4184.0;
      });
      expect(n.kcal!.round(), 1000);
    });

    test('code 0 with no expected keys → treated as an invalid session',
        () async {
      final c = clientWith((r) async => isLogin(r)
          ? loginOk()
          : jsonResponse({'code': 0, 'data': <String, dynamic>{}}));
      await c.login('jan@example.com', 'secret');
      expect(() => c.fetchDaySummary(day), throwsA(isA<KtAuthException>()));
    });

    test('date is sent as dd.MM.yyyy', () async {
      Uri? requested;
      final c = clientWith((r) async {
        if (isLogin(r)) return loginOk();
        requested = r.url;
        return summary();
      });
      await c.login('jan@example.com', 'secret');
      await c.fetchDaySummary(LocalDate(2026, 3, 5));
      expect(requested!.path, contains('/summary/05.03.2026/'));
    });
  });

  group('session', () {
    test('login stores email + MD5 hash, sends the cookie on GET', () async {
      String? cookie;
      final c = clientWith((r) async {
        if (isLogin(r)) return loginOk();
        cookie = r.headers['Cookie'];
        return summary();
      });
      await c.login('jan@example.com', 'secret');
      await c.fetchDaySummary(day);

      expect(cookie, 'PHPSESSID=abc123');
      expect(await storage.read(key: 'kt_email'), 'jan@example.com');
      // md5('secret')
      expect(await storage.read(key: 'kt_pwd_hash'),
          '5ebe2294ecd0e0f08eab7690d2a6ee69');
    });

    test('rejected login → KtAuthException and nothing stored', () async {
      final c = clientWith((r) async => loginRejected());
      await expectLater(
          c.login('jan@example.com', 'wrong'), throwsA(isA<KtAuthException>()));
      expect(await c.hasStoredCredentials(), isFalse);
    });

    test('401 on GET → KtAuthException and session invalidated', () async {
      final c = clientWith((r) async =>
          isLogin(r) ? loginOk() : http.Response('', 401));
      await c.login('jan@example.com', 'secret');
      await expectLater(
          c.fetchDaySummary(day), throwsA(isA<KtAuthException>()));
      expect(c.isLoggedIn, isFalse);
    });

    test('socket error → KtNetworkException', () async {
      final c = clientWith((r) async => throw const SocketException('down'));
      await expectLater(c.login('jan@example.com', 'secret'),
          throwsA(isA<KtNetworkException>()));
    });

    test('HTTP 500 → KtApiException (not network)', () async {
      final c = clientWith((r) async =>
          isLogin(r) ? loginOk() : http.Response('oops', 500));
      await c.login('jan@example.com', 'secret');
      final e = await c.fetchDaySummary(day).then<Object?>((_) => null,
          onError: (Object e) => e);
      expect(e, isA<KtApiException>());
      expect(e, isNot(isA<KtNetworkException>()));
    });

    test('restoreSession without stored credentials → false', () async {
      final c = clientWith((r) async => loginOk());
      expect(await c.restoreSession(), isFalse);
    });
  });
}
