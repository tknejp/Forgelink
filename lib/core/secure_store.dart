import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The single secure-storage instance of the app.
///
/// `resetOnError: false` so a keystore hiccup (e.g. in the background worker)
/// cannot silently wipe the stored Kalorické tabulky credentials. Every
/// consumer — including the ported KT client — must receive this instance;
/// never construct `FlutterSecureStorage` with default options elsewhere.
abstract final class SecureStore {
  static const FlutterSecureStorage instance = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false),
  );
}
