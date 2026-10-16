# Forgelink — Status

Working-state doc: what is open right now. The full design record (why things are the way they are) is [archive/implementation_plan.md](archive/implementation_plan.md).

**2026-10-16 — 1.0.0 in daily use.** All planned phases shipped (see the "What shipped" block at the top of the archived plan), followed by the redesign, the sheet status, calm error handling and the first release build. Done today:

- Synced against the coach's real sheet (switched in Settings → Tabulka).
- OAuth consent screen of `forgelink-511721` published **In production** (unverified): authorizations no longer expire after 7 days. Homepage + privacy policy on GitHub Pages ([index.html](index.html), [privacy.html](privacy.html)); Search Console verification of `tknejp.github.io` failed and isn't needed for an unverified app.
- Release signing: release keystore outside the repo, `android/key.properties` (gitignored), second Android OAuth client with the release SHA-1. 1.0.0 installed from the release APK.
- GitHub Releases: pushing a `v*` tag builds a signed APK in GitHub Actions (see README → Releases).

## Open

### Device checks still not observed

- [ ] A scheduled 00:30 / 12:30 run firing on its own (the test button proved the worker; the timer not yet).
- [ ] After a reboot, the next scheduled run fires without opening the app.
- [ ] Automatic retry after a connection problem: the dates wait ("Čeká na připojení"), the retry runs once online and notifies; a manual sync of those dates cancels it.
- [ ] Steps total matches Samsung Health's daily total for a few days (Health Connect de-duplication by source priority).

### Releases

- [ ] Add the four signing secrets to the GitHub repo (README → Releases) and push the first tag.

## Known limitations (by design)

- A day with genuinely 0 steps can't be told apart from "no data" (Health Connect can't store 0-count records) and is left blank; "Kompletní" therefore doesn't require steps.
- Weight comes from the last reading of the local day; a weigh-in after 12:30 lands with the 00:30 run.
- Nutrition logged after 12:30 for an earlier day is only picked up by the next runs within the 3-day lookback.
- If the coach renames a header or tab, the affected dates are refused (`SheetLayoutChanged` / `SheetTabMissing`) rather than guessed.
- "Kompletní" means the cells are filled, not that they match the sources (a value typed by hand counts as filled).
- Background runs can be moved by Android by minutes (Doze); force-stopping the app cancels them until it is opened again.
- Updates are installed by hand (APK from GitHub Releases); a new signing key would require uninstalling — keep the keystore backed up.
