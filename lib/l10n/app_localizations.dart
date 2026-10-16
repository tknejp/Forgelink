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

  /// No description provided for @homeRangeSync.
  ///
  /// In cs, this message translates to:
  /// **'Synchronizovat období'**
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

  /// No description provided for @diagnosticsShow.
  ///
  /// In cs, this message translates to:
  /// **'Zobrazit záznamy ({count})'**
  String diagnosticsShow(int count);

  /// No description provided for @diagnosticsHide.
  ///
  /// In cs, this message translates to:
  /// **'Skrýt záznamy'**
  String get diagnosticsHide;

  /// No description provided for @homeIntegrationSheets.
  ///
  /// In cs, this message translates to:
  /// **'Google Sheets'**
  String get homeIntegrationSheets;

  /// No description provided for @homeFix.
  ///
  /// In cs, this message translates to:
  /// **'Opravit'**
  String get homeFix;

  /// No description provided for @whenToday.
  ///
  /// In cs, this message translates to:
  /// **'dnes {time}'**
  String whenToday(String time);

  /// No description provided for @whenYesterday.
  ///
  /// In cs, this message translates to:
  /// **'včera {time}'**
  String whenYesterday(String time);

  /// No description provided for @lastSuccessLine.
  ///
  /// In cs, this message translates to:
  /// **'Naposledy úspěšně: {when} · {trigger}'**
  String lastSuccessLine(String when, String trigger);

  /// No description provided for @triggerManualShort.
  ///
  /// In cs, this message translates to:
  /// **'ručně'**
  String get triggerManualShort;

  /// No description provided for @triggerBackgroundShort.
  ///
  /// In cs, this message translates to:
  /// **'na pozadí'**
  String get triggerBackgroundShort;

  /// No description provided for @syncProgress.
  ///
  /// In cs, this message translates to:
  /// **'Synchronizuji {done}/{total} · {date}'**
  String syncProgress(int done, int total, String date);

  /// No description provided for @syncProgressWriting.
  ///
  /// In cs, this message translates to:
  /// **'Zapisuji do tabulky…'**
  String get syncProgressWriting;

  /// No description provided for @runSuccess.
  ///
  /// In cs, this message translates to:
  /// **'Synchronizováno: {dates}.'**
  String runSuccess(String dates);

  /// No description provided for @runNothingToWrite.
  ///
  /// In cs, this message translates to:
  /// **'Pro {dates} nejsou žádná data. Tabulka zůstala beze změny.'**
  String runNothingToWrite(String dates);

  /// No description provided for @runPartial.
  ///
  /// In cs, this message translates to:
  /// **'Částečně synchronizováno: {dates}.'**
  String runPartial(String dates);

  /// No description provided for @runFailed.
  ///
  /// In cs, this message translates to:
  /// **'Synchronizace se nezdařila: {dates}.'**
  String runFailed(String dates);

  /// No description provided for @runDayWritten.
  ///
  /// In cs, this message translates to:
  /// **'zapsáno {fields}'**
  String runDayWritten(String fields);

  /// No description provided for @runDayUnchanged.
  ///
  /// In cs, this message translates to:
  /// **'beze změny {fields}'**
  String runDayUnchanged(String fields);

  /// No description provided for @runDayMissing.
  ///
  /// In cs, this message translates to:
  /// **'bez dat {fields}'**
  String runDayMissing(String fields);

  /// No description provided for @runDayFailed.
  ///
  /// In cs, this message translates to:
  /// **'nezapsáno {fields}'**
  String runDayFailed(String fields);

  /// No description provided for @detailsShow.
  ///
  /// In cs, this message translates to:
  /// **'Podrobnosti'**
  String get detailsShow;

  /// No description provided for @detailsHide.
  ///
  /// In cs, this message translates to:
  /// **'Skrýt podrobnosti'**
  String get detailsHide;

  /// No description provided for @fieldWeight.
  ///
  /// In cs, this message translates to:
  /// **'váha'**
  String get fieldWeight;

  /// No description provided for @fieldKcal.
  ///
  /// In cs, this message translates to:
  /// **'kcal'**
  String get fieldKcal;

  /// No description provided for @fieldProtein.
  ///
  /// In cs, this message translates to:
  /// **'bílkoviny'**
  String get fieldProtein;

  /// No description provided for @fieldCarbs.
  ///
  /// In cs, this message translates to:
  /// **'sacharidy'**
  String get fieldCarbs;

  /// No description provided for @fieldFat.
  ///
  /// In cs, this message translates to:
  /// **'tuky'**
  String get fieldFat;

  /// No description provided for @fieldFiber.
  ///
  /// In cs, this message translates to:
  /// **'vláknina'**
  String get fieldFiber;

  /// No description provided for @fieldSteps.
  ///
  /// In cs, this message translates to:
  /// **'kroky'**
  String get fieldSteps;

  /// No description provided for @outcomeWritten.
  ///
  /// In cs, this message translates to:
  /// **'Zapsáno'**
  String get outcomeWritten;

  /// No description provided for @outcomeUnchanged.
  ///
  /// In cs, this message translates to:
  /// **'Beze změny'**
  String get outcomeUnchanged;

  /// No description provided for @outcomeMissing.
  ///
  /// In cs, this message translates to:
  /// **'Bez dat'**
  String get outcomeMissing;

  /// No description provided for @outcomeSkippedFormula.
  ///
  /// In cs, this message translates to:
  /// **'Vzorec – přeskočeno'**
  String get outcomeSkippedFormula;

  /// No description provided for @outcomeFailed.
  ///
  /// In cs, this message translates to:
  /// **'Chyba'**
  String get outcomeFailed;

  /// No description provided for @dayNeverSynced.
  ///
  /// In cs, this message translates to:
  /// **'Tento den zatím nebyl synchronizován.'**
  String get dayNeverSynced;

  /// No description provided for @daySyncNow.
  ///
  /// In cs, this message translates to:
  /// **'Synchronizovat tento den'**
  String get daySyncNow;

  /// No description provided for @dayTodayWeightOnly.
  ///
  /// In cs, this message translates to:
  /// **'Dnes se synchronizuje jen váha.'**
  String get dayTodayWeightOnly;

  /// No description provided for @calendarHint.
  ///
  /// In cs, this message translates to:
  /// **'Klepni = synchronizovat · podrž = detail · podrž a táhni = období'**
  String get calendarHint;

  /// No description provided for @rangeTooLong.
  ///
  /// In cs, this message translates to:
  /// **'Období může mít nejvýše {max} dní.'**
  String rangeTooLong(int max);

  /// No description provided for @rangePickerHelp.
  ///
  /// In cs, this message translates to:
  /// **'Vyber období k synchronizaci'**
  String get rangePickerHelp;

  /// No description provided for @historyTitle.
  ///
  /// In cs, this message translates to:
  /// **'Historie synchronizací'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In cs, this message translates to:
  /// **'Zatím žádné synchronizace.'**
  String get historyEmpty;

  /// No description provided for @triggerQuick.
  ///
  /// In cs, this message translates to:
  /// **'Rychlá synchronizace'**
  String get triggerQuick;

  /// No description provided for @triggerCalendar.
  ///
  /// In cs, this message translates to:
  /// **'Kalendář'**
  String get triggerCalendar;

  /// No description provided for @triggerRange.
  ///
  /// In cs, this message translates to:
  /// **'Období'**
  String get triggerRange;

  /// No description provided for @triggerBackground.
  ///
  /// In cs, this message translates to:
  /// **'Na pozadí'**
  String get triggerBackground;

  /// No description provided for @runStatusSuccess.
  ///
  /// In cs, this message translates to:
  /// **'Hotovo'**
  String get runStatusSuccess;

  /// No description provided for @runStatusNoData.
  ///
  /// In cs, this message translates to:
  /// **'Bez dat'**
  String get runStatusNoData;

  /// No description provided for @runStatusPartial.
  ///
  /// In cs, this message translates to:
  /// **'Částečně'**
  String get runStatusPartial;

  /// No description provided for @runStatusFailed.
  ///
  /// In cs, this message translates to:
  /// **'Chyba'**
  String get runStatusFailed;

  /// No description provided for @openIssuesTitle.
  ///
  /// In cs, this message translates to:
  /// **'Vyžaduje pozornost'**
  String get openIssuesTitle;

  /// No description provided for @dismiss.
  ///
  /// In cs, this message translates to:
  /// **'Skrýt'**
  String get dismiss;

  /// No description provided for @historyCells.
  ///
  /// In cs, this message translates to:
  /// **'Zapsaných buněk: {count}'**
  String historyCells(int count);

  /// No description provided for @rangeConfirmTitle.
  ///
  /// In cs, this message translates to:
  /// **'Synchronizovat období?'**
  String get rangeConfirmTitle;

  /// No description provided for @rangeConfirmBody.
  ///
  /// In cs, this message translates to:
  /// **'{dates} · {count, plural, =1{1 den} few{{count} dny} other{{count} dní}}'**
  String rangeConfirmBody(String dates, int count);

  /// No description provided for @homeQuickSyncCaption.
  ///
  /// In cs, this message translates to:
  /// **'{yesterday} kompletně · {today} jen váha'**
  String homeQuickSyncCaption(String yesterday, String today);

  /// No description provided for @settingsHcBackground.
  ///
  /// In cs, this message translates to:
  /// **'Povolit čtení na pozadí'**
  String get settingsHcBackground;

  /// No description provided for @settingsHcBackgroundGranted.
  ///
  /// In cs, this message translates to:
  /// **'Čtení na pozadí je povolené – synchronizace doběhne, i když aplikaci opustíš.'**
  String get settingsHcBackgroundGranted;

  /// No description provided for @settingsHcBackgroundUnavailable.
  ///
  /// In cs, this message translates to:
  /// **'Tato verze Health Connect čtení na pozadí nepodporuje.'**
  String get settingsHcBackgroundUnavailable;

  /// No description provided for @syncServiceTitle.
  ///
  /// In cs, this message translates to:
  /// **'Forgelink synchronizuje…'**
  String get syncServiceTitle;

  /// No description provided for @syncServiceText.
  ///
  /// In cs, this message translates to:
  /// **'Zapisuji data do tabulky.'**
  String get syncServiceText;

  /// No description provided for @syncServiceChannel.
  ///
  /// In cs, this message translates to:
  /// **'Probíhající synchronizace'**
  String get syncServiceChannel;

  /// No description provided for @syncQueued.
  ///
  /// In cs, this message translates to:
  /// **'+{count} ve frontě'**
  String syncQueued(int count);

  /// No description provided for @homeQuickSyncLabel.
  ///
  /// In cs, this message translates to:
  /// **'Rychlá synchronizace včerejška'**
  String get homeQuickSyncLabel;

  /// No description provided for @autoSyncSwitch.
  ///
  /// In cs, this message translates to:
  /// **'Synchronizovat automaticky'**
  String get autoSyncSwitch;

  /// No description provided for @autoSyncDescription.
  ///
  /// In cs, this message translates to:
  /// **'Každý den kolem 0:30 (celý předchozí den) a 12:30 (dnešní váha) doplní poslední 3 dny. Android může běh o pár minut posunout, ruční synchronizace funguje vždy.'**
  String get autoSyncDescription;

  /// No description provided for @autoSyncLastRun.
  ///
  /// In cs, this message translates to:
  /// **'Poslední běh na pozadí: {when} · {status}'**
  String autoSyncLastRun(String when, String status);

  /// No description provided for @autoSyncNeverRan.
  ///
  /// In cs, this message translates to:
  /// **'Na pozadí zatím neběžela.'**
  String get autoSyncNeverRan;

  /// No description provided for @autoSyncBattery.
  ///
  /// In cs, this message translates to:
  /// **'Vypnout optimalizaci baterie'**
  String get autoSyncBattery;

  /// No description provided for @autoSyncBatteryOk.
  ///
  /// In cs, this message translates to:
  /// **'Optimalizace baterie je pro Forgelink vypnutá.'**
  String get autoSyncBatteryOk;

  /// No description provided for @autoSyncUnused.
  ///
  /// In cs, this message translates to:
  /// **'Otevřít nastavení aplikace'**
  String get autoSyncUnused;

  /// No description provided for @autoSyncUnusedHint.
  ///
  /// In cs, this message translates to:
  /// **'V nastavení aplikace vypni „Pozastavit aktivitu, pokud se aplikace nepoužívá“, jinak Android po delší době automatickou synchronizaci zastaví.'**
  String get autoSyncUnusedHint;

  /// No description provided for @autoSyncNeedsHcBackground.
  ///
  /// In cs, this message translates to:
  /// **'Health Connect na pozadí: povol „Čtení na pozadí“ v sekci Health Connect.'**
  String get autoSyncNeedsHcBackground;

  /// No description provided for @bgFailureTitle.
  ///
  /// In cs, this message translates to:
  /// **'Automatická synchronizace se nezdařila'**
  String get bgFailureTitle;

  /// No description provided for @bgChannelName.
  ///
  /// In cs, this message translates to:
  /// **'Výsledky synchronizace'**
  String get bgChannelName;

  /// No description provided for @diagnosticsBgTest.
  ///
  /// In cs, this message translates to:
  /// **'Test synchronizace na pozadí'**
  String get diagnosticsBgTest;

  /// No description provided for @diagnosticsBgTestScheduled.
  ///
  /// In cs, this message translates to:
  /// **'Spustí se za 10 s – teď můžeš aplikaci opustit.'**
  String get diagnosticsBgTestScheduled;

  /// No description provided for @bgSuccessTitle.
  ///
  /// In cs, this message translates to:
  /// **'Synchronizace dokončena'**
  String get bgSuccessTitle;

  /// No description provided for @bgSuccessBody.
  ///
  /// In cs, this message translates to:
  /// **'{dates}: zapsáno {count, plural, =1{1 hodnota} few{{count} hodnoty} other{{count} hodnot}}.'**
  String bgSuccessBody(String dates, int count);

  /// No description provided for @bgUpToDateBody.
  ///
  /// In cs, this message translates to:
  /// **'{dates}: vše už bylo aktuální.'**
  String bgUpToDateBody(String dates);

  /// No description provided for @bgPartialTitle.
  ///
  /// In cs, this message translates to:
  /// **'Synchronizace dokončena s problémy'**
  String get bgPartialTitle;

  /// No description provided for @bgManualHint.
  ///
  /// In cs, this message translates to:
  /// **'Otevři Forgelink a synchronizuj ručně.'**
  String get bgManualHint;

  /// No description provided for @autoSyncNextRun.
  ///
  /// In cs, this message translates to:
  /// **'Další běh: {when}'**
  String autoSyncNextRun(String when);

  /// No description provided for @autoSyncNotifySuccess.
  ///
  /// In cs, this message translates to:
  /// **'Oznámit i úspěšnou synchronizaci'**
  String get autoSyncNotifySuccess;

  /// No description provided for @whenTomorrow.
  ///
  /// In cs, this message translates to:
  /// **'zítra {time}'**
  String whenTomorrow(String time);

  /// No description provided for @issueDriveApiDisabled.
  ///
  /// In cs, this message translates to:
  /// **'Google Drive API není v projektu Google Cloud povolené.'**
  String get issueDriveApiDisabled;

  /// No description provided for @driveChooseButton.
  ///
  /// In cs, this message translates to:
  /// **'Vybrat z Google Disku'**
  String get driveChooseButton;

  /// No description provided for @driveChooserTitle.
  ///
  /// In cs, this message translates to:
  /// **'Vyber tabulku'**
  String get driveChooserTitle;

  /// No description provided for @driveSearchHint.
  ///
  /// In cs, this message translates to:
  /// **'Hledat podle názvu'**
  String get driveSearchHint;

  /// No description provided for @driveEmpty.
  ///
  /// In cs, this message translates to:
  /// **'Žádné tabulky nenalezeny.'**
  String get driveEmpty;

  /// No description provided for @driveReadOnly.
  ///
  /// In cs, this message translates to:
  /// **'Jen ke čtení'**
  String get driveReadOnly;

  /// No description provided for @driveOwnerModified.
  ///
  /// In cs, this message translates to:
  /// **'{owner} · upraveno {when}'**
  String driveOwnerModified(String owner, String when);

  /// No description provided for @homeQuickSyncTitle.
  ///
  /// In cs, this message translates to:
  /// **'Rychlá synchronizace'**
  String get homeQuickSyncTitle;

  /// No description provided for @homeLastSync.
  ///
  /// In cs, this message translates to:
  /// **'Naposledy {when}'**
  String homeLastSync(String when);

  /// No description provided for @homeLastSyncWith.
  ///
  /// In cs, this message translates to:
  /// **'{when} · {trigger}'**
  String homeLastSyncWith(String when, String trigger);

  /// No description provided for @qsYesterday.
  ///
  /// In cs, this message translates to:
  /// **'Včera · {date}'**
  String qsYesterday(String date);

  /// No description provided for @qsYesterdaySub.
  ///
  /// In cs, this message translates to:
  /// **'Výživa a kroky'**
  String get qsYesterdaySub;

  /// No description provided for @qsToday.
  ///
  /// In cs, this message translates to:
  /// **'Dnes · {date}'**
  String qsToday(String date);

  /// No description provided for @qsTodaySub.
  ///
  /// In cs, this message translates to:
  /// **'Váha {value}'**
  String qsTodaySub(String value);

  /// No description provided for @qsTodaySubNone.
  ///
  /// In cs, this message translates to:
  /// **'Jen váha'**
  String get qsTodaySubNone;

  /// No description provided for @chipInSheet.
  ///
  /// In cs, this message translates to:
  /// **'V tabulce'**
  String get chipInSheet;

  /// No description provided for @chipToWrite.
  ///
  /// In cs, this message translates to:
  /// **'Ke zápisu'**
  String get chipToWrite;

  /// No description provided for @chipNutritionMissing.
  ///
  /// In cs, this message translates to:
  /// **'Výživa chybí'**
  String get chipNutritionMissing;

  /// No description provided for @chipError.
  ///
  /// In cs, this message translates to:
  /// **'Chyba'**
  String get chipError;

  /// No description provided for @chipNoData.
  ///
  /// In cs, this message translates to:
  /// **'Bez dat'**
  String get chipNoData;

  /// No description provided for @calendarRangeButton.
  ///
  /// In cs, this message translates to:
  /// **'Období'**
  String get calendarRangeButton;

  /// No description provided for @legendFull.
  ///
  /// In cs, this message translates to:
  /// **'Kompletní'**
  String get legendFull;

  /// No description provided for @legendPartial.
  ///
  /// In cs, this message translates to:
  /// **'Částečně'**
  String get legendPartial;

  /// No description provided for @legendMissing.
  ///
  /// In cs, this message translates to:
  /// **'Chybí'**
  String get legendMissing;

  /// No description provided for @legendFailed.
  ///
  /// In cs, this message translates to:
  /// **'Chyba'**
  String get legendFailed;

  /// No description provided for @homeNeedsSetup.
  ///
  /// In cs, this message translates to:
  /// **'Nenastaveno'**
  String get homeNeedsSetup;

  /// No description provided for @syncSheetRunning.
  ///
  /// In cs, this message translates to:
  /// **'Synchronizuji…'**
  String get syncSheetRunning;

  /// No description provided for @syncSheetDone.
  ///
  /// In cs, this message translates to:
  /// **'Hotovo'**
  String get syncSheetDone;

  /// No description provided for @syncSheetWarn.
  ///
  /// In cs, this message translates to:
  /// **'Hotovo s upozorněním'**
  String get syncSheetWarn;

  /// No description provided for @syncSheetFailed.
  ///
  /// In cs, this message translates to:
  /// **'Synchronizace selhala'**
  String get syncSheetFailed;

  /// No description provided for @syncSheetNoData.
  ///
  /// In cs, this message translates to:
  /// **'Žádná nová data'**
  String get syncSheetNoData;

  /// No description provided for @syncSheetSub.
  ///
  /// In cs, this message translates to:
  /// **'{label} · {count, plural, =1{1 den} few{{count} dny} other{{count} dní}}'**
  String syncSheetSub(String label, int count);

  /// No description provided for @syncRowWaiting.
  ///
  /// In cs, this message translates to:
  /// **'Čeká'**
  String get syncRowWaiting;

  /// No description provided for @syncRowReading.
  ///
  /// In cs, this message translates to:
  /// **'Čtu Health Connect a Kalorické tabulky…'**
  String get syncRowReading;

  /// No description provided for @syncRowRead.
  ///
  /// In cs, this message translates to:
  /// **'Načteno'**
  String get syncRowRead;

  /// No description provided for @syncRowWriting.
  ///
  /// In cs, this message translates to:
  /// **'Zapisuji do tabulky…'**
  String get syncRowWriting;

  /// No description provided for @syncRowResult.
  ///
  /// In cs, this message translates to:
  /// **'{written, plural, =1{1 nová} few{{written} nové} other{{written} nových}} · {unchanged} beze změny'**
  String syncRowResult(int written, int unchanged);

  /// No description provided for @syncRowNutritionMissing.
  ///
  /// In cs, this message translates to:
  /// **'výživa chybí'**
  String get syncRowNutritionMissing;

  /// No description provided for @syncRowRestAfterMidnight.
  ///
  /// In cs, this message translates to:
  /// **'zbytek po půlnoci'**
  String get syncRowRestAfterMidnight;

  /// No description provided for @syncRowNoData.
  ///
  /// In cs, this message translates to:
  /// **'Ve zdrojích nejsou data'**
  String get syncRowNoData;

  /// No description provided for @syncMoreDays.
  ///
  /// In cs, this message translates to:
  /// **'+ {count} dalších'**
  String syncMoreDays(int count);

  /// No description provided for @actionClose.
  ///
  /// In cs, this message translates to:
  /// **'Zavřít'**
  String get actionClose;

  /// No description provided for @actionOpenSheet.
  ///
  /// In cs, this message translates to:
  /// **'Otevřít tabulku'**
  String get actionOpenSheet;

  /// No description provided for @fieldLabelWeight.
  ///
  /// In cs, this message translates to:
  /// **'Váha'**
  String get fieldLabelWeight;

  /// No description provided for @fieldLabelSteps.
  ///
  /// In cs, this message translates to:
  /// **'Kroky'**
  String get fieldLabelSteps;

  /// No description provided for @fieldLabelKcal.
  ///
  /// In cs, this message translates to:
  /// **'Energie'**
  String get fieldLabelKcal;

  /// No description provided for @fieldLabelProtein.
  ///
  /// In cs, this message translates to:
  /// **'Bílkoviny'**
  String get fieldLabelProtein;

  /// No description provided for @fieldLabelCarbs.
  ///
  /// In cs, this message translates to:
  /// **'Sacharidy'**
  String get fieldLabelCarbs;

  /// No description provided for @fieldLabelFat.
  ///
  /// In cs, this message translates to:
  /// **'Tuky'**
  String get fieldLabelFat;

  /// No description provided for @fieldLabelFiber.
  ///
  /// In cs, this message translates to:
  /// **'Vláknina'**
  String get fieldLabelFiber;

  /// No description provided for @cellInSheet.
  ///
  /// In cs, this message translates to:
  /// **'V tabulce'**
  String get cellInSheet;

  /// No description provided for @cellToWrite.
  ///
  /// In cs, this message translates to:
  /// **'Ke zápisu'**
  String get cellToWrite;

  /// No description provided for @cellMissing.
  ///
  /// In cs, this message translates to:
  /// **'Chybí ve zdroji'**
  String get cellMissing;

  /// No description provided for @cellAfterMidnight.
  ///
  /// In cs, this message translates to:
  /// **'Po půlnoci'**
  String get cellAfterMidnight;

  /// No description provided for @cellFormula.
  ///
  /// In cs, this message translates to:
  /// **'Vzorec'**
  String get cellFormula;

  /// No description provided for @cellFailed.
  ///
  /// In cs, this message translates to:
  /// **'Chyba'**
  String get cellFailed;

  /// No description provided for @dayChipFull.
  ///
  /// In cs, this message translates to:
  /// **'Kompletní'**
  String get dayChipFull;

  /// No description provided for @dayChipPartial.
  ///
  /// In cs, this message translates to:
  /// **'Částečně'**
  String get dayChipPartial;

  /// No description provided for @dayChipNone.
  ///
  /// In cs, this message translates to:
  /// **'Nesynchronizováno'**
  String get dayChipNone;

  /// No description provided for @dayChipFailed.
  ///
  /// In cs, this message translates to:
  /// **'Chyba'**
  String get dayChipFailed;

  /// No description provided for @dayChipNoData.
  ///
  /// In cs, this message translates to:
  /// **'Bez dat'**
  String get dayChipNoData;

  /// No description provided for @daySheetTab.
  ///
  /// In cs, this message translates to:
  /// **'List {tab}'**
  String daySheetTab(String tab);

  /// No description provided for @dayTodaySuffix.
  ///
  /// In cs, this message translates to:
  /// **'{title} · dnes'**
  String dayTodaySuffix(String title);

  /// No description provided for @dayTodayNote.
  ///
  /// In cs, this message translates to:
  /// **'Den ještě neskončil. Výživa a kroky se zapíšou po půlnoci, teď lze zapsat jen váhu.'**
  String get dayTodayNote;

  /// No description provided for @lockNoteManual.
  ///
  /// In cs, this message translates to:
  /// **'Hlad, hydratace, trénink a poznámky zůstanou beze změny.'**
  String get lockNoteManual;

  /// No description provided for @daySyncFirst.
  ///
  /// In cs, this message translates to:
  /// **'Synchronizovat den'**
  String get daySyncFirst;

  /// No description provided for @dayUpdate.
  ///
  /// In cs, this message translates to:
  /// **'Aktualizovat den'**
  String get dayUpdate;

  /// No description provided for @rangePreset3.
  ///
  /// In cs, this message translates to:
  /// **'Poslední 3 dny'**
  String get rangePreset3;

  /// No description provided for @rangePreset7.
  ///
  /// In cs, this message translates to:
  /// **'Posledních 7 dní'**
  String get rangePreset7;

  /// No description provided for @rangePresetMonth.
  ///
  /// In cs, this message translates to:
  /// **'Tento měsíc'**
  String get rangePresetMonth;

  /// No description provided for @rangeLockNote.
  ///
  /// In cs, this message translates to:
  /// **'Existující hodnoty se jen aktualizují. Hlad, hydratace, trénink a poznámky zůstanou beze změny.'**
  String get rangeLockNote;

  /// No description provided for @rangePickFirst.
  ///
  /// In cs, this message translates to:
  /// **'Vyber první a poslední den'**
  String get rangePickFirst;

  /// No description provided for @rangePickEnd.
  ///
  /// In cs, this message translates to:
  /// **'{date} · klepni na konec období'**
  String rangePickEnd(String date);

  /// No description provided for @rangeSummary.
  ///
  /// In cs, this message translates to:
  /// **'{from} – {to} · {count, plural, =1{1 den} few{{count} dny} other{{count} dní}}'**
  String rangeSummary(String from, String to, int count);

  /// No description provided for @rangeButton.
  ///
  /// In cs, this message translates to:
  /// **'Synchronizovat {count, plural, =1{1 den} few{{count} dny} other{{count} dní}}'**
  String rangeButton(int count);

  /// No description provided for @monthPrev.
  ///
  /// In cs, this message translates to:
  /// **'Předchozí měsíc'**
  String get monthPrev;

  /// No description provided for @monthNext.
  ///
  /// In cs, this message translates to:
  /// **'Další měsíc'**
  String get monthNext;

  /// No description provided for @settingsGroupSources.
  ///
  /// In cs, this message translates to:
  /// **'Zdroje dat'**
  String get settingsGroupSources;

  /// No description provided for @settingsGroupTarget.
  ///
  /// In cs, this message translates to:
  /// **'Cíl'**
  String get settingsGroupTarget;

  /// No description provided for @settingsGroupOther.
  ///
  /// In cs, this message translates to:
  /// **'Ostatní'**
  String get settingsGroupOther;

  /// No description provided for @rowReads.
  ///
  /// In cs, this message translates to:
  /// **'Čte'**
  String get rowReads;

  /// No description provided for @hcReadsValue.
  ///
  /// In cs, this message translates to:
  /// **'Váhu a kroky'**
  String get hcReadsValue;

  /// No description provided for @rowHistory.
  ///
  /// In cs, this message translates to:
  /// **'Starší data'**
  String get rowHistory;

  /// No description provided for @rowBackground.
  ///
  /// In cs, this message translates to:
  /// **'Na pozadí'**
  String get rowBackground;

  /// No description provided for @valueAllowed.
  ///
  /// In cs, this message translates to:
  /// **'Povoleno'**
  String get valueAllowed;

  /// No description provided for @valueNotAllowed.
  ///
  /// In cs, this message translates to:
  /// **'Nepovoleno'**
  String get valueNotAllowed;

  /// No description provided for @valueUnsupported.
  ///
  /// In cs, this message translates to:
  /// **'Nepodporováno'**
  String get valueUnsupported;

  /// No description provided for @hcGrantHistoryShort.
  ///
  /// In cs, this message translates to:
  /// **'Povolit starší data'**
  String get hcGrantHistoryShort;

  /// No description provided for @hcGrantBackgroundShort.
  ///
  /// In cs, this message translates to:
  /// **'Povolit na pozadí'**
  String get hcGrantBackgroundShort;

  /// No description provided for @rowAccount.
  ///
  /// In cs, this message translates to:
  /// **'Účet'**
  String get rowAccount;

  /// No description provided for @ktReadsValue.
  ///
  /// In cs, this message translates to:
  /// **'Energii, makra, vlákninu'**
  String get ktReadsValue;

  /// No description provided for @ktLoginShort.
  ///
  /// In cs, this message translates to:
  /// **'Přihlásit'**
  String get ktLoginShort;

  /// No description provided for @rowAccess.
  ///
  /// In cs, this message translates to:
  /// **'Přístup'**
  String get rowAccess;

  /// No description provided for @googleAccessValue.
  ///
  /// In cs, this message translates to:
  /// **'Tabulky, vybrané soubory'**
  String get googleAccessValue;

  /// No description provided for @googleConnect.
  ///
  /// In cs, this message translates to:
  /// **'Připojit'**
  String get googleConnect;

  /// No description provided for @rowSheetId.
  ///
  /// In cs, this message translates to:
  /// **'ID'**
  String get rowSheetId;

  /// No description provided for @rowTab.
  ///
  /// In cs, this message translates to:
  /// **'List'**
  String get rowTab;

  /// No description provided for @rowCoverage.
  ///
  /// In cs, this message translates to:
  /// **'Rozsah'**
  String get rowCoverage;

  /// No description provided for @sheetCoverage.
  ///
  /// In cs, this message translates to:
  /// **'Týdnů: {weeks} · {first} – {last}'**
  String sheetCoverage(int weeks, String first, String last);

  /// No description provided for @sheetPickDrive.
  ///
  /// In cs, this message translates to:
  /// **'Vybrat z Disku'**
  String get sheetPickDrive;

  /// No description provided for @sheetEditManual.
  ///
  /// In cs, this message translates to:
  /// **'Upravit ručně'**
  String get sheetEditManual;

  /// No description provided for @sheetEditTitle.
  ///
  /// In cs, this message translates to:
  /// **'Upravit tabulku'**
  String get sheetEditTitle;

  /// No description provided for @autoSyncSub.
  ///
  /// In cs, this message translates to:
  /// **'Denně 0:30 a 12:30 · doplní poslední 3 dny'**
  String get autoSyncSub;

  /// No description provided for @notifySuccessSub.
  ///
  /// In cs, this message translates to:
  /// **'Notifikace po každém běhu, nejen při chybě'**
  String get notifySuccessSub;

  /// No description provided for @rowNextRun.
  ///
  /// In cs, this message translates to:
  /// **'Další běh'**
  String get rowNextRun;

  /// No description provided for @rowLastRun.
  ///
  /// In cs, this message translates to:
  /// **'Poslední běh'**
  String get rowLastRun;

  /// No description provided for @rowBattery.
  ///
  /// In cs, this message translates to:
  /// **'Baterie'**
  String get rowBattery;

  /// No description provided for @batteryOk.
  ///
  /// In cs, this message translates to:
  /// **'Optimalizace vypnutá'**
  String get batteryOk;

  /// No description provided for @batteryOn.
  ///
  /// In cs, this message translates to:
  /// **'Optimalizace zapnutá'**
  String get batteryOn;

  /// No description provided for @valueOff.
  ///
  /// In cs, this message translates to:
  /// **'vypnuto'**
  String get valueOff;

  /// No description provided for @valueNever.
  ///
  /// In cs, this message translates to:
  /// **'zatím ne'**
  String get valueNever;

  /// No description provided for @autoSyncDelayHint.
  ///
  /// In cs, this message translates to:
  /// **'Android může běh o pár minut posunout. Aby ho po delší době nezastavil, vypni v nastavení aplikace „Pozastavit aktivitu, pokud se aplikace nepoužívá“.'**
  String get autoSyncDelayHint;

  /// No description provided for @appSettingsButton.
  ///
  /// In cs, this message translates to:
  /// **'Nastavení aplikace'**
  String get appSettingsButton;

  /// No description provided for @batteryButton.
  ///
  /// In cs, this message translates to:
  /// **'Vypnout optimalizaci'**
  String get batteryButton;

  /// No description provided for @diagnosticsCount.
  ///
  /// In cs, this message translates to:
  /// **'{count, plural, =1{1 záznam} few{{count} záznamy} other{{count} záznamů}}'**
  String diagnosticsCount(int count);

  /// No description provided for @settingsFooter.
  ///
  /// In cs, this message translates to:
  /// **'Forgelink {version} · data zůstávají v telefonu'**
  String settingsFooter(String version);

  /// No description provided for @historyFilterAll.
  ///
  /// In cs, this message translates to:
  /// **'Vše'**
  String get historyFilterAll;

  /// No description provided for @historyFilterManual.
  ///
  /// In cs, this message translates to:
  /// **'Ručně'**
  String get historyFilterManual;

  /// No description provided for @historyFilterBackground.
  ///
  /// In cs, this message translates to:
  /// **'Na pozadí'**
  String get historyFilterBackground;

  /// No description provided for @historyFilterIssues.
  ///
  /// In cs, this message translates to:
  /// **'Problémy'**
  String get historyFilterIssues;

  /// No description provided for @historyFilterEmpty.
  ///
  /// In cs, this message translates to:
  /// **'Žádné záznamy v tomto filtru.'**
  String get historyFilterEmpty;

  /// No description provided for @historyToday.
  ///
  /// In cs, this message translates to:
  /// **'Dnes'**
  String get historyToday;

  /// No description provided for @historyYesterday.
  ///
  /// In cs, this message translates to:
  /// **'Včera'**
  String get historyYesterday;

  /// No description provided for @diagFilterAll.
  ///
  /// In cs, this message translates to:
  /// **'Vše'**
  String get diagFilterAll;

  /// No description provided for @diagFilterIssues.
  ///
  /// In cs, this message translates to:
  /// **'Upozornění a chyby'**
  String get diagFilterIssues;

  /// No description provided for @diagBgTestShort.
  ///
  /// In cs, this message translates to:
  /// **'Test na pozadí'**
  String get diagBgTestShort;

  /// No description provided for @onbWelcomeText.
  ///
  /// In cs, this message translates to:
  /// **'Přenese váhu, kroky a výživu do tabulky tvého trenéra. Jedním klepnutím nebo samo každý den.'**
  String get onbWelcomeText;

  /// No description provided for @onbSourceHcSub.
  ///
  /// In cs, this message translates to:
  /// **'Váha a kroky'**
  String get onbSourceHcSub;

  /// No description provided for @onbSourceKtSub.
  ///
  /// In cs, this message translates to:
  /// **'Energie, makra, vláknina'**
  String get onbSourceKtSub;

  /// No description provided for @onbSourceSheets.
  ///
  /// In cs, this message translates to:
  /// **'Google Sheets'**
  String get onbSourceSheets;

  /// No description provided for @onbSourceSheetsSub.
  ///
  /// In cs, this message translates to:
  /// **'Tabulka trenéra'**
  String get onbSourceSheetsSub;

  /// No description provided for @onbLocalNote.
  ///
  /// In cs, this message translates to:
  /// **'Vše běží v telefonu. Žádný server ani další účet.'**
  String get onbLocalNote;

  /// No description provided for @onbStart.
  ///
  /// In cs, this message translates to:
  /// **'Začít nastavení'**
  String get onbStart;

  /// No description provided for @onbContinue.
  ///
  /// In cs, this message translates to:
  /// **'Pokračovat'**
  String get onbContinue;

  /// No description provided for @onbSkip.
  ///
  /// In cs, this message translates to:
  /// **'Přeskočit'**
  String get onbSkip;

  /// No description provided for @onbInstallHc.
  ///
  /// In cs, this message translates to:
  /// **'Nainstalovat Health Connect'**
  String get onbInstallHc;

  /// No description provided for @onbHcText.
  ///
  /// In cs, this message translates to:
  /// **'Forgelink bude jen číst. Nic nezapisuje ani nemaže.'**
  String get onbHcText;

  /// No description provided for @onbPermWeightSub.
  ///
  /// In cs, this message translates to:
  /// **'Pro zápis dnešní váhy'**
  String get onbPermWeightSub;

  /// No description provided for @onbPermStepsSub.
  ///
  /// In cs, this message translates to:
  /// **'Denní součet'**
  String get onbPermStepsSub;

  /// No description provided for @onbPermHistory.
  ///
  /// In cs, this message translates to:
  /// **'Starší data'**
  String get onbPermHistory;

  /// No description provided for @onbPermHistorySub.
  ///
  /// In cs, this message translates to:
  /// **'Pro opravu dnů starších 30 dní'**
  String get onbPermHistorySub;

  /// No description provided for @onbPermBackground.
  ///
  /// In cs, this message translates to:
  /// **'Čtení na pozadí'**
  String get onbPermBackground;

  /// No description provided for @onbPermBackgroundSub.
  ///
  /// In cs, this message translates to:
  /// **'Pro automatickou synchronizaci'**
  String get onbPermBackgroundSub;

  /// No description provided for @onbKtText.
  ///
  /// In cs, this message translates to:
  /// **'Přihlas se stejným účtem jako v aplikaci. Údaje zůstanou uložené jen v telefonu.'**
  String get onbKtText;

  /// No description provided for @onbKtOk.
  ///
  /// In cs, this message translates to:
  /// **'Přihlášeno a ověřeno'**
  String get onbKtOk;

  /// No description provided for @onbEmailHint.
  ///
  /// In cs, this message translates to:
  /// **'jmeno@email.cz'**
  String get onbEmailHint;

  /// No description provided for @onbSheetTitle.
  ///
  /// In cs, this message translates to:
  /// **'Tabulka trenéra'**
  String get onbSheetTitle;

  /// No description provided for @onbSheetText.
  ///
  /// In cs, this message translates to:
  /// **'Přihlas se ke Googlu a vyber tabulku. Forgelink najde řádek podle data a vyplní jen svoje sloupce.'**
  String get onbSheetText;

  /// No description provided for @onbGoogleNotConnected.
  ///
  /// In cs, this message translates to:
  /// **'Nepřihlášeno'**
  String get onbGoogleNotConnected;

  /// No description provided for @onbGoogleAccess.
  ///
  /// In cs, this message translates to:
  /// **'Přístup k vybraným tabulkám'**
  String get onbGoogleAccess;

  /// No description provided for @onbSheetNone.
  ///
  /// In cs, this message translates to:
  /// **'Nevybráno'**
  String get onbSheetNone;

  /// No description provided for @onbSheetOk.
  ///
  /// In cs, this message translates to:
  /// **'List {tab} · ověřeno'**
  String onbSheetOk(String tab);

  /// No description provided for @onbGoogleButton.
  ///
  /// In cs, this message translates to:
  /// **'Přihlásit přes Google'**
  String get onbGoogleButton;

  /// No description provided for @onbPickSheet.
  ///
  /// In cs, this message translates to:
  /// **'Vybrat tabulku'**
  String get onbPickSheet;

  /// No description provided for @onbDoneTitle.
  ///
  /// In cs, this message translates to:
  /// **'Vše připraveno'**
  String get onbDoneTitle;

  /// No description provided for @onbDoneText.
  ///
  /// In cs, this message translates to:
  /// **'Každý den kolem 0:30 se zapíše celý předchozí den, ve 12:30 dnešní váha.'**
  String get onbDoneText;

  /// No description provided for @onbFinish.
  ///
  /// In cs, this message translates to:
  /// **'Přejít na přehled'**
  String get onbFinish;

  /// No description provided for @actionBack.
  ///
  /// In cs, this message translates to:
  /// **'Zpět'**
  String get actionBack;

  /// No description provided for @syncButtonProgress.
  ///
  /// In cs, this message translates to:
  /// **'Synchronizuji {done}/{total}'**
  String syncButtonProgress(int done, int total);

  /// No description provided for @syncButtonWriting.
  ///
  /// In cs, this message translates to:
  /// **'Zapisuji…'**
  String get syncButtonWriting;

  /// No description provided for @syncButtonDone.
  ///
  /// In cs, this message translates to:
  /// **'Hotovo'**
  String get syncButtonDone;

  /// No description provided for @daySheetTabRead.
  ///
  /// In cs, this message translates to:
  /// **'List {tab} · stav z tabulky {when}'**
  String daySheetTabRead(String tab, String when);

  /// No description provided for @rowSheetFile.
  ///
  /// In cs, this message translates to:
  /// **'Soubor'**
  String get rowSheetFile;

  /// No description provided for @waitTitle.
  ///
  /// In cs, this message translates to:
  /// **'Čeká na připojení'**
  String get waitTitle;

  /// No description provided for @waitSub.
  ///
  /// In cs, this message translates to:
  /// **'Dokončí se samo · {count, plural, =1{1 den} few{{count} dny} other{{count} dní}}'**
  String waitSub(int count);

  /// No description provided for @waitNow.
  ///
  /// In cs, this message translates to:
  /// **'Zkusit teď'**
  String get waitNow;

  /// No description provided for @chipWaiting.
  ///
  /// In cs, this message translates to:
  /// **'Čeká'**
  String get chipWaiting;

  /// No description provided for @syncRowWaitingNet.
  ///
  /// In cs, this message translates to:
  /// **'Čeká na připojení'**
  String get syncRowWaitingNet;

  /// No description provided for @syncSheetWaitingNote.
  ///
  /// In cs, this message translates to:
  /// **'Až bude připojení, synchronizace se dokončí sama a dá vědět notifikací.'**
  String get syncSheetWaitingNote;

  /// No description provided for @dayWaitingNote.
  ///
  /// In cs, this message translates to:
  /// **'Poslední pokus se nepovedl kvůli připojení. Den se zkusí znovu sám.'**
  String get dayWaitingNote;
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
