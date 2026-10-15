# Forgelink — Implementation Plan

Plan date: 2026-10-15. This is a living plan until the MVP ships. After that it becomes a design record (move it to `docs/archive/`).

Forgelink is a small Android utility for one user. It copies daily data from **Health Connect** (weight, steps) and **Kalorické tabulky** (kcal and macros) into the nutrition coach's existing **Google Sheet**. No manual copying is needed.

> **Design principle:** this is a utility, not a fitness app. The goal is the smallest implementation that can be trusted to write the right numbers into the right cells and never damage anything else in the coach's sheet.

The plan rests on a source-level research pass over Forgetrack and the plugins it already uses, done on 2026-10-15. Plugin claims cite the exact pub-cache sources, listed in [Appendix A](#appendix-a--verified-technical-facts). A skeptic pass checked them. Items still marked *unverified* go on the device validation list in [Phase 5](#phase-5--device-validation-on-the-real-sheet).

---

## 1. Scope

**In scope (MVP):**

- Manual sync in three modes:
  - **Quick Sync:** yesterday in full, plus today's weight.
  - **Calendar tap:** one date.
  - **Date range.**
- Writes **values only** into columns B–H of the matching date row on the `tracker` tab.
- Idempotent and safe to repeat. Missing data never becomes `0` or a blank.
- Clear Czech error messages, each with a direct action (open settings, grant permission, reconnect, retry).
- A compact integration status (Health Connect, Kalorické tabulky, Google Sheets).
- A lightweight local sync history.
- Material 3 styling that follows the system light/dark theme.
- The ARB localization pipeline, Czech first, with no hardcoded UI text.

**Background sync (the brief's "phase 2", here [Phase 6](#phase-6--background-sync-runs-with-the-app-closed)):** a best-effort daily sync that runs even when the app is closed. It starts only after manual sync is proven. In this document "Phase N" always means a phase from §13.

**Optional:** an in-app "choose from Google Drive" list (Phase 7).

**Non-goals:**

- Dashboards, statistics, gamification, RPG, Firebase or any cloud backend, or a local database.
- Any formatting change, any row creation, or any write outside B–H of an existing date row.

---

## 2. Destination sheet contract (verified 2026-10-15)

| Item | Value |
|---|---|
| Spreadsheet | the coach's spreadsheet, ID `<coach sheet ID>`. Owned by the coach and shared with the user (editor). |
| Tab | `tracker` (sheet range A1:L904 at time of inspection). It is the only tab Forgelink reads or writes. |
| Other tabs | `making weight`, `Sebereflexe`, `weightlog`, `spánkový deníček`, `archiv`, … These are **never** read. Several contain dates (e.g. `weightlog` column A), so a spreadsheet-wide date search would be wrong. |
| Weekly structure | Each week is a Google Sheets **Table** (e.g. `Tabulka63`). Above it sit a goals block ("CÍLE:" in column A, targets in F–L) and a header row (`DATUM … POZNÁMKY`). Then come 7 date rows, then a footer row with `AVERAGE` formulas (shows `#DIV/0!` while empty). |
| Date column | A, displayed `12.10.2026`. It may be a real date (serial) or text; the app handles both. |

**Column ownership:**

| Col | Header | Owner | Source | Format written |
|---|---|---|---|---|
| A | DATUM | Sheet | — | **never written** (lookup key only) |
| B | VÁHA | Forgelink | Health Connect, last weight reading of the day | number, 1 decimal |
| C | KCAL | Forgelink | Kalorické tabulky | integer |
| D | BÍLKOVINY | Forgelink | Kalorické tabulky | integer (g) |
| E | SACHARIDY | Forgelink | Kalorické tabulky | integer (g) |
| F | TUKY | Forgelink | Kalorické tabulky | integer (g) |
| G | VLÁKNINA | Forgelink | Kalorické tabulky | integer (g) |
| H | KROKY | Forgelink | Health Connect, de-duplicated daily total | integer |
| I | POCIT HLADU | Manual (dropdown) | — | **never written** |
| J | HYDRATACE | Manual (dropdown) | — | **never written** |
| K | TRÉNINK | Manual (checkbox) | — | **never written** |
| L | POZNÁMKY | Manual | — | **never written** |

**Invariants:**

1. The app never sends a write request that covers A or I–L, header rows, goals rows or footer rows.
2. The app never sends formatting requests (`spreadsheets.batchUpdate`), `values.append` or `values.clear`, and never creates rows, tables or tabs.
3. A row is a target only if its column A parses to a date on the `tracker` tab, and (when Table metadata is available) it lies inside a Table's data rows.
4. If a date appears on more than one row, the app writes nothing for that date and reports an error. It never guesses.
5. A cell in B–H whose current content is a formula is never overwritten. It is reported as skipped.
6. Display formatting stays the coach's. If a column is formatted as an integer, `82.4` is stored correctly but shows as `82`. The app cannot and will not change that.

---

## 3. Data rules (per field)

### Missing data vs. zero

| Field | "Missing" (cell left untouched) | Written as `0`? |
|---|---|---|
| Weight | No WEIGHT record whose local timestamp falls on that day | Never. A weight ≤ 0 is treated as missing. |
| Steps | Aggregate returns `0` (Health Connect cannot store a 0-count steps record, so 0 means no data) | Never |
| KT, whole day | Summary `hasData == false` (kcal ≤ 0 and protein ≤ 0): nothing logged | Never |
| KT, single macro on a logged day | Its nutrient code is absent from the summary response | **Yes**, when the code is present with value 0 (a real zero) |

Forgetrack's parser maps absent nutrient codes to `0` (`kt_nutrition_parser.dart:20-24`, `?? 0`). **The port makes every macro nullable** to avoid this.

### Health Connect

- **Day window:** `start = DateTime(y, m, d)`, `end = DateTime(y, m, d + 1)`, in local time. Never use `.add(Duration(days: 1))`; it breaks on DST days.
- **Steps:**
  - Call `getTotalStepsInInterval(start, end)` with the default `includeManualEntry: true`. That is the Health Connect Aggregate API, which de-duplicates phone and watch data by the user's data-source priority.
  - `0` → missing.
  - `null` → read failure for that day only (the plugin turns native exceptions into `null`).
  - `> 0` → the value.
  - **Do not port** Forgetrack's raw-record summing (`hc_steps_service.dart`). It can double-count multiple sources and zero-fills days with no data.
- **Weight:**
  - Call `getHealthDataFromTypes(types: [WEIGHT], startTime: start, endTime: end)`.
  - Keep points with `start <= dateFrom < end`. `dateFrom` is already local.
  - Sort by `dateFrom`, then `sourceName` as a deterministic tie-break.
  - Take the **last** point and round to 1 decimal. Values are in kg.
- **Preflight is mandatory.** The plugin returns an empty list, `null` or `0` instead of throwing on permission problems, so empty results are only trusted after these checks pass:
  1. `getHealthConnectSdkStatus() == sdkAvailable`. Always call this first; it also re-initializes the plugin's native client.
  2. `hasPermissions([STEPS])` and `hasPermissions([WEIGHT])`. Checked separately so the error names the missing type.
- **History window:**
  - Health Connect only allows reads from 30 days before the app's first permission grant.
  - Forgelink stores `hcFirstGrantDate` the first time it sees permissions granted. Forgelink is a new app, so this date is exact.
  - A reinstall resets Health Connect's window. App backup is disabled (§12), so a reinstall also starts with empty prefs and records a fresh date. A restored stale date can't make out-of-window days look like "no data".
  - For dates earlier than `hcFirstGrantDate − 30 days`, the app requires `isHealthDataHistoryAuthorized()`. Without it, that day's Health Connect fields fail with `hcHistoryPermissionMissing` and are never written as blank.

### Kalorické tabulky

- **Auth:** unchanged from Forgetrack.
  - Email plus the MD5 hash of the password, stored in secure storage.
  - `POST /login/create` gives a session cookie. Logging in again with the stored hash is the only refresh mechanism.
- **Per sync run:** one `restoreSession()` POST, then **one GET per day**: `/user/diary/summary/{dd.MM.yyyy}/get?format=json`. That single endpoint provides:
  - kcal from `foodstuffEnergyTotal`, falling back to the `total` item;
  - protein, carbohydrate, fat and fiber from `items` / `itemsDynamic`, keyed by `code`.

  Forgetrack's merged fetch used 2 GETs per day. The diary endpoint's `*Total` fields are unreliable (0.0 in the captured sample).
- **Rounding:** integers via `.round()`.
- **Expired-session detection:**
  - HTTP 401/403 or `code != 0` triggers `refreshSession()` once per run, then a retry.
  - Network failures (socket, client, timeout) are thrown as `KtNetworkException`, a new subclass of `KtApiException`. That way they surface as `offline`, not as "KT is down". Forgetrack wraps them in a generic `KtApiException`.
  - **Sanity check:** a `code 0` response whose `data` map lacks both `foodstuffEnergyTotal` and `items`/`itemsDynamic` is treated as an invalid session, not as "no data".
- **Never auto-wipe credentials.** Forgetrack's provider logs out on `KtAuthException`. Forgelink only marks the KT integration `error(ktAuthRejected)` and asks the user to update credentials.

---

## 4. Sync semantics

### Modes

| Mode | Dates | Fields |
|---|---|---|
| Quick Sync | yesterday | B–H (all) |
| | today | B (weight) only |
| Calendar tap (past date) | that date | B–H |
| Calendar tap (today) | today | B only, so the coach never sees half a day of nutrition |
| Calendar tap (future) | — | disabled |
| Date range | every date in range, capped at 120 days | B–H, except today, which gets B only |
| Background ([Phase 6](#phase-6--background-sync-runs-with-the-app-closed)) | yesterday−2 … yesterday, plus today | B–H, and B only for today |

### Write algorithm (one run)

1. **Local preflight, no network.** There are two kinds of checks, and neither touches the network.
   - **Run-blocking:** the sheet ID and tab are configured, and a Google account is pinned. Every write needs these. A failure stops the run with the matching `SyncIssue` and its action; nothing is fetched or written.
   - **Per source:**
     - KT credentials stored → needed for C–G;
     - Health Connect available → needed for B and H;
     - STEPS permission → needed for H;
     - WEIGHT permission → needed for B.

     A failure marks only the affected fields `failed(issue)` for every date in the run. The other source still runs, and the run becomes `partial` with the issue's action shown.
   - A source is only checked when the run's field set needs it. A run that only writes today's weight never checks KT.
   - If **no** source can supply any field the run needs (e.g. today's weight with Health Connect unavailable), the run stops as `failed` with that source's issue.
   - The Phase 6 worker uses the same rules.
2. **Concurrency guard.**
   - In the foreground, the `SyncController` holds a busy flag. While a run is active, buttons and calendar cells are disabled and further requests are ignored.
   - From Phase 6 on, the run also takes a lease key in `SharedPreferencesAsync` (run id + timestamp, 10-minute TTL) so a background run and a manual run never overlap.
3. **Google auth client.**
   - Token for the **pinned account** (§11): `GoogleSignInPlatform.instance.clientAuthorizationTokensForScopes(ClientAuthorizationTokensForScopesParameters(request: AuthorizationRequestDetails(scopes: [spreadsheets], userId: pinnedId, email: pinnedEmail, promptIfUnauthorized: false)))`.
   - In the foreground only, if that returns `null`, repeat it once with `promptIfUnauthorized: true`.
   - The public `GoogleSignIn.instance.authorizationClient` is not used. It sends no email, so Play services could hand back a token for a different account on a multi-account phone.
   - A new `AuthClient` is built per run and closed at the end: `authenticatedClient(http.Client(), AccessCredentials(AccessToken('Bearer', token, expiryUtc), null, scopes))` from `googleapis_auth`. The token carries no expiry, so use a short synthetic one (e.g. now + 50 min). Because the token comes from the platform interface, the `extension_google_sign_in_as_googleapis_auth` bridge isn't needed.
4. **Sheet metadata** (1 request):

   ```dart
   await api.spreadsheets.get(id, $fields:
     'properties(title,locale,timeZone),'
     'sheets(properties(sheetId,title),'
     'tables(tableId,name,range,rowsProperties(footerColorStyle),'
     'columnProperties(columnIndex,columnName,columnType)))');
   ```

   - Find the tab named `tracker`; missing → `sheetTabMissing`.
   - For each Table on it, check that the column names at table-relative indexes 0–7 normalize to `DATUM, VÁHA, KCAL, BÍLKOVINY, SACHARIDY, TUKY, VLÁKNINA, KROKY` (trim + uppercase). Any mismatch → `sheetLayoutChanged`, and nothing is written.
   - **Data rows of a Table** run from `range.startRowIndex + 1` (skipping the header) to `range.endRowIndex − (hasFooter ? 1 : 0)`, end exclusive, 0-based. `hasFooter` means `rowsProperties.footerColorStyle != null`. The exact header and footer semantics are confirmed against the test copy in Phase 3. Because a footer row never has a date in column A, the date rule stays safe even if this is off by one.
   - If the tab has **no** Tables (e.g. the coach converted them back to ranges), continue without the Table check. Invariants 3–5 still protect the sheet.
5. **Date index and current values** (1 request):

   ```dart
   await api.spreadsheets.values.get(id, "'$tab'!A:H",
       valueRenderOption: 'UNFORMATTED_VALUE',
       dateTimeRenderOption: 'SERIAL_NUMBER');
   ```

   Parse column A:
   - a `num` is a day serial: `DateTime.utc(1899, 12, 30).add(Duration(days: n.floor()))`;
   - a `String` matching `^\s*(\d{1,2})\.\s*(\d{1,2})\.\s*(\d{4})\s*$` is a date;
   - anything else is not a date row.

   Compare dates as `LocalDate` (y/m/d) values, never as `DateTime` instants. Build `Map<LocalDate, row>`, plus the set of duplicate dates and the current B–H values per row.
6. **Formula guard** (1 request): `api.spreadsheets.values.get(id, "'$tab'!B:H", valueRenderOption: 'FORMULA')`. Any target cell whose value starts with `=` is skipped and reported.
7. **Fetch sources** sequentially per date:
   - Health Connect: 2 calls per day.
   - KT: 1 GET per day.

   A source that fails stops only that source's fields. The other source continues, and the run becomes partial.
8. **Build the write plan** (pure function). For each date row and each column B–H:
   - new value is `null` → `missing` (not sent);
   - target cell holds a formula → `skippedFormula`;
   - new value equals the current value → `unchanged`. Weight uses `|a−b| < 0.05`; integers must match exactly. Skipping unchanged cells keeps the coach's version history clean.
   - otherwise → `write`.

   Adjacent `write` cells in a row are grouped into one `ValueRange` (e.g. `'tracker'!C884:G884`). Values are Dart `num`s, never strings.
9. **Write** (1 request, skipped entirely when the plan has no `write` cells):

   ```dart
   await api.spreadsheets.values.batchUpdate(
       BatchUpdateValuesRequest(valueInputOption: 'RAW', data: valueRanges), id);
   ```

   - Never use `USER_ENTERED`, so nothing is ever locale-parsed or format-inferred.
   - Atomicity is undocumented. On failure, every planned cell in the run is marked `failed`. A re-run is always safe because writes are idempotent.
   - On a 403 at this step, set the Google Sheets integration to `error(sheetNoEditAccess)` (§7).
10. **Record.** Save per-field outcomes, the per-date status, the run summary, `lastSuccessAt` and the open issues (§7).

Each run costs at most 3 Sheets reads and 1 write, however many dates it covers, which stays well within the per-user quota (60 requests per minute).

### Outcomes

- **Per field:** `written(value)` · `unchanged(value)` · `missing` · `skippedFormula` · `failed(issue)`.

- **Per date:**

  | Status | Meaning | Calendar |
  |---|---|---|
  | `ok` | No field failed or was skipped. At least one field written or unchanged. Missing fields are allowed (e.g. no weigh-in that day). | green |
  | `partial` | At least one field `failed` or `skippedFormula`, and at least one written or unchanged | amber |
  | `noData` | Every field missing, nothing failed. Cells untouched. | grey outline |
  | `failed` | A blocking issue for the date (not in sheet, duplicate, auth, …), or every attempted field failed | red |
  | `running` | Run in progress | spinner |
  | none | Never synced | plain |

  "Missing" is normal and is reported in the date detail, not as a warning colour.

- **Per run:**

  | Status | Rule | UI |
  |---|---|---|
  | `success` | No date `partial` or `failed`, and at least one date `ok` | snackbar `runSuccess` |
  | `noData` | Every date `noData` | snackbar `runNothingToWrite`, explicitly saying nothing was written |
  | `partial` | Some dates or fields failed, others succeeded | result card `runPartial` |
  | `failed` | Nothing written, at least one failure | result card `runFailed` |

  Partial and failed runs show per-date lines naming what was written and what failed, with actions (§6 run messages).

---

## 5. Architecture

A plain layered structure with no feature folders; the app is too small for them. Business logic lives in `sources/`, `sheets/` and `sync/`; widgets only render state and call the controller.

```
lib/
  main.dart                    bootstrap: GoogleSignIn.instance.initialize(serverClientId: webClientId), prefs, run app
  app.dart                     MaterialApp(title: 'Forgelink'): light + dark theme, ThemeMode.system, l10n delegates, locale cs
  core/
    app_log.dart               ported from Forgetrack (no Sentry), plus email masking
    app_config.dart            constants: default tab name, column map B..H, scopes, KT base URL, Web client ID
    local_date.dart            LocalDate (y/m/d): serial <-> date, parse "d.M.yyyy", day window
    prefs_store.dart           SharedPreferencesAsync wrapper (config, statuses, history, open issues)
    secure_store.dart          one shared const FlutterSecureStorage(aOptions: AndroidOptions(resetOnError: false))
    system_intents.dart        MethodChannel 'forgelink/system_intents': open Health Connect settings (Phase 6 adds battery / unused-app intents)
    sync_issue.dart            sealed SyncIssue hierarchy (§6)
  sources/
    health/hc_read_client.dart     ported (nearly as is)
    health/health_source.dart      preflight, steps(day) -> int?, lastWeight(day) -> double?
    kt/kt_client.dart              facade + part files ported from Forgetrack (session, summary, parser, formatter)
  sheets/
    google_auth.dart           connect (authenticate + pin), TokenProvider interface + PlayServicesTokenProvider (pinned email)
    sheets_api.dart            thin googleapis wrapper (get metadata, values.get, values.batchUpdate)
    tracker_index.dart         PURE: (metadata, A:H values) -> date index, duplicates, current values
    write_plan.dart            PURE: (index, day values, formulas) -> outcomes + List<ValueRange>
    tracker_sheet.dart         orchestrates index -> plan -> write for one run
  sync/
    day_values.dart            DayValues {weightKg?, kcal?, proteinG?, carbsG?, fatG?, fiberG?, steps?}
    sync_models.dart           SyncTrigger, FieldOutcome, DayResult, RunResult
    sync_engine.dart           preflight -> fetch -> sheet (no Flutter imports, testable)
    sync_controller.dart       ChangeNotifier: busy, progress, last run, per-date status; reload() from prefs on start + resume
    sync_history.dart          persisted run log + per-date status map + open issues
    integration_status.dart    notConfigured / configured / verified / error per integration
  ui/
    home/…                     status strip, last-sync card, quick sync, month calendar, range action
    settings/…                 sections: Health Connect, Kalorické tabulky, Google, Spreadsheet, Auto sync, Diagnostics
    issue_presenter.dart       SyncIssue -> localized message + action
  l10n/
    app_cs.arb                 template (Czech)
    l10n.dart                  context.l10n extension (copied from Forgetrack)
    app_localizations*.dart    generated, committed
test/                          mirrors lib/ (see §14)
```

**State and dependency injection:** `provider` with a single `ChangeNotifierProvider<SyncController>` and plain constructor injection of the services. No streams except where a plugin forces one.

**Storage:**

| Data | Where |
|---|---|
| KT email + password MD5 hash | `flutter_secure_storage`, keys `kt_email` / `kt_pwd_hash`, through the single `SecureStore` instance (`aOptions: AndroidOptions(resetOnError: false)`) so a keystore hiccup can't silently wipe credentials. The ported KT code takes this instance as a required parameter, with no default fallback. |
| Phase 6 fallback: Google refresh token | `flutter_secure_storage`, same instance |
| Sheet ID, tab name (default `tracker`), pinned Google account email/id, auto-sync flag, `hcFirstGrantDate` | `SharedPreferencesAsync` (no per-isolate cache, safe with the Phase 6 worker) |
| Integration status cache, `lastSuccessAt`, last run, open issues | `SharedPreferencesAsync` |
| Per-date status map | `SharedPreferencesAsync`, JSON, pruned to the last 400 days |
| Run history | `SharedPreferencesAsync`, JSON list, last 50 runs, issue codes + params only, no secrets |

**Dependencies** (versions as resolved in Forgetrack, which are known to work together):

| Package | Version | Why |
|---|---|---|
| `flutter_localizations` (sdk), `intl` | 0.20.2 | ARB pipeline, date formatting |
| `health` | ^13.3.1 | Health Connect |
| `google_sign_in` | ^7.2.0 | Google account connect (`authenticate`) and authorization (Play services) |
| `google_sign_in_platform_interface` | ^3.1.0 | token requests for the **pinned** account email (§4 step 3) |
| `googleapis` | ^16.0.0 | Sheets v4 (needs Dart ≥ 3.9; the scaffold uses ^3.11.5) |
| `googleapis_auth` | ^2.3.0 | `AuthClient` from an access token; Phase 6 refresh-token fallback |
| `http` | ^1.6.0 | KT REST client |
| `crypto` | ^3.0.7 | MD5 for KT login |
| `flutter_secure_storage` | ^10.0.0 | credentials |
| `shared_preferences` | ^2.5.5 | config, statuses, history |
| `provider` | ^6.1.5 | DI and state |
| `workmanager` | ^0.9.0+3 | **Phase 6 only** |
| `flutter_local_notifications` | ^18.0.1 | **Phase 6 only**, failure notifications (needs core library desugaring) |

Not used: Firebase, Sentry, Isar, `path_provider`, charts, `app_settings`, `connectivity_plus`, `extension_google_sign_in_as_googleapis_auth`. The few native intents needed (Health Connect settings; in Phase 6 battery optimisation and unused-app restrictions) go through one small MethodChannel in `MainActivity` instead of a plugin.

---

## 6. Error model and UX

`SyncIssue` is a sealed hierarchy. Each subtype carries its parameters: the affected date(s), the source, the missing permission types, the Google account email. Each subtype maps to:

- a localized message,
- an action,
- `isTransient`, which drives the Phase 6 retry behaviour.

Technical details (HTTP status, error reason, exception type) go to `AppLog` and the run history's diagnostic field. They are never shown in the message and never include tokens, passwords or cookies.

| Issue | When | Message (cs, draft) | Action |
|---|---|---|---|
| `ktCredentialsMissing` | No stored KT email/hash | Chybí přihlašovací údaje ke Kalorickým tabulkám. | **Otevřít nastavení** → KT |
| `ktAuthRejected` | Login `code != 0` after refresh | Přihlášení do Kalorických tabulek se nezdařilo. Zkontroluj e-mail a heslo. | **Upravit údaje** → KT |
| `ktUnavailable` | KT 5xx / bad JSON / repeated API error | Kalorické tabulky teď neodpovídají. | **Zkusit znovu** |
| `googleNotConnected` | No pinned account / never authorized | Google účet není připojený. | **Připojit Google účet** |
| `googleReauthRequired` | Silent auth returns null / 401 persists | Přihlášení ke Googlu vypršelo. | **Znovu připojit** |
| `sheetNotConfigured` | No sheet ID | Není nastavená cílová tabulka. | **Otevřít nastavení** → Tabulka |
| `sheetNotFound` | 404 | Tabulka nebyla nalezena. Zkontroluj odkaz v nastavení. | **Otevřít nastavení** → Tabulka |
| `sheetNoEditAccess` | 403 PERMISSION_DENIED (plain) | Účet {email} nemá oprávnění tabulku upravovat. | **Otevřít nastavení** → Google / Tabulka |
| `sheetsApiDisabled` | 403 with reason `SERVICE_DISABLED` | Google Sheets API není v projektu Google Cloud povolené. | (info; fix in GCP, §11) |
| `sheetTabMissing` | No `tracker` tab | V tabulce chybí list „{tab}“. | **Otevřít nastavení** → Tabulka |
| `sheetLayoutChanged` | Table header mismatch | Rozvržení listu „{tab}“ se změnilo. Nic nebylo zapsáno. | (info) |
| `dateNotInSheet` | No row for date | Datum {date} v tabulce není. Nic nebylo zapsáno. | (info) |
| `dateDuplicated` | Same date in more rows | Datum {date} je v tabulce vícekrát. Nic nebylo zapsáno. | (info) |
| `cellHasFormula` | Formula in a target cell | Buňka {cell} obsahuje vzorec, nebyla přepsána. | (info) |
| `hcNotAvailable` | SDK status not available | Health Connect není nainstalovaný nebo potřebuje aktualizaci. | **Nainstalovat / aktualizovat** → `Health().installHealthConnect()` |
| `hcPermissionMissing` | `hasPermissions` false | Chybí oprávnění Health Connect: {types}. | **Udělit oprávnění** → `requestAuthorization`; if it returns without granting, fall back to `SystemIntents.openHealthConnectSettings()` |
| `hcHistoryPermissionMissing` | Date older than the 30-day window | Data starší než 30 dní vyžadují oprávnění ke čtení historie. | **Udělit oprávnění** → `requestHealthDataHistoryAuthorization()` |
| `hcBackgroundPermissionMissing` | Phase 6 worker: background read not authorized | Automatická synchronizace nemá oprávnění číst Health Connect na pozadí. | **Udělit oprávnění** → Settings → Health Connect → Čtení na pozadí (`requestHealthDataInBackgroundAuthorization()`) |
| `hcReadFailed` | Steps aggregate returned `null` | Health Connect pro {date} nevrátil data. | **Zkusit znovu** |
| `noData` | Source reachable, nothing logged | V {source} nejsou pro {date} žádná data. Buňky zůstaly beze změny. | (info) |
| `offline` | Socket / DNS / timeout | Synchronizace vyžaduje připojení k internetu. | **Zkusit znovu** |
| `sheetsUnavailable` | 429 / 5xx after backoff | Google Sheets je dočasně nedostupné. | **Zkusit znovu** |
| `unexpected` | Anything unclassified | Synchronizace se nezdařila z neočekávaného důvodu. | **Zkusit znovu** + "Diagnostika" |

**Run summary messages** (ARB keys, §4 per-run status):

| Key | Message (cs, draft) |
|---|---|
| `runSuccess` | Synchronizováno: {dates}. |
| `runNothingToWrite` | Pro {dates} nejsou žádná data. Tabulka zůstala beze změny. |
| `runPartial` | Částečně synchronizováno. Per-date lines: "{date}: zapsáno {okFields}; nezapsáno {failedFields} – {reason}" |
| `runFailed` | Synchronizace se nezdařila: {issue message} |

**Open issues.** Every run-blocking issue and every auth, permission or config issue from any run (foreground or background) is saved to a persisted `openIssues` list, with its trigger and date(s).
- The home screen shows these as a banner with their action, above the last sync card.
- An open issue is cleared when a later run proves that integration or date OK, or when the user dismisses it.
- This is how background failures stay visible after a later unrelated manual sync.

**Navigation:**
- `SettingsScreen(initialSection: …)` scrolls to the section and briefly highlights it.
- Health Connect actions call the plugin's permission flows. If those can't help, they open Health Connect settings through `SystemIntents` (§5), which is ported from Forgetrack's `openHealthConnectSettings` MethodChannel.

**Error classification order for Google calls:**

1. `AccessDeniedException` (googleapis_auth, raised on any `WWW-Authenticate` response):
   - header contains `invalid_token` → clear the cached token (`GoogleSignInPlatform.instance.clearAuthorizationToken(ClearAuthorizationTokenParams(accessToken: token))`) and retry once;
   - header contains `insufficient_scope` → `googleReauthRequired`, with no retry loop.
2. `DetailedApiRequestError` → by `status`, `jsonResponse['error']['status']` and `['details'][*]['reason']`:
   - 400 → `sheetLayoutChanged` / config;
   - 403 with reason `SERVICE_DISABLED` → `sheetsApiDisabled`;
   - 403 with reason `ACCESS_TOKEN_SCOPE_INSUFFICIENT` → `googleReauthRequired`;
   - any other 403 `PERMISSION_DENIED` → `sheetNoEditAccess`;
   - 404 → `sheetNotFound`;
   - 429 / 5xx → backoff (2^n s + jitter, at most 4 tries, at least 60 s for 429), then `sheetsUnavailable`.
3. `SocketException` / `ClientException` / `TimeoutException` → `offline`.

**Error classification for KT:**
- `KtAuthException` that persists after one `refreshSession()` → `ktAuthRejected`.
- `KtNetworkException` → `offline`.
- Any other `KtApiException` → `ktUnavailable`.

---

## 7. Integration status

Four states per integration: `notConfigured` · `configured` (stored, not yet proven) · `verified` (proven by a successful real request) · `error(issue)`. Google Sheets has one extra state, `readVerified`, between `configured` and `verified`.

| Integration | `configured` when | `verified` by | Refreshed |
|---|---|---|---|
| Health Connect | Available and permissions granted | A successful read during sync | On app resume (local IPC, no network) |
| Kalorické tabulky | Credentials stored | Successful login (settings "Přihlásit a ověřit", or sync) | Only by sync / explicit verify |
| Google Sheets | Account pinned + sheet ID set | A successful **write** during sync. "Ověřit" in settings (metadata + date index) only proves read access, so it sets an intermediate `readVerified`. | Only by sync / explicit verify |

**Google Sheets edit access.** With only the `spreadsheets` scope there is no read-only way to check edit rights. The "Ověřit" result therefore says: "Čtení ověřeno; oprávnění k úpravám se ověří při první synchronizaci." A 403 on the first write sets `error(sheetNoEditAccess)`. In Phase 7, `files.get(id, $fields: 'capabilities(canEdit)')` can check it up front.

**`lastSuccessAt`.** The end time of the latest run (any trigger) that wrote or confirmed at least one cell and had no `failed` field. `missing` fields alone don't block it. The last sync card shows it together with the trigger ("ručně" / "na pozadí").

**Reload.** `SyncController.reload()` re-reads the following from `SharedPreferencesAsync` on app start and on every `AppLifecycleState.resumed`, so results of a background run that finished while the app sat in memory show up immediately:
- the last run;
- the per-date map;
- open issues;
- integration statuses;
- `lastSuccessAt`.

**Home screen:**

- When all three are `configured`, `readVerified` or `verified`, the strip collapses to a single chip: **Vše připojeno**.
- Otherwise each affected integration shows one line with its message and action.
- Changing a setting resets that integration to `configured` until it is proven again.
- There is no network polling just to refresh status.

---

## 8. UI specification

One screen does the work; settings sit one tap away. Material 3, `ColorScheme.fromSeed`, light and dark themes, `ThemeMode.system`. Compact density.

**Home:**

1. **App bar.** "Forgelink" and a settings icon.
2. **Status strip** (§7).
3. **Open issues banner.** Shown only when `openIssues` is non-empty (§6): one line per issue with its action and a dismiss control.
4. **Last sync card.**
   - Idle: "Naposledy synchronizováno: dnes 7:42" (or "nikdy"), plus the last run's one-line result with an expandable detail list (date → source → outcome, with actions).
   - Running: a progress line ("Synchronizuji 3/10 · 12. 10.") and a linear progress indicator.
5. **Quick Sync.**
   - A large `FilledButton` labelled "Synchronizovat", with a subtitle "Včera: výživa a kroky · Dnes: váha".
   - Disabled while running.
   - On finish, feedback follows the per-run status (§4):
     - `success` and `noData` get a snackbar (`runSuccess` / `runNothingToWrite`);
     - `partial` and `failed` update the result card, with per-date lines and actions.
6. **Calendar.**
   - Month header with ‹ › navigation and a Po–Ne weekday row.
   - 7-column grid of compact cells: day number plus a status colour or dot (§4 outcomes).
   - **Tap = sync that date immediately**, with no confirmation or extra picker. The tapped cell shows a spinner and then its new status.
   - Future dates are disabled.
   - Long-press opens a bottom sheet with that date's last per-field outcome.
   - Opens on the current month.
7. **Advanced.**
   - "Synchronizovat období…" opens the Material `showDateRangePicker` and starts immediately on confirm.
   - "Historie synchronizací" shows the last 50 runs.

**Settings** (sections, each addressable for deep links). Every integration section starts with a **status line**: nenastaveno / nastaveno / (čtení ověřeno) / ověřeno / chyba, plus the issue's action. Its state comes from §7.

- **Health Connect:**
  - status line;
  - "Udělit oprávnění" (steps and weight);
  - "Oprávnění ke čtení historie";
  - Phase 6: "Čtení na pozadí";
  - "Otevřít Health Connect" (`SystemIntents`);
  - a hint to set the step source priority in Health Connect.
- **Kalorické tabulky:** status line, stored email (masked), an email + password form, "Přihlásit a ověřit", "Odhlásit".
- **Google účet:**
  - status line and the pinned account email;
  - "Připojit" / "Znovu připojit" runs the connect flow (§11): `GoogleSignIn.instance.authenticate()`, store `account.email` + `account.id`, then `account.authorizationClient.authorizeScopes([spreadsheets])`;
  - "Odpojit" calls `GoogleSignIn.instance.disconnect()` and clears the pinned account.
- **Tabulka:**
  - status line;
  - URL or ID field; the ID is parsed with `/spreadsheets/d/([a-zA-Z0-9-_]+)`;
  - tab name (default `tracker`);
  - "Ověřit", which runs metadata + index and shows the counts found on the real sheet, e.g. "Nalezeno 60 týdnů, 420 dní (28. 7. 2025 – 20. 9. 2026). Čtení ověřeno; oprávnění k úpravám se ověří při první synchronizaci."
- **Automatická synchronizace** (Phase 6):
  - on/off switch: toggling registers or cancels the periodic task (§13 Phase 6);
  - battery optimisation exemption;
  - "Pozastavit aktivitu, pokud se aplikace nepoužívá" (Pause app activity if unused) set to off;
  - an OEM hint.
- **Diagnostika:** app version and the last N log lines (copy to clipboard).

---

## 9. Localization

- ARB pipeline as in Forgetrack: `l10n.yaml` with `arb-dir: lib/l10n`, **`template-arb-file: app_cs.arb`**, `output-localization-file: app_localizations.dart`, `output-class: AppLocalizations`, `output-dir: lib/l10n`, `nullable-getter: false`, `untranslated-messages-file: build/untranslated_l10n.txt`, and `generate: true` in the pubspec.
- **Czech is the only shipped locale.**
  - `supportedLocales: AppLocalizations.supportedLocales` and `locale: const Locale('cs')`, so the UI is Czech regardless of the phone language.
  - Adding `app_en.arb` later only means removing the forced `locale:`, or making it a setting.
- The brand name "Forgelink" (`MaterialApp.title`, launcher label) is not localized.
- **No hardcoded UI text.**
  - Every user-visible string, including `SyncIssue` messages, comes from ARB.
  - Messages with parameters (`{date}`, `{types}`, `{email}`) use ARB placeholders.
  - Dates are formatted with `intl` in `cs`.
- Run `flutter gen-l10n` after every ARB edit and commit the generated files, as Forgetrack does.
- Background notifications in phase 6 use `lookupAppLocalizations(const Locale('cs'))`, which needs no `BuildContext`.

---

## 10. Logging and diagnostics

- **`AppLog`:** a trimmed copy of Forgetrack's logger with Sentry removed and the prefix set to `[Forgelink]`. Channels: `app`, `auth`, `health`, `kt`, `ktApi` and `ktParse` (scoped `KT` loggers, kept so the ported KT files compile unchanged), `sheets`, `sync`.
- **What gets logged:** each step with date, source and operation, e.g. `sync: 2026-10-12 kt.summary ok kcal=2700`.
- **What never gets logged:** emails are masked with `_maskEmail`, fixed for an empty local part. Passwords, hashes, cookies and tokens are never logged.
- **Persistence:** release builds print nothing, so `AppLog` also appends warnings, errors and run summaries to a small persisted ring buffer (last 300 lines in prefs) shown under Settings → Diagnostika. This is how background runs are inspected.

---

## 11. Google Cloud / OAuth setup

1. **Project.** A **new GCP project "Forgelink"** is recommended over reusing Forgetrack's `forgetracker-493415`:
   - the consent screen shows the Forgelink name;
   - the publishing status is independent;
   - the Sheets quota is separate;
   - moving the shared project to *In production* would also change Forgetrack's consent behaviour.

   See [Open decisions](#16-open-decisions).
2. **Enable the Google Sheets API.** Enable the Drive API too, but only for optional Phase 7.
3. **Google Auth Platform → Branding / Audience.**
   - User type External, publishing status **In production**, with **no** verification submission (personal use).
   - The user sees the "unverified app" warning once.
   - **Do not stay in Testing:** test-user authorizations expire after 7 days, which would break unattended sync and force weekly re-consent.
4. **Data access.** Scope `https://www.googleapis.com/auth/spreadsheets` (sensitive). Phase 7 only: `drive.metadata.readonly`, which is a **restricted** scope. That is acceptable only under the unverified personal-use path (In production, fewer than 100 users). Never submit it for verification.
5. **Clients → Android.** Package `com.knejp.forgelink`, plus:
   - the **debug** keystore SHA-1:

     ```bash
     keytool -list -v -keystore "$USERPROFILE/.android/debug.keystore" -alias androiddebugkey -storepass android -keypass android
     ```

   - a second client for the **release** keystore SHA-1.
6. **Clients → Web application. Required for the MVP.**
   - Its ID is the `serverClientId` for `GoogleSignIn.instance.initialize(serverClientId: …)`. On Android, `authenticate()` fails with `clientConfigurationError` without it.
   - `authenticate()` is the only way to learn which account the user picked, and Forgelink pins that account.
   - Keep its client secret only for the Phase 6 refresh-token fallback.

**Connect flow (MVP):**
1. `GoogleSignIn.instance.authenticate()` → `GoogleSignInAccount`.
2. Store `account.email` and `account.id` (the pinned account).
3. `account.authorizationClient.authorizeScopes([spreadsheets])`.

All later token requests, foreground and worker, go through `GoogleSignInPlatform.instance.clientAuthorizationTokensForScopes` with the pinned email and id (§4 step 3). Forgelink does not call `attemptLightweightAuthentication` on start, so Forgetrack's multi-account picker workaround is not needed.
7. **No `google-services.json`** and no Google Services Gradle plugin.
8. Wait a few minutes for propagation. Misconfiguration shows up as `GoogleSignInExceptionCode.canceled` or `clientConfigurationError`.

---

## 12. Android configuration

- `minSdk = 26` (Health Connect), `compileSdk` ≥ 36 (health plugin), Java/JVM 17.
- Release signing via `key.properties`, with a debug fallback.
- **No flavors.** Forgelink uses one application ID.
- `MainActivity : FlutterFragmentActivity()`. The health plugin's permission launcher needs a `ComponentActivity`.
- **`MainActivity` MethodChannel `forgelink/system_intents`:**
  - MVP: `openHealthConnectSettings`, copied and trimmed from Forgetrack's `MainActivity.kt` (ACTION_HEALTH_CONNECT_SETTINGS, then the Health Connect launch intent, then the app details screen);
  - Phase 6 adds `requestIgnoreBatteryOptimizations` (ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS) and `openUnusedAppRestrictions` (`IntentCompat.createManageUnusedAppRestrictionsIntent`, needs `androidx.core`).
- **Manifest:**
  - `android:label="Forgelink"` on `<application>` (the scaffold has `forgelink`);
  - **backup disabled**: `android:allowBackup="false"` plus `android:dataExtractionRules="@xml/data_extraction_rules"` excluding everything for both cloud backup and device transfer. Android 12+ ignores `allowBackup` for device transfer. A restore would bring back secure-storage ciphertext the new keystore can't decrypt (with `resetOnError: false`, every read would fail), and a stale `hcFirstGrantDate`.
  - permissions: `INTERNET`, `android.permission.health.READ_STEPS`, `android.permission.health.READ_WEIGHT`, `android.permission.health.READ_HEALTH_DATA_HISTORY`;
  - Phase 6 permissions: `READ_HEALTH_DATA_IN_BACKGROUND`, `RECEIVE_BOOT_COMPLETED`, `POST_NOTIFICATIONS`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`;
  - the `ACTION_SHOW_PERMISSIONS_RATIONALE` intent-filter on `MainActivity`;
  - the `ViewPermissionUsageActivity` activity-alias (`VIEW_PERMISSION_USAGE` + `HEALTH_PERMISSIONS`);
  - `<queries>` for `com.google.android.apps.healthdata`.

  Copy the Health Connect entries from Forgetrack's manifest and trim the unused permissions.

---

## 13. Phases

Each phase ends with `flutter analyze` clean, its tests green and a commit. Phases 1–4 form the MVP.

### Phase 0 — Setup (no app code)

- [x] Decide on the GCP project (§16): new project **`forgelink-511721`** (project number 598204569304).
- [x] Do §11 steps 2–8 in that project, including the **Web client**. Its ID is in `AppConfig.googleWebClientId`.
  - Debug keystore (`%USERPROFILE%\.android\debug.keystore`) SHA-1 for the Android client: `43:85:B2:26:9C:73:D0:91:EE:3F:93:CD:C3:09:59:95:EC:C1:4F:8B`.
  - The release keystore doesn't exist yet. Add its SHA-1 as a second Android client once `android/key.properties` is set up.
- [x] **Test copy of the coach's sheet**: ID `<test copy ID>`. All development and dry runs target the copy until Phase 5 signs off.
- [ ] Confirm the KT account's energy unit is kcal, not kJ.

### Phase 1 — Foundation

**Status: done 2026-10-15.** `flutter analyze` clean, 23 tests pass, debug APK builds. Two deviations from the tree in §5:
- the persisted log ring buffer lives in `core/log_buffer.dart`;
- `SheetColumn` (the B–H column map) lives in `core/app_config.dart`.

Launcher label and backup exclusion still need a check on the device.

- Pubspec dependencies (§5, without the Phase 6 packages), `l10n.yaml` + `app_cs.arb`, `context.l10n`.
- App shell: theme light/dark/system, `MaterialApp(title: 'Forgelink')`, Home and Settings skeletons with deep-link sections, `provider` wiring.
- `core/`: `AppLog` + ring buffer, `LocalDate`, `PrefsStore`, `SecureStore`, `SystemIntents`, `SyncIssue` + `IssuePresenter`.
- Android: `minSdk`, `MainActivity` + `system_intents` channel, manifest entries including the `Forgelink` label and disabled backup (§12).

**Done when:**
- the app starts in light and dark themes with the launcher label "Forgelink";
- all visible strings come from ARB;
- backup is disabled (`adb shell bmgr backupnow com.knejp.forgelink` backs up nothing);
- `LocalDate` tests pass: serials (46307 = 12. 10. 2026), string parsing, DST day windows.

### Phase 2 — Sources

**Status: code done 2026-10-16.** 64 tests pass, analyze clean, APK builds. Not yet verified on the device: the Health Connect permission flow and a real KT login.

Layout:
- KT lives in `sources/kt/`:
  - `kt_client.dart` with parts `kt_session_client`, `kt_summary_parser`, `kt_formatter`;
  - `kt_source.dart`, which does the refresh-once and the `SyncIssue` mapping.
- Health Connect lives in `sources/health/` (`hc_read_client.dart`, `health_source.dart`).
- Integration status is in `sync/integration_status.dart`.
- Settings controllers and sections are in `ui/settings/`.

Deviations:
- Settings shows the stored KT email unmasked; it is the user's own. Logs stay masked.
- `kt_session_client.dart` also adds a 20 s request timeout.

- **KT:** port the session client, the trimmed facade, the summary-only diary call, the nullable parser and the formatter. In the port:
  - re-point the `part of` directives at `kt_client.dart`;
  - require the `SecureStore` instance (no default storage);
  - add `KtNetworkException`, the expired-session sanity check and the no-auto-wipe rule.
- **Health Connect:** port `hc_read_client`, trim the permission service to STEPS + WEIGHT (+ history), and add the new `HealthSource` (§3).
- Settings sections for Health Connect and KT, with live status.

**Done when** settings can grant Health Connect permissions and log into KT with verification, and these tests pass:

- the KT parser against the captured fixture in Forgetrack's `docs/integrations/kt_api_reference.md` (kcal 2700, protein 216, carbs 308, fat 61, fiber 27);
- a parser test for an absent code → `null`;
- session tests with `http/testing` `MockClient`: login `code != 0` → `KtAuthException`, 401 → refresh, cookie extraction, `SocketException` → `KtNetworkException` → `offline`;
- `HealthSource` tests with a fake client: 0 → missing, `null` → `hcReadFailed`, last-of-day weight, preflight failures.

### Phase 3 — Sheets

**Status: code done 2026-10-16.** 106 tests pass, analyze clean, APK builds.

Open items:
- `AppConfig.googleWebClientId` is set (Web client in `forgelink-511721`).
- Not yet verified on the device: "Ověřit" against the test copy, the account picker and the token for the pinned account.

Layout:
- `sheets/google_auth.dart`: connect flow and a pinned-email `TokenProvider`.
- `sheets/sheets_gateway.dart`: error mapping and backoff; the classifier is pure.
- `sheets/tracker_index.dart` and `sheets/write_plan.dart`: pure.
- `sheets/tracker_sheet.dart`: orchestration and `parseSpreadsheetId`.
- Settings sections: `google_*`, `sheet_*`.

Deviations:
- Weekly Tables are recognized as tables that start in column A with `DATUM` as the first column. Other Tables on the tab are ignored.
- Date cells must parse to a year between 2000 and 2100, which rules out other numbers in column A.

- `GoogleAuth`: the connect flow (`authenticate()` → pin email/id → `authorizeScopes`), and a `TokenProvider` interface whose Play-services implementation requests tokens for the pinned email via the platform interface (silent, then interactive in the foreground).
- `SheetsApi` wrapper with the error mapping (§6).
- `TrackerIndex` and `WritePlan` as pure functions.
- Settings sections for Google and the spreadsheet, including "Ověřit".

**Done when** "Ověřit" against the **test copy** reports the correct week and day counts, and these tests pass:

- index: serial dates, string dates, duplicates, rows outside Tables, header and footer exclusion;
- write plan: nulls never sent, `''` never produced, A and I–L never in a range, adjacent runs grouped, unchanged cells skipped, formula cells skipped, RAW numbers only.

### Phase 4 — Sync engine and Home (MVP)

- `SyncEngine` (§4 algorithm), `SyncController`, `SyncHistory`, integration status.
- Home: status strip, last sync card, Quick Sync, calendar with per-date status, range sync, history list, result details with actions.

**Done when** every MVP acceptance criterion from the brief holds against the **test copy**:

- [ ] authenticate KT;
- [ ] read Health Connect;
- [ ] access the sheet;
- [ ] find the row by date;
- [ ] write B–H correctly;
- [ ] I–L, formats and footers untouched;
- [ ] Quick Sync in one tap;
- [ ] calendar date in one tap;
- [ ] range works;
- [ ] repeating a sync changes nothing (second run reports all `unchanged`);
- [ ] errors are specific and actionable.

**Tests:** engine with fake sources and a fake sheet (partial failure of one source, missing data, date not found, duplicates, offline). Also the IssuePresenter and SyncController rows in §14.

### Phase 5 — Device validation on the real sheet

- [ ] **Dry run on the test copy.** Check that RAW writes into the Table rows keep column types, banding, number formats, dropdowns, checkboxes and footer formulas. *Unverified in docs; must be proven before any real write.*
- [ ] Compare the steps aggregate with Samsung Health's daily totals for 3–5 days (de-duplication and the all-day-record quirk).
- [ ] Confirm the weight "last of day" choice against the scale app.
- [ ] Revoke a Health Connect permission and check that it is reported as a permission error, not as "no data".
- [ ] Multi-account phone: the token belongs to the pinned account (a wrong account shows as 403 or 404).
- [ ] Switch the sheet ID to the coach's real sheet. Run one Quick Sync and check the cells by eye with the coach's view.

### Phase 6 — Background sync (runs with the app closed)

The research verified this is feasible against the plugin sources:

- `workmanager` runs every task in a headless `FlutterEngine(applicationContext)`;
- `health`, `google_sign_in_android` and `flutter_secure_storage` all attach through `onAttachedToEngine` with the application context;
- consent and permission UI are the only steps that need an Activity, and they happen once, in the foreground.

**Design:**

- **Schedule.** One unique periodic task: `registerPeriodicTask(uniqueName, taskName, frequency: 12 h, flexInterval: ~4 h, constraints: Constraints(networkType: NetworkType.connected), existingWorkPolicy: ExistingPeriodicWorkPolicy.update)`.
  - On **every app start**, call `Workmanager().initialize()`. Then, if `autoSync == true`, register the task (which also recovers from hibernation and force-stop once the app is opened); otherwise call `cancelByUniqueName(uniqueName)`.
  - The settings switch does the same when toggled.
  - The worker also returns `true` immediately if it reads `autoSync == false`.
- **Lookback.** Each run syncs yesterday−2 … yesterday (B–H) plus today (B). Unchanged cells are skipped, so extra runs cost nothing. Late Health Connect data from Samsung Health self-heals.
- **Worker order:**
  1. `WidgetsFlutterBinding` / `DartPluginRegistrant.ensureInitialized()`;
  2. `SharedPreferencesAsync` config, returning `true` at once if `autoSync` is off;
  3. lease key;
  4. `getHealthConnectSdkStatus()` (re-initializes the plugin);
  5. `isHealthDataInBackgroundAvailable() && isHealthDataInBackgroundAuthorized()`; if this fails, Health Connect fields fail with `hcBackgroundPermissionMissing`, and KT still runs (§4 step 1);
  6. KT `restoreSession()`;
  7. Google token;
  8. the same `SyncEngine` as the foreground;
  9. save the result and open issues.
- **Google token in the worker, Strategy A (default).** The same pinned-email path as the foreground (§4 step 3), with `promptIfUnauthorized: false`:
  1. `GoogleSignIn.instance.initialize(serverClientId: webClientId)` in the worker isolate;
  2. `GoogleSignInPlatform.instance.clientAuthorizationTokensForScopes(...)`.

  A `null` result or `uiUnavailable` → `googleReauthRequired`.
- **Strategy B (fallback, only if A fails device validation).**
  1. In the foreground, call `authorizeServer([spreadsheets])` with the Web client as `serverClientId`.
  2. Exchange the code once. The function needs an `http.Client` as its first argument and comes from `package:googleapis_auth/auth_io.dart`; close the client afterwards:

     ```dart
     await obtainAccessCredentialsViaCodeExchange(
         http.Client(), ClientId(webId, webSecret), serverAuthCode, redirectUrl: '');
     ```

     That `redirectUrl: ''` is correct for Android server auth codes is **unverified**; check it on the device.
  3. Store the refresh token in secure storage.
  4. In the worker, use `clientViaRefreshToken`.

  The embedded secret is acceptable for single-user personal use. Both strategies sit behind the `TokenProvider` interface, so switching is local.
- **Return values** (`workmanager_android`):

  | Return | WorkManager result | Use for |
  |---|---|---|
  | `true` | `Result.success()` | success, and permanent problems after they are recorded and notified |
  | `false` | `Result.retry()`, with backoff | transient problems |
  | throw | `Result.failure()` | — (for periodic work this only ends the current run) |

  Forgetrack's background service has this mapping inverted; do not copy it.
- **Notifications.** Only on failures that need the user (re-auth, permission, credentials), and at most one per day. None for successful runs.
- **Keeping the job alive** (Android 13+):
  - battery optimisation exemption (the restricted standby bucket starts after 8 days without interaction, and exempt apps escape it);
  - "Pause app activity if unused" turned off via `IntentCompat.createManageUnusedAppRestrictionsIntent`. App hibernation after months unused would cancel jobs **and** may reset permissions.
  - OEM hints (Samsung: Never sleeping apps; Xiaomi: Autostart + No restrictions).
  - The exemption and unused-app intents go through the `system_intents` channel (§12).
- **Device validation checklist** (before relying on it):

  1. A one-off task runs after the app is swiped away (`adb shell cmd jobscheduler run -f com.knejp.forgelink <jobId>`).
  2. Health Connect background reads return real data with the permission granted, and are reported as a permission problem when it is revoked.
  3. Strategy A returns a token right after use, after more than 1 h, after a reboot without opening the app, and after more than 7 days.
  4. The pinned email picks the right account.
  5. KT login and a Sheets read + write work from the worker.
  6. After a reboot, the next periodic run fires without opening the app.
  7. After `am force-stop`, nothing runs until the app is opened.
  8. `am set-standby-bucket … restricted`, with and without the exemption.
  9. `dumpsys deviceidle force-idle` defers runs to a maintenance window.
  10. Secure storage reads work in the worker while the screen is locked.
  11. `false` is retried with backoff, and a throw does not cancel the periodic schedule.
  12. A background failure (e.g. KT credentials revoked) and a background success both show on the home screen on the next open or resume. The failure appears as an open issue; the success sends no notification.
  13. Switching auto sync off → `adb shell dumpsys jobscheduler` shows no Forgelink job, and nothing runs within 24 h.

### Phase 7 — Optional: choose from Google Drive

- Add the `drive.metadata.readonly` scope (restricted, so personal-use path only; re-consent).
- List spreadsheets with `files.list(q: "mimeType='application/vnd.google-apps.spreadsheet' and trashed=false", orderBy: 'recency desc', fields: 'files(id,name,owners(displayName),modifiedTime,capabilities(canEdit))')` and show them in a bottom-sheet list.
- Pick → fill in the ID → "Ověřit". Files with `canEdit == false` are shown disabled.
- "Ověřit" can now also check edit access up front with `files.get(id, $fields: 'capabilities(canEdit)')`.

This adds no picker library. Pasting the URL stays the primary path.

---

## 14. Testing strategy

Pure logic gets unit tests; plugins sit behind small fakes. Widget tests are limited to the calendar cell states and the status strip collapse.

| Area | Key cases |
|---|---|
| `LocalDate` | serial ↔ date (46307 = 2026-10-12, 46310 = 2026-10-15), `"12.10.2026"` / `"12. 10. 2026"` / `"1.7.2025"`, DST start/end day windows |
| KT parser | fixture totals; absent code → `null`; `hasData` false on an empty day; localized `actual` strings (`'26,6'`, `'2 700'`) |
| KT session | login `code != 0`; 401 → invalidate; stale-socket retry; cookie parsing; no credential wipe on auth failure |
| HealthSource | preflight order; steps 0 → missing, `null` → failure; weight last-of-day with unsorted, same-timestamp points; history window gate |
| TrackerIndex | serial and string dates; duplicates; rows outside Tables; non-date rows (CÍLE, header, footer); other tabs ignored |
| WritePlan | `null` never sent; no `''`; A and I–L never in a range; adjacent grouping; unchanged skip (weight tolerance); formula skip; RAW numbers only |
| SyncEngine | per-mode field sets (today = weight only, and no KT check); WEIGHT permission missing → C–H written, B failed, run partial; KT credentials missing → B and H written, C–G failed; date not found; offline; idempotent second run → all unchanged and **no write request**; per-date and per-run status rules (§4), including "missing only" → `ok` and "all missing" → run `noData` |
| Error mapping | `AccessDeniedException` `invalid_token` vs `insufficient_scope`; 403 `SERVICE_DISABLED` vs plain `PERMISSION_DENIED`; 404/429/5xx; socket errors; KT `KtNetworkException` → `offline` |
| IssuePresenter | every `SyncIssue` subtype yields a non-empty Czech message with placeholders filled, plus the expected action (e.g. `ktCredentialsMissing` → open settings at KT, `sheetNotConfigured` → open settings at Tabulka, `hcPermissionMissing` → grant Health Connect types, `googleReauthRequired` → reconnect, `offline` → retry) |
| SyncController | a second request while busy is ignored; buttons and cells report disabled; busy clears after a failure; `reload()` picks up a run saved by another isolate; open issues are added and cleared per §6 |

Forgetrack tests worth adapting:

- `test/features/health_connect/hc_steps_service_test.dart`: the fake-client pattern only.
- `bushido_export_data_builder_test.dart`: keep the rounding cases, **invert** the "0 steps is a real zero" expectations.

---

## 15. Reuse map from Forgetrack

Forgetrack stays untouched; Forgelink copies files and adapts them.

| Forgetrack file | Action | Notes |
|---|---|---|
| `nutrition/data/kaloricke_tabulky_service.dart` | copy + trim | keep exceptions, constants, facade (login/restore/refresh/logout/storedEmail/fetchDaySummary); trim `KtDayNutrition` to 5 nullable values + `hasData` |
| `…/kt_session_client.dart` | copy + small changes | `part of '../kt_client.dart'` (imports live in the facade); `FlutterSecureStorage` becomes a required parameter (no `const FlutterSecureStorage()` default, which would bring back `resetOnError: true`); network errors throw `KtNetworkException` |
| `…/kt_diary_service.dart` | copy + trim | `fetchDaySummary` only, plus the sanity check; re-pointed `part of` |
| `…/kt_nutrition_parser.dart` | copy + trim | summary parsing only; make every macro nullable |
| `…/kt_service_formatter.dart` | copy + trim | `_formatDiaryDate`, `_maskEmail` (fix the empty-local-part crash), log helpers |
| `…/kt_statistics_service.dart`, KT provider, sync coordinator, Isar DB | drop | keep only the "refresh once, then retry" idea |
| `health_connect/data/health_connect_service/hc_read_client.dart` | copy | nearly as is |
| `…/hc_permission_service.dart` | copy + trim | STEPS + WEIGHT; keep the history and background methods |
| `…/hc_steps_service.dart`, `hc_body_service.dart` | rewrite | per-day aggregate; last-of-day weight (§3) |
| `sheets_export/application/google_sheets_auth_service.dart` | rewrite | same silent → interactive idea, but tokens come from `GoogleSignInPlatform.instance.clientAuthorizationTokensForScopes` with the pinned email; scope `spreadsheets` |
| `auth/data/google_auth_service.dart` | ideas only | `initialize(serverClientId)` + `authenticate()` pattern for the connect flow; mask emails in logs |
| `auth/data/google_auth_platform_adapter.dart` | drop | imports private plugin internals; the account picker workaround isn't needed (no lightweight auth on start) |
| `android/…/MainActivity.kt` (Forgetrack) | copy + trim | `openHealthConnectSettings` handler only, on channel `forgelink/system_intents` |
| `sheets_export/data/sheets_service.dart` | copy + trim | `readRange` with render options; add `batchUpdate` of values; drop the create/format/clear helpers and the swallowed errors |
| `coach_log_export/data/bushido_a1_notation.dart` | copy as is | `columnLetter` |
| `coach_log_export/data/bushido_sheets_service.dart` | **drop** | writes `''` for null (clears cells), writes column A, creates blocks, applies formatting; all of these are forbidden here |
| `coach_log_export/data/bushido_export_data_builder.dart` | rules only | rounding rules; do **not** copy the steps zero-fill |
| `core/logging/app_log.dart` | copy + trim | no Sentry; new prefix; ring buffer sink |
| `core/errors/app_error.dart`, `kt_error_classifier.dart` | ideas only | replaced by `SyncIssue` |
| `core/services/background_sync_service.dart` | skeleton only (Phase 6) | entry point and registration pattern; **its return-value mapping is inverted** |
| `l10n.yaml`, `lib/l10n/l10n.dart` | copy + adjust | template `app_cs.arb`; ARB contents not copied |
| `android/app/src/main/AndroidManifest.xml` | copy + trim | Health Connect entries only (§12) |

---

## 16. Open decisions

Each has a default the plan already assumes. Change any of them before the phase it affects.

1. **GCP project** (Phase 0): **new "Forgelink" project** (default) or reuse `forgetracker-493415`.
2. **Calendar tap on today** (Phase 4): **weight only** (default), or all fields with partial-day values.
3. **A macro of 0 on a logged day** (Phase 2): **write 0** (default, a real zero), or treat it as missing.
4. **Drive chooser** (Phase 7): do it later with `drive.metadata.readonly` (default), or skip it entirely.

---

## 17. Risks

| Risk | Mitigation |
|---|---|
| Value writes into Sheets *Tables* have no explicit documentation | Phase 5 dry run on the test copy; formula guard; Table header check |
| Coach changes the layout (renames the tab, moves columns, duplicates a week) | Table header validation → `sheetLayoutChanged`; duplicate guard; write nothing on doubt |
| The health plugin hides errors as empty/0/null | Mandatory preflight; 0 = missing, `null` = failure; never write on empty |
| Steps double counting or the all-day-record quirk | Aggregate API (de-duplicated by priority); Phase 5 comparison against Samsung Health |
| KT unofficial API changes, session-expiry shape unknown, macro codes may depend on the KT dashboard widget set | Sanity check → refresh; nullable codes; captured-fixture tests; KT errors stay isolated from Health Connect fields (partial sync) |
| KT energy unit could be kJ | Phase 0 confirmation |
| Google Testing-mode 7-day expiry | Publish as *In production* (unverified) from day one |
| Wrong Google account on a multi-account phone | Pinned email; account shown in settings; 403/404 message names the account |
| Background: standby buckets, hibernation, OEM killers, force-stop | Exemption + unused-app setting + OEM hints + re-register on start; manual sync always works. If device validation shows the restricted bucket still blocks runs despite the exemption, consider a home-screen widget (an active widget exempts the app). Not planned. |
| Google account mix-up on a multi-account phone | Connect flow pins the email; every token request names it (§4 step 3, §11) |
| Backup restore breaks secure storage / history window | Backup disabled (§12) |
| Background Google auth without an Activity is untested on a device | `TokenProvider` with Strategy B fallback; Phase 6 validation checklist |
| Weight column formatted as an integer by the coach | Documented; values-only rule means display is the coach's choice |

---

## Appendix A — Verified technical facts

All checked on 2026-10-15 against the plugin sources resolved in Forgetrack's `pubspec.lock`. `PUB` = `%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev`.

- **WorkManager.**
  - `workmanager_android 0.9.0+2` (`BackgroundWorker.kt`) runs each task in a new `FlutterEngine(applicationContext)`.
  - Dart `true` → `Result.success()`, `false`/`null` → `Result.retry()`, a throw → `Result.failure()` (`BackgroundWorker.kt:206-218`, `workmanager_impl.dart:323-330`).
  - Periodic work is rescheduled for the next period after a failure.
- **Background-safe plugins.** `health 13.3.1` creates its client in `onAttachedToEngine` from the application context (`HealthPlugin.kt:62-76`). It is only initialized if Health Connect was available at attach time; `getHealthConnectSdkStatus` re-initializes it (`:122-128`). Permission requests need the Activity launcher and return false without it.
- **Steps API.** `getTotalStepsInInterval` with `includeManualEntry: true` → `HealthConnectClient.aggregate(COUNT_TOTAL)`. It returns `0` with no data and `null` on an exception (`HealthDataReader.kt:~510`). The aggregate de-duplicates Activity/Sleep types across apps by priority. `includeManualEntry: false` reads one raw page with no de-duplication. `getHealthAggregateDataFromTypes` is broken on Android (argument-name mismatch, `HealthDataReader.kt:405-406`).
- **Generic Health Connect reads.** `getHealthDataFromTypes` returns an empty list when the permission is missing or on any exception (`HealthDataReader.kt:75-81, 128-134`).
- **Weight records.** Values are kg (`HealthDataConverter.kt:29-32`). `dateFrom == dateTo == record time`, built as a local `DateTime` (`health_data_point.dart:126`). Weight is not de-duplicated across apps.
- **Google auth in the background.** `google_sign_in_android 7.2.10` calls `Identity.getAuthorizationClient(applicationContext)`. An Activity is needed only when prompting (`GoogleSignInPlugin.java:72, 398-406, 435`). The public `authorizationClient` has no email; pinning one requires `GoogleSignInPlatform.instance.clientAuthorizationTokensForScopes` (`google_sign_in.dart:127, 575`).
- **`AuthClient` bridge.** `extension_google_sign_in_as_googleapis_auth 3.0.0` builds an `AuthClient` with a fake 365-day expiry and no refresh token. `googleapis_auth 2.3.0` raises `AccessDeniedException` for any `WWW-Authenticate` response (`auth_http_utils.dart:43-50`).
- **Sheets values API.** `googleapis 16.0.0`:
  - `RAW` stores values as is; `USER_ENTERED` parses strings (`sheets/v4.dart:1171-1180`);
  - `null` inside `ValueRange.values` is skipped and `''` clears the cell (`:15665-15698`);
  - `UNFORMATTED_VALUE` + `SERIAL_NUMBER` returns dates as days since 1899-12-30 (`:1025-1069`);
  - `Sheet.tables` / `Table.columnProperties` are exposed (`:12766, 13666-13822`).
- **Scopes.** `spreadsheets` is a sensitive scope and enough to edit the coach's shared sheet. `drive.file` cannot open it. `drive`, `drive.readonly` and `drive.metadata.readonly` are restricted.
- **Pinning the account.** `GoogleSignIn.instance.authorizationClient` sends `email: null`; only a `GoogleSignInAccount` from `authenticate()` carries the email (`google_sign_in.dart:127-132, 574-576`). On Android, `authenticate()` needs a `serverClientId` (`google_sign_in_android.dart:225-227`).
- **googleapis 16 call shapes.** `spreadsheets.get(String spreadsheetId, {List<String>? ranges, String? $fields})`, `values.get(spreadsheetId, range, {dateTimeRenderOption, valueRenderOption, …})`, `values.batchUpdate(BatchUpdateValuesRequest request, String spreadsheetId)` (`sheets/v4.dart:227-232, 885-889, 1080-1086`). `TableRowsProperties.footerColorStyle` marks a footer row.
- **Testing-mode expiry.** Test-user authorizations expire 7 days after consent (support.google.com/cloud/answer/15549945).
- **Secure storage.** `flutter_secure_storage 10.0.0` works from the application context in a background engine. `resetOnError` defaults to `true` (`android_options.dart:51, 83`).
- **Kalorické tabulky.** The summary endpoint alone returns kcal and all four macros. Forgetrack's sample: `foodstuffEnergyTotal 2700.0`, fiber `26.645`, protein `216.009`, carbohydrate `308.422`, fat `61.2185` (Forgetrack `docs/integrations/kt_api_reference.md:1404-1536`).
- **Android app standby and hibernation.** An app with no interaction for 8 days goes to the restricted bucket on Android 13+, where its jobs run at most once a day and only alongside other jobs. Doze-exempt apps and apps with an active widget are exempt (developer.android.com/topic/performance/appstandby). Hibernation after months unused cancels jobs (developer.android.com/topic/performance/app-hibernation).
