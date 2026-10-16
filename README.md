# Forgelink

A small Android utility for personal use. It copies daily data from **Health Connect** (weight, steps) and **Kalorické tabulky** (kcal, protein, carbs, fat, fiber) into the nutrition coach's existing Google Sheet — no manual copying.

It writes **values only**, into the row whose date matches, and never touches the date column, the manual columns (hunger, hydration, training, notes), formulas or formatting. Missing data is never written as 0 or blank; repeated syncs give the same result.

Status: **all planned phases shipped (2026-10-16).** Open setup items: [docs/status.md](docs/status.md). Design record: [docs/archive/implementation_plan.md](docs/archive/implementation_plan.md).

## What it does

- **Quick Sync** — one button: yesterday in full plus today's weight.
- **Calendar** — tap a day to sync it; hold for its per-field detail (value and state of every cell); hold and drag to sync a range (with a confirmation); swipe between months. "Období" opens a range screen with presets (last 3 / 7 days, this month).
- **Sheet status** — the calendar colours come from the sheet itself (read on open / resume and after every sync, cached for offline): green = everything filled (steps optional), amber = partly, red = a failed sync or a duplicated date. The day detail shows the values that are in the sheet.
- **Progress sheet** — Quick Sync and range syncs show a per-day progress sheet (can be swiped away; the sync continues) with the result and "Otevřít tabulku".
- **First launch** — a 5-step setup (Health Connect, Kalorické tabulky, Google + sheet, automatic sync), shown only while nothing is configured.
- **Queue + background-safe** — taps during a running sync are queued and merged; a foreground service keeps a sync running when you leave the app.
- **Automatic sync** — about **00:30** (the finished day) and **12:30** (after the morning weigh-in), each re-syncing the last 3 days plus today's weight, with a notification afterwards (success notifications can be turned off).
- **Clear errors** — Czech messages with a direct action (open the right Settings section, grant a permission, reconnect Google, retry); unresolved problems stay on Home until fixed.
- **Settings** — Health Connect permissions (incl. history and background reading), Kalorické tabulky login, Google account, destination sheet (paste a link or "Vybrat z Google Disku"), automatic sync, diagnostics log (own screen, filterable).
- Light/dark theme from the design handoff (Manrope font, `lib/ui/theme.dart` tokens); Czech UI via ARB.

### How it finds the right cells

The coach's `tracker` tab is a stack of weekly Google Sheets **Tables**. Forgelink reads the Table metadata, recognizes weekly tables by their `DATUM` column and maps every field by its **header name in that table** (older weeks use different column orders). A date that appears twice, a table missing a header, or a date outside every weekly table is reported and never written.

## Setup

1. **Google Cloud** project `forgelink-511721`: Sheets API and Drive API enabled; OAuth consent screen with scopes `spreadsheets` and `drive.metadata.readonly`; Android OAuth client for `com.knejp.forgelink` + debug SHA-1; Web client whose ID is `AppConfig.googleWebClientId`. While the consent screen is in Testing, re-connect Google weekly (see [docs/status.md](docs/status.md)).
2. **Health Connect** installed; grant steps + weight (and optionally history and background reading) in Settings.
3. In the app: Kalorické tabulky login → connect Google → pick the sheet → Ověřit → optionally enable automatic sync and the battery exemption.

## Development

```bash
flutter pub get
flutter gen-l10n   # after editing lib/l10n/app_cs.arb
flutter analyze
flutter test
flutter run        # or VS Code: "Forgelink (debug)"
```

VS Code tasks (Terminal → Run Task) cover analyze, test, gen-l10n, building/installing the debug APK and device logs. In debug builds, Settings → Diagnostika has **"Test synchronizace na pozadí"**, which runs the background worker once 10 s later so it can be observed with the app closed.

## Layout

```
lib/
  core/        config, logging (+ persisted ring buffer), LocalDate, prefs/secure storage, SyncIssue, native intents
  sources/     health/ (Health Connect) · kt/ (Kalorické tabulky client, ported from Forgetrack)
  sheets/      Google auth (pinned account), Sheets gateway + error mapping, TrackerIndex, WritePlan, Drive chooser
  sync/        SyncEngine (one run), SyncController (queue), SyncHistory, integration status
  background/  WorkManager scheduling + headless worker, result notifications
  ui/          home (calendar, sync card, day detail), settings, history, theme, widgets
android/       MainActivity (system-intents channel), SyncForegroundService
```

Forgelink reuses proven pieces of [Forgetrack](../Forgetrack) (Health Connect reading, the Kalorické tabulky client, Google Sheets access) without depending on it.
