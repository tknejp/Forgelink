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
  /// **'Zhruba dvakrát denně doplní poslední 3 dny a dnešní váhu. Android může běh posunout, ruční synchronizace funguje vždy.'**
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
  /// **'Problémy se synchronizací'**
  String get bgChannelName;
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
