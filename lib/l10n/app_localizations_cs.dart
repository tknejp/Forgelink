// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get settingsTitle => 'Nastavení';

  @override
  String get homeIntegrationsTitle => 'Propojení';

  @override
  String get homeAllConnected => 'Vše připojeno';

  @override
  String get homeNotConfiguredYet => 'Aplikace zatím není nastavená.';

  @override
  String get homeOpenSettings => 'Otevřít nastavení';

  @override
  String get homeLastSyncTitle => 'Poslední synchronizace';

  @override
  String get homeLastSyncNever => 'Zatím neproběhla žádná synchronizace.';

  @override
  String get homeQuickSyncButton => 'Synchronizovat';

  @override
  String get homeQuickSyncSubtitle => 'Včera: výživa a kroky · Dnes: váha';

  @override
  String get homeCalendarTitle => 'Kalendář';

  @override
  String get homeComingSoon => 'Bude doplněno v další fázi.';

  @override
  String get homeAdvancedTitle => 'Další možnosti';

  @override
  String get homeRangeSync => 'Synchronizovat období…';

  @override
  String get homeHistory => 'Historie synchronizací';

  @override
  String get settingsSectionHealthConnect => 'Health Connect';

  @override
  String get settingsSectionKt => 'Kalorické tabulky';

  @override
  String get settingsSectionGoogle => 'Google účet';

  @override
  String get settingsSectionSheet => 'Tabulka';

  @override
  String get settingsSectionAutoSync => 'Automatická synchronizace';

  @override
  String get settingsSectionDiagnostics => 'Diagnostika';

  @override
  String get statusNotConfigured => 'Nenastaveno';

  @override
  String get statusConfigured => 'Nastaveno';

  @override
  String get statusReadVerified => 'Čtení ověřeno';

  @override
  String get statusVerified => 'Ověřeno';

  @override
  String get statusError => 'Chyba';

  @override
  String get settingsOpenHealthConnect => 'Otevřít Health Connect';

  @override
  String get settingsAutoSyncLater =>
      'Automatická synchronizace přibude v pozdější fázi.';

  @override
  String get diagnosticsEmpty => 'Žádné záznamy.';

  @override
  String get diagnosticsCopy => 'Kopírovat';

  @override
  String get diagnosticsCopied => 'Zkopírováno do schránky.';

  @override
  String get diagnosticsClear => 'Vymazat';

  @override
  String get dataSourceHealthConnect => 'Health Connect';

  @override
  String get dataSourceKt => 'Kalorických tabulkách';

  @override
  String get hcTypeSteps => 'kroky';

  @override
  String get hcTypeWeight => 'váha';

  @override
  String get issueKtCredentialsMissing =>
      'Chybí přihlašovací údaje ke Kalorickým tabulkám.';

  @override
  String get issueKtAuthRejected =>
      'Přihlášení do Kalorických tabulek se nezdařilo. Zkontroluj e-mail a heslo.';

  @override
  String get issueKtUnavailable => 'Kalorické tabulky teď neodpovídají.';

  @override
  String get issueGoogleNotConnected => 'Google účet není připojený.';

  @override
  String get issueGoogleReauthRequired => 'Přihlášení ke Googlu vypršelo.';

  @override
  String get issueSheetNotConfigured => 'Není nastavená cílová tabulka.';

  @override
  String get issueSheetNotFound =>
      'Tabulka nebyla nalezena. Zkontroluj odkaz v nastavení.';

  @override
  String issueSheetNoEditAccess(String email) {
    return 'Účet $email nemá oprávnění tabulku upravovat.';
  }

  @override
  String get issueSheetsApiDisabled =>
      'Google Sheets API není v projektu Google Cloud povolené.';

  @override
  String issueSheetTabMissing(String tab) {
    return 'V tabulce chybí list „$tab“.';
  }

  @override
  String issueSheetLayoutChanged(String tab) {
    return 'Rozvržení listu „$tab“ se změnilo. Nic nebylo zapsáno.';
  }

  @override
  String issueDateNotInSheet(String date) {
    return 'Datum $date v tabulce není. Nic nebylo zapsáno.';
  }

  @override
  String issueDateDuplicated(String date, String rows) {
    return 'Datum $date je v tabulce vícekrát (řádky $rows). Nic nebylo zapsáno.';
  }

  @override
  String issueCellHasFormula(String cell) {
    return 'Buňka $cell obsahuje vzorec, nebyla přepsána.';
  }

  @override
  String get issueSheetsUnavailable => 'Google Sheets je dočasně nedostupné.';

  @override
  String get issueHcNotAvailable =>
      'Health Connect není nainstalovaný nebo potřebuje aktualizaci.';

  @override
  String issueHcPermissionMissing(String types) {
    return 'Chybí oprávnění Health Connect: $types.';
  }

  @override
  String get issueHcHistoryPermissionMissing =>
      'Data starší než 30 dní vyžadují oprávnění ke čtení historie.';

  @override
  String get issueHcBackgroundPermissionMissing =>
      'Automatická synchronizace nemá oprávnění číst Health Connect na pozadí.';

  @override
  String issueHcReadFailed(String date) {
    return 'Health Connect pro $date nevrátil data.';
  }

  @override
  String issueNoData(String source, String date) {
    return 'V $source nejsou pro $date žádná data. Buňky zůstaly beze změny.';
  }

  @override
  String get issueOffline => 'Synchronizace vyžaduje připojení k internetu.';

  @override
  String get issueUnexpected =>
      'Synchronizace se nezdařila z neočekávaného důvodu.';

  @override
  String get actionOpenSettings => 'Otevřít nastavení';

  @override
  String get actionInstallHealthConnect => 'Nainstalovat / aktualizovat';

  @override
  String get actionGrantPermissions => 'Udělit oprávnění';

  @override
  String get actionConnectGoogle => 'Připojit Google účet';

  @override
  String get actionReconnectGoogle => 'Znovu připojit';

  @override
  String get actionRetry => 'Zkusit znovu';

  @override
  String get settingsHcHistory => 'Oprávnění ke čtení historie';

  @override
  String get settingsHcHistoryGranted =>
      'Čtení historie starší než 30 dní je povolené.';

  @override
  String get settingsHcHistoryUnavailable =>
      'Tato verze Health Connect čtení historie nepodporuje.';

  @override
  String get settingsHcPriorityHint =>
      'Tip: v aplikaci Health Connect nastav prioritu zdrojů pro kroky, aby se nesčítaly z více zařízení.';

  @override
  String get settingsHcAllGranted =>
      'Oprávnění ke čtení váhy a kroků jsou udělena.';

  @override
  String get ktEmailLabel => 'E-mail';

  @override
  String get ktPasswordLabel => 'Heslo';

  @override
  String get ktLoginButton => 'Přihlásit a ověřit';

  @override
  String get ktLogoutButton => 'Odhlásit';

  @override
  String get ktChangeCredentials => 'Změnit údaje';

  @override
  String get ktCancel => 'Zrušit';

  @override
  String ktSignedInAs(String email) {
    return 'Přihlášeno jako $email';
  }

  @override
  String get ktLoginSuccess => 'Přihlášení ověřeno.';

  @override
  String get ktFieldsRequired => 'Vyplň e-mail i heslo.';

  @override
  String googleConnectedAs(String email) {
    return 'Připojený účet: $email';
  }

  @override
  String get googleDisconnect => 'Odpojit';

  @override
  String get googleWebClientMissing =>
      'V aplikaci chybí ID webového klienta Google, připojení nemusí fungovat.';

  @override
  String get sheetUrlLabel => 'Odkaz nebo ID tabulky';

  @override
  String get sheetTabLabel => 'Název listu';

  @override
  String get sheetSaveVerify => 'Uložit a ověřit';

  @override
  String get sheetVerify => 'Ověřit';

  @override
  String get sheetInvalidId => 'Neplatný odkaz nebo ID tabulky.';

  @override
  String get sheetNeedsGoogle => 'Pro ověření nejdřív připoj Google účet.';

  @override
  String sheetVerifyResult(int weeks, int days, String first, String last) {
    return 'Týdenních tabulek: $weeks, dní: $days ($first – $last).';
  }

  @override
  String get sheetVerifyNoDates => 'V listu nebyla nalezena žádná data.';

  @override
  String get sheetEditAccessNote =>
      'Čtení ověřeno; oprávnění k úpravám se ověří při první synchronizaci.';

  @override
  String sheetDuplicates(int count, String first, String last, String rows) {
    return 'Pozor: $count dní je v listu vícekrát ($first – $last, řádky $rows). Tyto dny se nebudou synchronizovat, dokud duplicitu neodstraníš.';
  }
}
