/// App-wide constants. Values that the user can change live in `PrefsStore`.
abstract final class AppConfig {
  /// Brand name — intentionally not localized (launcher label, MaterialApp title).
  static const appName = 'Forgelink';

  /// Google Cloud project `forgelink-511721` (#598204569304).
  ///
  /// Web OAuth client ID used as `serverClientId` for
  /// `GoogleSignIn.instance.initialize`. Required for the connect flow on
  /// Android (docs/implementation_plan.md §11 step 6).
  static const googleWebClientId =
      '598204569304-4556eie5qesqgqusnqsdumi2fdhuhm7f.apps.googleusercontent.com';

  static const sheetsScope = 'https://www.googleapis.com/auth/spreadsheets';

  /// Default name of the coach's tab; editable in Settings → Tabulka.
  static const defaultSheetTab = 'tracker';

  static const ktBaseUrl = 'https://www.kaloricketabulky.cz';

  /// Upper bound for one date-range sync (docs/implementation_plan.md §4).
  static const maxRangeDays = 120;
}

/// Fields Forgelink owns on the coach's sheet. The actual sheet column is
/// located per weekly Table by [header] (older weeks use a different column
/// order); [letter] is only the layout of the newest weeks, for reference.
/// The date column and the manual columns are never written.
enum SheetColumn {
  weight('B', 'VÁHA'),
  kcal('C', 'KCAL'),
  protein('D', 'BÍLKOVINY'),
  carbs('E', 'SACHARIDY'),
  fat('F', 'TUKY'),
  fiber('G', 'VLÁKNINA'),
  steps('H', 'KROKY');

  const SheetColumn(this.letter, this.header);

  /// A1 column letter.
  final String letter;

  /// Expected (normalized, uppercase) header in the weekly Table.
  final String header;
}
