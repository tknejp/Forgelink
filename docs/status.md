# Forgelink — Status

Working-state doc: what is open right now. The full design record (why things are the way they are) is [archive/implementation_plan.md](archive/implementation_plan.md).

**2026-10-16 — MVP and all optional phases shipped** (phases 1–7, see the "What shipped" block at the top of the archived plan). Everything below is setup or verification, not missing features.

## Open

### 1. Switch to the coach's real sheet (plan Phase 5)

Development has run against the test copy `<test copy ID>`.

- [ ] Check the real sheet for a duplicated week (the copy had 12.–18. 10. 2026 twice; duplicated dates are never written).
- [ ] Settings → Tabulka → "Vybrat z Google Disku" → the coach's spreadsheet → Ověřit.
- [ ] One manual sync of yesterday; check the cells (and that I–L, footer formulas and formatting are untouched) in the coach's view.

### 2. Google consent expires every 7 days

The OAuth consent screen of `forgelink-511721` is in **Testing** (test user = your Google account). Test-user authorizations expire 7 days after consent, so roughly weekly the automatic runs fail with "Přihlášení ke Googlu vypršelo" (notified); Settings → Google účet → **Znovu připojit** fixes it for another week.

- [ ] Permanent fix: publish to **In production** (unverified). Google requires a homepage URL and a privacy-policy URL on the Branding page first (two small static pages, e.g. GitHub Pages; add the domain under Authorized domains). Don't upload a logo — that forces verification.

### 3. Release build

Currently only debug builds (debug keystore) are installed.

- [ ] Create a release keystore; put its path and passwords in `android/key.properties` (gitignored).
- [ ] Add its SHA-1 as a second Android OAuth client (`com.knejp.forgelink`) in `forgelink-511721`.
- [ ] `flutter build apk --release`, install, connect Google once more.

### 4. Device checks still not observed

- [ ] A scheduled 00:30 / 12:30 run firing on its own (the test button proved the worker; the timer not yet).
- [ ] After a reboot, the next scheduled run fires without opening the app.
- [ ] Steps total matches Samsung Health's daily total for a few days (Health Connect de-duplication by source priority).

## Known limitations (by design)

- A day with genuinely 0 steps can't be told apart from "no data" (Health Connect can't store 0-count records) and is left blank.
- Weight comes from the last reading of the local day; a weigh-in after 12:30 lands with the 00:30 run.
- If the coach renames a header or tab, the affected dates are refused (`SheetLayoutChanged` / `SheetTabMissing`) rather than guessed.
- Background runs can be moved by Android by minutes (Doze); force-stopping the app cancels them until it is opened again.
