import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/core/prefs_store.dart';
import 'package:forgelink/core/sync_issue.dart';
import 'package:forgelink/sources/kt/kt_client.dart';
import 'package:forgelink/sync/integration_status.dart';
import 'package:forgelink/ui/settings/kt_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../sources/kt/kt_test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    FlutterSecureStorage.setMockInitialValues({});
  });

  KtController controllerWith(http.Response Function() login) {
    final client = KtClient(
      storage: const FlutterSecureStorage(),
      client: MockClient((_) async => login()),
    );
    return KtController(client, IntegrationStatusStore(PrefsStore()));
  }

  test('starts not configured', () async {
    final c = controllerWith(loginOk);
    await c.load();
    expect(c.status.state, IntegrationState.notConfigured);
  });

  test('successful login → verified, persisted across reloads', () async {
    final c = controllerWith(loginOk);
    expect(await c.login(' jan@example.com ', 'secret'), isTrue);
    expect(c.status.state, IntegrationState.verified);
    expect(c.storedEmail, 'jan@example.com');

    final again = controllerWith(loginOk);
    await again.load();
    expect(again.status.state, IntegrationState.verified);
  });

  test('rejected login → KtAuthRejected shown, nothing stored', () async {
    final c = controllerWith(loginRejected);
    expect(await c.login('jan@example.com', 'wrong'), isFalse);
    expect(c.lastAttemptIssue, isA<KtAuthRejected>());
    expect(c.status.state, IntegrationState.notConfigured);
  });

  test('logout clears credentials and status', () async {
    final c = controllerWith(loginOk);
    await c.login('jan@example.com', 'secret');
    await c.logout();
    expect(c.status.state, IntegrationState.notConfigured);
    expect(c.storedEmail, isNull);
  });
}
