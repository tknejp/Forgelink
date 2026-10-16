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
  String get homeLastSyncNever => 'Zatím neproběhla žádná synchronizace.';

  @override
  String get homeQuickSyncButton => 'Synchronizovat';

  @override
  String get homeRangeSync => 'Synchronizovat období';

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

  @override
  String diagnosticsShow(int count) {
    return 'Zobrazit záznamy ($count)';
  }

  @override
  String get diagnosticsHide => 'Skrýt záznamy';

  @override
  String get homeIntegrationSheets => 'Google Sheets';

  @override
  String get homeFix => 'Opravit';

  @override
  String whenToday(String time) {
    return 'dnes $time';
  }

  @override
  String whenYesterday(String time) {
    return 'včera $time';
  }

  @override
  String lastSuccessLine(String when, String trigger) {
    return 'Naposledy úspěšně: $when · $trigger';
  }

  @override
  String get triggerManualShort => 'ručně';

  @override
  String get triggerBackgroundShort => 'na pozadí';

  @override
  String syncProgress(int done, int total, String date) {
    return 'Synchronizuji $done/$total · $date';
  }

  @override
  String get syncProgressWriting => 'Zapisuji do tabulky…';

  @override
  String runSuccess(String dates) {
    return 'Synchronizováno: $dates.';
  }

  @override
  String runNothingToWrite(String dates) {
    return 'Pro $dates nejsou žádná data. Tabulka zůstala beze změny.';
  }

  @override
  String runPartial(String dates) {
    return 'Částečně synchronizováno: $dates.';
  }

  @override
  String runFailed(String dates) {
    return 'Synchronizace se nezdařila: $dates.';
  }

  @override
  String runDayWritten(String fields) {
    return 'zapsáno $fields';
  }

  @override
  String runDayUnchanged(String fields) {
    return 'beze změny $fields';
  }

  @override
  String runDayMissing(String fields) {
    return 'bez dat $fields';
  }

  @override
  String runDayFailed(String fields) {
    return 'nezapsáno $fields';
  }

  @override
  String get detailsShow => 'Podrobnosti';

  @override
  String get detailsHide => 'Skrýt podrobnosti';

  @override
  String get fieldWeight => 'váha';

  @override
  String get fieldKcal => 'kcal';

  @override
  String get fieldProtein => 'bílkoviny';

  @override
  String get fieldCarbs => 'sacharidy';

  @override
  String get fieldFat => 'tuky';

  @override
  String get fieldFiber => 'vláknina';

  @override
  String get fieldSteps => 'kroky';

  @override
  String get outcomeWritten => 'Zapsáno';

  @override
  String get outcomeUnchanged => 'Beze změny';

  @override
  String get outcomeMissing => 'Bez dat';

  @override
  String get outcomeSkippedFormula => 'Vzorec – přeskočeno';

  @override
  String get outcomeFailed => 'Chyba';

  @override
  String get dayNeverSynced => 'Tento den zatím nebyl synchronizován.';

  @override
  String get daySyncNow => 'Synchronizovat tento den';

  @override
  String get dayTodayWeightOnly => 'Dnes se synchronizuje jen váha.';

  @override
  String get calendarHint =>
      'Klepni = synchronizovat · podrž = detail · podrž a táhni = období';

  @override
  String rangeTooLong(int max) {
    return 'Období může mít nejvýše $max dní.';
  }

  @override
  String get rangePickerHelp => 'Vyber období k synchronizaci';

  @override
  String get historyTitle => 'Historie synchronizací';

  @override
  String get historyEmpty => 'Zatím žádné synchronizace.';

  @override
  String get triggerQuick => 'Rychlá synchronizace';

  @override
  String get triggerCalendar => 'Kalendář';

  @override
  String get triggerRange => 'Období';

  @override
  String get triggerBackground => 'Na pozadí';

  @override
  String get runStatusSuccess => 'Hotovo';

  @override
  String get runStatusNoData => 'Bez dat';

  @override
  String get runStatusPartial => 'Částečně';

  @override
  String get runStatusFailed => 'Chyba';

  @override
  String get openIssuesTitle => 'Vyžaduje pozornost';

  @override
  String get dismiss => 'Skrýt';

  @override
  String historyCells(int count) {
    return 'Zapsaných buněk: $count';
  }

  @override
  String get rangeConfirmTitle => 'Synchronizovat období?';

  @override
  String rangeConfirmBody(String dates, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dní',
      few: '$count dny',
      one: '1 den',
    );
    return '$dates · $_temp0';
  }

  @override
  String homeQuickSyncCaption(String yesterday, String today) {
    return '$yesterday kompletně · $today jen váha';
  }

  @override
  String get settingsHcBackground => 'Povolit čtení na pozadí';

  @override
  String get settingsHcBackgroundGranted =>
      'Čtení na pozadí je povolené – synchronizace doběhne, i když aplikaci opustíš.';

  @override
  String get settingsHcBackgroundUnavailable =>
      'Tato verze Health Connect čtení na pozadí nepodporuje.';

  @override
  String get syncServiceTitle => 'Forgelink synchronizuje…';

  @override
  String get syncServiceText => 'Zapisuji data do tabulky.';

  @override
  String get syncServiceChannel => 'Probíhající synchronizace';

  @override
  String syncQueued(int count) {
    return '+$count ve frontě';
  }

  @override
  String get homeQuickSyncLabel => 'Rychlá synchronizace včerejška';

  @override
  String get autoSyncSwitch => 'Synchronizovat automaticky';

  @override
  String get autoSyncDescription =>
      'Každý den kolem 0:30 (celý předchozí den) a 12:30 (dnešní váha) doplní poslední 3 dny. Android může běh o pár minut posunout, ruční synchronizace funguje vždy.';

  @override
  String autoSyncLastRun(String when, String status) {
    return 'Poslední běh na pozadí: $when · $status';
  }

  @override
  String get autoSyncNeverRan => 'Na pozadí zatím neběžela.';

  @override
  String get autoSyncBattery => 'Vypnout optimalizaci baterie';

  @override
  String get autoSyncBatteryOk =>
      'Optimalizace baterie je pro Forgelink vypnutá.';

  @override
  String get autoSyncUnused => 'Otevřít nastavení aplikace';

  @override
  String get autoSyncUnusedHint =>
      'V nastavení aplikace vypni „Pozastavit aktivitu, pokud se aplikace nepoužívá“, jinak Android po delší době automatickou synchronizaci zastaví.';

  @override
  String get autoSyncNeedsHcBackground =>
      'Health Connect na pozadí: povol „Čtení na pozadí“ v sekci Health Connect.';

  @override
  String get bgFailureTitle => 'Automatická synchronizace se nezdařila';

  @override
  String get bgChannelName => 'Výsledky synchronizace';

  @override
  String get diagnosticsBgTest => 'Test synchronizace na pozadí';

  @override
  String get diagnosticsBgTestScheduled =>
      'Spustí se za 10 s – teď můžeš aplikaci opustit.';

  @override
  String get bgSuccessTitle => 'Synchronizace dokončena';

  @override
  String bgSuccessBody(String dates, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hodnot',
      few: '$count hodnoty',
      one: '1 hodnota',
    );
    return '$dates: zapsáno $_temp0.';
  }

  @override
  String bgUpToDateBody(String dates) {
    return '$dates: vše už bylo aktuální.';
  }

  @override
  String get bgPartialTitle => 'Synchronizace dokončena s problémy';

  @override
  String get bgManualHint => 'Otevři Forgelink a synchronizuj ručně.';

  @override
  String autoSyncNextRun(String when) {
    return 'Další běh: $when';
  }

  @override
  String get autoSyncNotifySuccess => 'Oznámit i úspěšnou synchronizaci';

  @override
  String whenTomorrow(String time) {
    return 'zítra $time';
  }

  @override
  String get issueDriveApiDisabled =>
      'Google Drive API není v projektu Google Cloud povolené.';

  @override
  String get driveChooseButton => 'Vybrat z Google Disku';

  @override
  String get driveChooserTitle => 'Vyber tabulku';

  @override
  String get driveSearchHint => 'Hledat podle názvu';

  @override
  String get driveEmpty => 'Žádné tabulky nenalezeny.';

  @override
  String get driveReadOnly => 'Jen ke čtení';

  @override
  String driveOwnerModified(String owner, String when) {
    return '$owner · upraveno $when';
  }

  @override
  String get homeQuickSyncTitle => 'Rychlá synchronizace';

  @override
  String homeLastSync(String when) {
    return 'Naposledy $when';
  }

  @override
  String homeLastSyncWith(String when, String trigger) {
    return '$when · $trigger';
  }

  @override
  String qsYesterday(String date) {
    return 'Včera · $date';
  }

  @override
  String get qsYesterdaySub => 'Výživa a kroky';

  @override
  String qsToday(String date) {
    return 'Dnes · $date';
  }

  @override
  String qsTodaySub(String value) {
    return 'Váha $value';
  }

  @override
  String get qsTodaySubNone => 'Jen váha';

  @override
  String get chipInSheet => 'V tabulce';

  @override
  String get chipToWrite => 'Ke zápisu';

  @override
  String get chipNutritionMissing => 'Výživa chybí';

  @override
  String get chipError => 'Chyba';

  @override
  String get chipNoData => 'Bez dat';

  @override
  String get calendarRangeButton => 'Období';

  @override
  String get legendFull => 'Kompletní';

  @override
  String get legendPartial => 'Částečně';

  @override
  String get legendMissing => 'Chybí';

  @override
  String get legendFailed => 'Chyba';

  @override
  String get homeNeedsSetup => 'Nenastaveno';

  @override
  String get syncSheetRunning => 'Synchronizuji…';

  @override
  String get syncSheetDone => 'Hotovo';

  @override
  String get syncSheetWarn => 'Hotovo s upozorněním';

  @override
  String get syncSheetFailed => 'Synchronizace selhala';

  @override
  String get syncSheetNoData => 'Žádná nová data';

  @override
  String syncSheetSub(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dní',
      few: '$count dny',
      one: '1 den',
    );
    return '$label · $_temp0';
  }

  @override
  String get syncRowWaiting => 'Čeká';

  @override
  String get syncRowReading => 'Čtu Health Connect a Kalorické tabulky…';

  @override
  String get syncRowRead => 'Načteno';

  @override
  String get syncRowWriting => 'Zapisuji do tabulky…';

  @override
  String syncRowResult(int written, int unchanged) {
    String _temp0 = intl.Intl.pluralLogic(
      written,
      locale: localeName,
      other: '$written nových',
      few: '$written nové',
      one: '1 nová',
    );
    return '$_temp0 · $unchanged beze změny';
  }

  @override
  String get syncRowNutritionMissing => 'výživa chybí';

  @override
  String get syncRowRestAfterMidnight => 'zbytek po půlnoci';

  @override
  String get syncRowNoData => 'Ve zdrojích nejsou data';

  @override
  String syncMoreDays(int count) {
    return '+ $count dalších';
  }

  @override
  String get actionClose => 'Zavřít';

  @override
  String get actionOpenSheet => 'Otevřít tabulku';

  @override
  String get fieldLabelWeight => 'Váha';

  @override
  String get fieldLabelSteps => 'Kroky';

  @override
  String get fieldLabelKcal => 'Energie';

  @override
  String get fieldLabelProtein => 'Bílkoviny';

  @override
  String get fieldLabelCarbs => 'Sacharidy';

  @override
  String get fieldLabelFat => 'Tuky';

  @override
  String get fieldLabelFiber => 'Vláknina';

  @override
  String get cellInSheet => 'V tabulce';

  @override
  String get cellToWrite => 'Ke zápisu';

  @override
  String get cellMissing => 'Chybí ve zdroji';

  @override
  String get cellAfterMidnight => 'Po půlnoci';

  @override
  String get cellFormula => 'Vzorec';

  @override
  String get cellFailed => 'Chyba';

  @override
  String get dayChipFull => 'Kompletní';

  @override
  String get dayChipPartial => 'Částečně';

  @override
  String get dayChipNone => 'Nesynchronizováno';

  @override
  String get dayChipFailed => 'Chyba';

  @override
  String get dayChipNoData => 'Bez dat';

  @override
  String daySheetTab(String tab) {
    return 'List $tab';
  }

  @override
  String dayTodaySuffix(String title) {
    return '$title · dnes';
  }

  @override
  String get dayTodayNote =>
      'Den ještě neskončil. Výživa a kroky se zapíšou po půlnoci, teď lze zapsat jen váhu.';

  @override
  String get lockNoteManual =>
      'Hlad, hydratace, trénink a poznámky zůstanou beze změny.';

  @override
  String get daySyncFirst => 'Synchronizovat den';

  @override
  String get dayUpdate => 'Aktualizovat den';

  @override
  String get rangePreset3 => 'Poslední 3 dny';

  @override
  String get rangePreset7 => 'Posledních 7 dní';

  @override
  String get rangePresetMonth => 'Tento měsíc';

  @override
  String get rangeLockNote =>
      'Existující hodnoty se jen aktualizují. Hlad, hydratace, trénink a poznámky zůstanou beze změny.';

  @override
  String get rangePickFirst => 'Vyber první a poslední den';

  @override
  String rangePickEnd(String date) {
    return '$date · klepni na konec období';
  }

  @override
  String rangeSummary(String from, String to, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dní',
      few: '$count dny',
      one: '1 den',
    );
    return '$from – $to · $_temp0';
  }

  @override
  String rangeButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dní',
      few: '$count dny',
      one: '1 den',
    );
    return 'Synchronizovat $_temp0';
  }

  @override
  String get monthPrev => 'Předchozí měsíc';

  @override
  String get monthNext => 'Další měsíc';

  @override
  String get settingsGroupSources => 'Zdroje dat';

  @override
  String get settingsGroupTarget => 'Cíl';

  @override
  String get settingsGroupOther => 'Ostatní';

  @override
  String get rowReads => 'Čte';

  @override
  String get hcReadsValue => 'Váhu a kroky';

  @override
  String get rowHistory => 'Starší data';

  @override
  String get rowBackground => 'Na pozadí';

  @override
  String get valueAllowed => 'Povoleno';

  @override
  String get valueNotAllowed => 'Nepovoleno';

  @override
  String get valueUnsupported => 'Nepodporováno';

  @override
  String get hcGrantHistoryShort => 'Povolit starší data';

  @override
  String get hcGrantBackgroundShort => 'Povolit na pozadí';

  @override
  String get rowAccount => 'Účet';

  @override
  String get ktReadsValue => 'Energii, makra, vlákninu';

  @override
  String get ktLoginShort => 'Přihlásit';

  @override
  String get rowAccess => 'Přístup';

  @override
  String get googleAccessValue => 'Tabulky, vybrané soubory';

  @override
  String get googleConnect => 'Připojit';

  @override
  String get rowSheetId => 'ID';

  @override
  String get rowTab => 'List';

  @override
  String get rowCoverage => 'Rozsah';

  @override
  String sheetCoverage(int weeks, String first, String last) {
    return 'Týdnů: $weeks · $first – $last';
  }

  @override
  String get sheetPickDrive => 'Vybrat z Disku';

  @override
  String get sheetEditManual => 'Upravit ručně';

  @override
  String get sheetEditTitle => 'Upravit tabulku';

  @override
  String get autoSyncSub => 'Denně 0:30 a 12:30 · doplní poslední 3 dny';

  @override
  String get notifySuccessSub => 'Notifikace po každém běhu, nejen při chybě';

  @override
  String get rowNextRun => 'Další běh';

  @override
  String get rowLastRun => 'Poslední běh';

  @override
  String get rowBattery => 'Baterie';

  @override
  String get batteryOk => 'Optimalizace vypnutá';

  @override
  String get batteryOn => 'Optimalizace zapnutá';

  @override
  String get valueOff => 'vypnuto';

  @override
  String get valueNever => 'zatím ne';

  @override
  String get autoSyncDelayHint =>
      'Android může běh o pár minut posunout. Aby ho po delší době nezastavil, vypni v nastavení aplikace „Pozastavit aktivitu, pokud se aplikace nepoužívá“.';

  @override
  String get appSettingsButton => 'Nastavení aplikace';

  @override
  String get batteryButton => 'Vypnout optimalizaci';

  @override
  String diagnosticsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count záznamů',
      few: '$count záznamy',
      one: '1 záznam',
    );
    return '$_temp0';
  }

  @override
  String settingsFooter(String version) {
    return 'Forgelink $version · data zůstávají v telefonu';
  }

  @override
  String get historyFilterAll => 'Vše';

  @override
  String get historyFilterManual => 'Ručně';

  @override
  String get historyFilterBackground => 'Na pozadí';

  @override
  String get historyFilterIssues => 'Problémy';

  @override
  String get historyFilterEmpty => 'Žádné záznamy v tomto filtru.';

  @override
  String get historyToday => 'Dnes';

  @override
  String get historyYesterday => 'Včera';

  @override
  String get diagFilterAll => 'Vše';

  @override
  String get diagFilterIssues => 'Upozornění a chyby';

  @override
  String get diagBgTestShort => 'Test na pozadí';

  @override
  String get onbWelcomeText =>
      'Přenese váhu, kroky a výživu do tabulky tvého trenéra. Jedním klepnutím nebo samo každý den.';

  @override
  String get onbSourceHcSub => 'Váha a kroky';

  @override
  String get onbSourceKtSub => 'Energie, makra, vláknina';

  @override
  String get onbSourceSheets => 'Google Sheets';

  @override
  String get onbSourceSheetsSub => 'Tabulka trenéra';

  @override
  String get onbLocalNote =>
      'Vše běží v telefonu. Žádný server ani další účet.';

  @override
  String get onbStart => 'Začít nastavení';

  @override
  String get onbContinue => 'Pokračovat';

  @override
  String get onbSkip => 'Přeskočit';

  @override
  String get onbInstallHc => 'Nainstalovat Health Connect';

  @override
  String get onbHcText => 'Forgelink bude jen číst. Nic nezapisuje ani nemaže.';

  @override
  String get onbPermWeightSub => 'Pro zápis dnešní váhy';

  @override
  String get onbPermStepsSub => 'Denní součet';

  @override
  String get onbPermHistory => 'Starší data';

  @override
  String get onbPermHistorySub => 'Pro opravu dnů starších 30 dní';

  @override
  String get onbPermBackground => 'Čtení na pozadí';

  @override
  String get onbPermBackgroundSub => 'Pro automatickou synchronizaci';

  @override
  String get onbKtText =>
      'Přihlas se stejným účtem jako v aplikaci. Údaje zůstanou uložené jen v telefonu.';

  @override
  String get onbKtOk => 'Přihlášeno a ověřeno';

  @override
  String get onbEmailHint => 'jmeno@email.cz';

  @override
  String get onbSheetTitle => 'Tabulka trenéra';

  @override
  String get onbSheetText =>
      'Přihlas se ke Googlu a vyber tabulku. Forgelink najde řádek podle data a vyplní jen svoje sloupce.';

  @override
  String get onbGoogleNotConnected => 'Nepřihlášeno';

  @override
  String get onbGoogleAccess => 'Přístup k vybraným tabulkám';

  @override
  String get onbSheetNone => 'Nevybráno';

  @override
  String onbSheetOk(String tab) {
    return 'List $tab · ověřeno';
  }

  @override
  String get onbGoogleButton => 'Přihlásit přes Google';

  @override
  String get onbPickSheet => 'Vybrat tabulku';

  @override
  String get onbDoneTitle => 'Vše připraveno';

  @override
  String get onbDoneText =>
      'Každý den kolem 0:30 se zapíše celý předchozí den, ve 12:30 dnešní váha.';

  @override
  String get onbFinish => 'Přejít na přehled';

  @override
  String get actionBack => 'Zpět';

  @override
  String syncButtonProgress(int done, int total) {
    return 'Synchronizuji $done/$total';
  }

  @override
  String get syncButtonWriting => 'Zapisuji…';

  @override
  String get syncButtonDone => 'Hotovo';
}
