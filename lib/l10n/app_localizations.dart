import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_cs.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('cs')];

  /// Settings screen title / tooltip of the settings icon.
  ///
  /// In cs, this message translates to:
  /// **'Nastavení'**
  String get settingsTitle;

  /// No description provided for @homeIntegrationsTitle.
  ///
  /// In cs, this message translates to:
  /// **'Propojení'**
  String get homeIntegrationsTitle;

  /// No description provided for @homeAllConnected.
  ///
  /// In cs, this message translates to:
  /// **'Vše připojeno'**
  String get homeAllConnected;

  /// No description provided for @homeNotConfiguredYet.
  ///
  /// In cs, this message translates to:
  /// **'Aplikace zatím není nastavená.'**
  String get homeNotConfiguredYet;

  /// No description provided for @homeOpenSettings.
  ///
  /// In cs, this message translates to:
  /// **'Otevřít nastavení'**
  String get homeOpenSettings;

  /// No description provided for @homeLastSyncTitle.
  ///
  /// In cs, this message translates to:
  /// **'Poslední synchronizace'**
  String get homeLastSyncTitle;

  /// No description provided for @homeLastSyncNever.
  ///
  /// In cs, this message translates to:
  /// **'Zatím neproběhla žádná synchronizace.'**
  String get homeLastSyncNever;

  /// No description provided for @homeQuickSyncButton.
  ///
  /// In cs, this message translates to:
  /// **'Synchronizovat'**
  String get homeQuickSyncButton;

  /// No description provided for @homeQuickSyncSubtitle.
  ///
  /// In cs, this message translates to:
  /// **'Včera: výživa a kroky · Dnes: váha'**
  String get homeQuickSyncSubtitle;

  /// No description provided for @homeCalendarTitle.
  ///
  /// In cs, this message translates to:
  /// **'Kalendář'**
  String get homeCalendarTitle;

  /// Placeholder for home sections built in later implementation phases.
  ///
  /// In cs, this message translates to:
  /// **'Bude doplněno v další fázi.'**
  String get homeComingSoon;

  /// No description provided for @homeAdvancedTitle.
  ///
  /// In cs, this message translates to:
  /// **'Další možnosti'**
  String get homeAdvancedTitle;

  /// No description provided for @homeRangeSync.
  ///
  /// In cs, this message translates to:
  /// **'Synchronizovat období…'**
  String get homeRangeSync;

  /// No description provided for @homeHistory.
  ///
  /// In cs, this message translates to:
  /// **'Historie synchronizací'**
  String get homeHistory;

  /// No description provided for @settingsSectionHealthConnect.
  ///
  /// In cs, this message translates to:
  /// **'Health Connect'**
  String get settingsSectionHealthConnect;

  /// No description provided for @settingsSectionKt.
  ///
  /// In cs, this message translates to:
  /// **'Kalorické tabulky'**
  String get settingsSectionKt;

  /// No description provided for @settingsSectionGoogle.
  ///
  /// In cs, this message translates to:
  /// **'Google účet'**
  String get settingsSectionGoogle;

  /// No description provided for @settingsSectionSheet.
  ///
  /// In cs, this message translates to:
  /// **'Tabulka'**
  String get settingsSectionSheet;

  /// No description provided for @settingsSectionAutoSync.
  ///
  /// In cs, this message translates to:
  /// **'Automatická synchronizace'**
  String get settingsSectionAutoSync;

  /// No description provided for @settingsSectionDiagnostics.
  ///
  /// In cs, this message translates to:
  /// **'Diagnostika'**
  String get settingsSectionDiagnostics;

  /// No description provided for @statusNotConfigured.
  ///
  /// In cs, this message translates to:
  /// **'Nenastaveno'**
  String get statusNotConfigured;

  /// No description provided for @statusConfigured.
  ///
  /// In cs, this message translates to:
  /// **'Nastaveno'**
  String get statusConfigured;

  /// No description provided for @statusReadVerified.
  ///
  /// In cs, this message translates to:
  /// **'Čtení ověřeno'**
  String get statusReadVerified;

  /// No description provided for @statusVerified.
  ///
  /// In cs, this message translates to:
  /// **'Ověřeno'**
  String get statusVerified;

  /// No description provided for @statusError.
  ///
  /// In cs, this message translates to:
  /// **'Chyba'**
  String get statusError;

  /// No description provided for @settingsOpenHealthConnect.
  ///
  /// In cs, this message translates to:
  /// **'Otevřít Health Connect'**
  String get settingsOpenHealthConnect;

  /// No description provided for @settingsAutoSyncLater.
  ///
  /// In cs, this message translates to:
  /// **'Automatická synchronizace přibude v pozdější fázi.'**
  String get settingsAutoSyncLater;

  /// No description provided for @diagnosticsEmpty.
  ///
  /// In cs, this message translates to:
  /// **'Žádné záznamy.'**
  String get diagnosticsEmpty;

  /// No description provided for @diagnosticsCopy.
  ///
  /// In cs, this message translates to:
  /// **'Kopírovat'**
  String get diagnosticsCopy;

  /// No description provided for @diagnosticsCopied.
  ///
  /// In cs, this message translates to:
  /// **'Zkopírováno do schránky.'**
  String get diagnosticsCopied;

  /// No description provided for @diagnosticsClear.
  ///
  /// In cs, this message translates to:
  /// **'Vymazat'**
  String get diagnosticsClear;

  /// No description provided for @dataSourceHealthConnect.
  ///
  /// In cs, this message translates to:
  /// **'Health Connect'**
  String get dataSourceHealthConnect;

  /// Locative form, used in issueNoData: 'V {source} nejsou…'.
  ///
  /// In cs, this message translates to:
  /// **'Kalorických tabulkách'**
  String get dataSourceKt;

  /// No description provided for @hcTypeSteps.
  ///
  /// In cs, this message translates to:
  /// **'kroky'**
  String get hcTypeSteps;

  /// No description provided for @hcTypeWeight.
  ///
  /// In cs, this message translates to:
  /// **'váha'**
  String get hcTypeWeight;

  /// No description provided for @issueKtCredentialsMissing.
  ///
  /// In cs, this message translates to:
  /// **'Chybí přihlašovací údaje ke Kalorickým tabulkám.'**
  String get issueKtCredentialsMissing;

  /// No description provided for @issueKtAuthRejected.
  ///
  /// In cs, this message translates to:
  /// **'Přihlášení do Kalorických tabulek se nezdařilo. Zkontroluj e-mail a heslo.'**
  String get issueKtAuthRejected;

  /// No description provided for @issueKtUnavailable.
  ///
  /// In cs, this message translates to:
  /// **'Kalorické tabulky teď neodpovídají.'**
  String get issueKtUnavailable;

  /// No description provided for @issueGoogleNotConnected.
  ///
  /// In cs, this message translates to:
  /// **'Google účet není připojený.'**
  String get issueGoogleNotConnected;

  /// No description provided for @issueGoogleReauthRequired.
  ///
  /// In cs, this message translates to:
  /// **'Přihlášení ke Googlu vypršelo.'**
  String get issueGoogleReauthRequired;

  /// No description provided for @issueSheetNotConfigured.
  ///
  /// In cs, this message translates to:
  /// **'Není nastavená cílová tabulka.'**
  String get issueSheetNotConfigured;

  /// No description provided for @issueSheetNotFound.
  ///
  /// In cs, this message translates to:
  /// **'Tabulka nebyla nalezena. Zkontroluj odkaz v nastavení.'**
  String get issueSheetNotFound;

  /// No description provided for @issueSheetNoEditAccess.
  ///
  /// In cs, this message translates to:
  /// **'Účet {email} nemá oprávnění tabulku upravovat.'**
  String issueSheetNoEditAccess(String email);

  /// No description provided for @issueSheetsApiDisabled.
  ///
  /// In cs, this message translates to:
  /// **'Google Sheets API není v projektu Google Cloud povolené.'**
  String get issueSheetsApiDisabled;

  /// No description provided for @issueSheetTabMissing.
  ///
  /// In cs, this message translates to:
  /// **'V tabulce chybí list „{tab}“.'**
  String issueSheetTabMissing(String tab);

  /// No description provided for @issueSheetLayoutChanged.
  ///
  /// In cs, this message translates to:
  /// **'Rozvržení listu „{tab}“ se změnilo. Nic nebylo zapsáno.'**
  String issueSheetLayoutChanged(String tab);

  /// No description provided for @issueDateNotInSheet.
  ///
  /// In cs, this message translates to:
  /// **'Datum {date} v tabulce není. Nic nebylo zapsáno.'**
  String issueDateNotInSheet(String date);

  /// No description provided for @issueDateDuplicated.
  ///
  /// In cs, this message translates to:
  /// **'Datum {date} je v tabulce vícekrát (řádky {rows}). Nic nebylo zapsáno.'**
  String issueDateDuplicated(String date, String rows);

  /// No description provided for @issueCellHasFormula.
  ///
  /// In cs, this message translates to:
  /// **'Buňka {cell} obsahuje vzorec, nebyla přepsána.'**
  String issueCellHasFormula(String cell);

  /// No description provided for @issueSheetsUnavailable.
  ///
  /// In cs, this message translates to:
  /// **'Google Sheets je dočasně nedostupné.'**
  String get issueSheetsUnavailable;

  /// No description provided for @issueHcNotAvailable.
  ///
  /// In cs, this message translates to:
  /// **'Health Connect není nainstalovaný nebo potřebuje aktualizaci.'**
  String get issueHcNotAvailable;

  /// No description provided for @issueHcPermissionMissing.
  ///
  /// In cs, this message translates to:
  /// **'Chybí oprávnění Health Connect: {types}.'**
  String issueHcPermissionMissing(String types);

  /// No description provided for @issueHcHistoryPermissionMissing.
  ///
  /// In cs, this message translates to:
  /// **'Data starší než 30 dní vyžadují oprávnění ke čtení historie.'**
  String get issueHcHistoryPermissionMissing;

  /// No description provided for @issueHcBackgroundPermissionMissing.
  ///
  /// In cs, this message translates to:
  /// **'Automatická synchronizace nemá oprávnění číst Health Connect na pozadí.'**
  String get issueHcBackgroundPermissionMissing;

  /// No description provided for @issueHcReadFailed.
  ///
  /// In cs, this message translates to:
  /// **'Health Connect pro {date} nevrátil data.'**
  String issueHcReadFailed(String date);

  /// No description provided for @issueNoData.
  ///
  /// In cs, this message translates to:
  /// **'V {source} nejsou pro {date} žádná data. Buňky zůstaly beze změny.'**
  String issueNoData(String source, String date);

  /// No description provided for @issueOffline.
  ///
  /// In cs, this message translates to:
  /// **'Synchronizace vyžaduje připojení k internetu.'**
  String get issueOffline;

  /// No description provided for @issueUnexpected.
  ///
  /// In cs, this message translates to:
  /// **'Synchronizace se nezdařila z neočekávaného důvodu.'**
  String get issueUnexpected;

  /// No description provided for @actionOpenSettings.
  ///
  /// In cs, this message translates to:
  /// **'Otevřít nastavení'**
  String get actionOpenSettings;

  /// No description provided for @actionInstallHealthConnect.
  ///
  /// In cs, this message translates to:
  /// **'Nainstalovat / aktualizovat'**
  String get actionInstallHealthConnect;

  /// No description provided for @actionGrantPermissions.
  ///
  /// In cs, this message translates to:
  /// **'Udělit oprávnění'**
  String get actionGrantPermissions;

  /// No description provided for @actionConnectGoogle.
  ///
  /// In cs, this message translates to:
  /// **'Připojit Google účet'**
  String get actionConnectGoogle;

  /// No description provided for @actionReconnectGoogle.
  ///
  /// In cs, this message translates to:
  /// **'Znovu připojit'**
  String get actionReconnectGoogle;

  /// No description provided for @actionRetry.
  ///
  /// In cs, this message translates to:
  /// **'Zkusit znovu'**
  String get actionRetry;

  /// No description provided for @settingsHcHistory.
  ///
  /// In cs, this message translates to:
  /// **'Oprávnění ke čtení historie'**
  String get settingsHcHistory;

  /// No description provided for @settingsHcHistoryGranted.
  ///
  /// In cs, this message translates to:
  /// **'Čtení historie starší než 30 dní je povolené.'**
  String get settingsHcHistoryGranted;

  /// No description provided for @settingsHcHistoryUnavailable.
  ///
  /// In cs, this message translates to:
  /// **'Tato verze Health Connect čtení historie nepodporuje.'**
  String get settingsHcHistoryUnavailable;

  /// No description provided for @settingsHcPriorityHint.
  ///
  /// In cs, this message translates to:
  /// **'Tip: v aplikaci Health Connect nastav prioritu zdrojů pro kroky, aby se nesčítaly z více zařízení.'**
  String get settingsHcPriorityHint;

  /// No description provided for @settingsHcAllGranted.
  ///
  /// In cs, this message translates to:
  /// **'Oprávnění ke čtení váhy a kroků jsou udělena.'**
  String get settingsHcAllGranted;

  /// No description provided for @ktEmailLabel.
  ///
  /// In cs, this message translates to:
  /// **'E-mail'**
  String get ktEmailLabel;

  /// No description provided for @ktPasswordLabel.
  ///
  /// In cs, this message translates to:
  /// **'Heslo'**
  String get ktPasswordLabel;

  /// No description provided for @ktLoginButton.
  ///
  /// In cs, this message translates to:
  /// **'Přihlásit a ověřit'**
  String get ktLoginButton;

  /// No description provided for @ktLogoutButton.
  ///
  /// In cs, this message translates to:
  /// **'Odhlásit'**
  String get ktLogoutButton;

  /// No description provided for @ktChangeCredentials.
  ///
  /// In cs, this message translates to:
  /// **'Změnit údaje'**
  String get ktChangeCredentials;

  /// No description provided for @ktCancel.
  ///
  /// In cs, this message translates to:
  /// **'Zrušit'**
  String get ktCancel;

  /// No description provided for @ktSignedInAs.
  ///
  /// In cs, this message translates to:
  /// **'Přihlášeno jako {email}'**
  String ktSignedInAs(String email);

  /// No description provided for @ktLoginSuccess.
  ///
  /// In cs, this message translates to:
  /// **'Přihlášení ověřeno.'**
  String get ktLoginSuccess;

  /// No description provided for @ktFieldsRequired.
  ///
  /// In cs, this message translates to:
  /// **'Vyplň e-mail i heslo.'**
  String get ktFieldsRequired;

  /// No description provided for @googleConnectedAs.
  ///
  /// In cs, this message translates to:
  /// **'Připojený účet: {email}'**
  String googleConnectedAs(String email);

  /// No description provided for @googleDisconnect.
  ///
  /// In cs, this message translates to:
  /// **'Odpojit'**
  String get googleDisconnect;

  /// No description provided for @googleWebClientMissing.
  ///
  /// In cs, this message translates to:
  /// **'V aplikaci chybí ID webového klienta Google, připojení nemusí fungovat.'**
  String get googleWebClientMissing;

  /// No description provided for @sheetUrlLabel.
  ///
  /// In cs, this message translates to:
  /// **'Odkaz nebo ID tabulky'**
  String get sheetUrlLabel;

  /// No description provided for @sheetTabLabel.
  ///
  /// In cs, this message translates to:
  /// **'Název listu'**
  String get sheetTabLabel;

  /// No description provided for @sheetSaveVerify.
  ///
  /// In cs, this message translates to:
  /// **'Uložit a ověřit'**
  String get sheetSaveVerify;

  /// No description provided for @sheetVerify.
  ///
  /// In cs, this message translates to:
  /// **'Ověřit'**
  String get sheetVerify;

  /// No description provided for @sheetInvalidId.
  ///
  /// In cs, this message translates to:
  /// **'Neplatný odkaz nebo ID tabulky.'**
  String get sheetInvalidId;

  /// No description provided for @sheetNeedsGoogle.
  ///
  /// In cs, this message translates to:
  /// **'Pro ověření nejdřív připoj Google účet.'**
  String get sheetNeedsGoogle;

  /// No description provided for @sheetVerifyResult.
  ///
  /// In cs, this message translates to:
  /// **'Týdenních tabulek: {weeks}, dní: {days} ({first} – {last}).'**
  String sheetVerifyResult(int weeks, int days, String first, String last);

  /// No description provided for @sheetVerifyNoDates.
  ///
  /// In cs, this message translates to:
  /// **'V listu nebyla nalezena žádná data.'**
  String get sheetVerifyNoDates;

  /// No description provided for @sheetEditAccessNote.
  ///
  /// In cs, this message translates to:
  /// **'Čtení ověřeno; oprávnění k úpravám se ověří při první synchronizaci.'**
  String get sheetEditAccessNote;

  /// No description provided for @sheetDuplicates.
  ///
  /// In cs, this message translates to:
  /// **'Pozor: {count} dní je v listu vícekrát ({first} – {last}, řádky {rows}). Tyto dny se nebudou synchronizovat, dokud duplicitu neodstraníš.'**
  String sheetDuplicates(int count, String first, String last, String rows);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['cs'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'cs':
      return AppLocalizationsCs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
