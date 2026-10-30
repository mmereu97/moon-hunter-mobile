# 🌙 Moon Hunter

**A moon‑photography planner for Android, built with Flutter.**

Moon Hunter tells you *where* and *when* the Moon will be, so you can plan shots
like "the full Moon rising behind that ridge" or "the Moon framed in the top of
the fir tree, seen from my window". It computes the Moon's position, phase,
distance and rise/set entirely on‑device — no accounts, no network calls, no ads.

It is a Flutter rewrite of my earlier [Python/PyQt5 app](https://github.com/mmereu97/Moonhunter), redesigned
around a live **polar compass** that shows the Moon "rising out of the sea" at
the horizon and floating up toward the zenith.

> Concept parity with commercial tools like PhotoPills, The Photographer's
> Ephemeris and Sun Surveyor — but free, offline and open.

---

## Features

- **Live sky compass** — a polar plot where the angle is the Moon's azimuth and
  the radial distance is its elevation. Fine degree graduations let you read the
  exact direction. Rotates with the phone (magnetometer) or stays north‑up.
- **Phase & distance** — current phase image (30 frames), illumination, and the
  Earth–Moon distance with a 1–10 "supermoon" rating (green/yellow/red).
- **Time Shift** — scrub time backward/forward (day/hour/minute or pick a date);
  the whole app tints sepia for the past and purple for the future.
- **Scenes** — save a shot as a set of conditions: azimuth window, elevation
  window, time window and minimum illumination.
- **Opportunity search** — scans a full year in 15‑minute steps (locally, almost
  instantly) and lists every night the Moon meets a scene's conditions.
- **Map planning** — place two pins (your spot + a target) on an OpenStreetMap /
  satellite map; the app computes the exact azimuth and distance, and the
  elevation needed to align the Moon with the target's top.
- **Full‑moon ratings** — the next 12 full moons ranked by closeness to perigee.
- **Location profiles** — save and switch between shooting spots.
- **Notifications** — optional alerts ~30 minutes before a matching opportunity.
- **Bilingual** — full Romanian/English UI, remembered between launches.

---

## How it works

The astronomy is computed locally with a pure‑Dart Suncalc port
(`apsl_sun_calc`), hidden behind an `AstronomyService` interface so the engine
can later be swapped for a higher‑precision ephemeris. Because everything is
local maths (no per‑step HTTP calls like the original Python app), scanning a
whole year of opportunities finishes in well under a second.

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for the full design and
[`AGENTS.md`](AGENTS.md) for contributor/agent guidance.

---

## Known limitations

- **Earth–Moon distance is approximate.** The Suncalc engine uses a simplified distance formula: on the 5 November 2025 supermoon it gives about 364,200 km against the published ~356,800 km (about 2% off). Position and phase are accurate enough for planning, but the supermoon rating and the full-moon ranking should be read as indicative. The engine sits behind the `AstronomyService` interface, so a higher-precision ephemeris (e.g. Meeus' lunar theory) can replace it without touching the UI.

## Tests

`flutter test` checks the engine against published events: the full moon of 5 November 2025, the new moon of 20 November 2025, the next-full-moon search and the range of every computed sky position.

---

## Tech stack

| Area | Choice |
| --- | --- |
| Framework | Flutter (Dart 3) |
| State | `provider` + a central `ChangeNotifier` (`AppState`) |
| Astronomy | `apsl_sun_calc` (pure‑Dart Suncalc) |
| Maps | `flutter_map` (OSM + Esri satellite, no API key) |
| Location | `geolocator` |
| Compass sensor | `flutter_compass` |
| Notifications | `flutter_local_notifications` + `timezone` |
| Persistence | JSON file via `path_provider` |
| Icons | `flutter_launcher_icons` |

---

## Getting started

Prerequisites: a recent Flutter SDK and an Android device/emulator.

```bash
git clone https://github.com/mmereu97/moon-hunter-mobile.git
cd moon-hunter-mobile
flutter pub get
flutter run
```

Build a release APK:

```bash
flutter build apk --release
```

Regenerate the launcher icon (after editing `assets/icon/`):

```bash
dart run flutter_launcher_icons
```

### Android notes

- `flutter_local_notifications` requires **core library desugaring**; this is
  enabled in `android/app/build.gradle.kts`.
- Required permissions (in `android/app/src/main/AndroidManifest.xml`):
  `INTERNET` (map tiles), `ACCESS_FINE/COARSE_LOCATION` (GPS),
  `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED` (alerts).
- iOS icon generation is disabled (`ios: false`) because the project is
  developed on Windows; re‑enable it on macOS if you target iOS.

---

## Project structure

```
lib/
  core/        constants, theme, strings (i18n)
  models/      MoonPosition, MoonDistance, MoonPhase, Scene, Opportunity, ...
  services/    astronomy, opportunity scanning, notifications
  state/       AppState (ChangeNotifier)
  data/        JSON settings repository
  ui/
    screens/   scenes, editor, opportunities, map, settings, ...
    widgets/   compass, oriented compass, moon image, time shift
  main.dart    entry point + home screen
assets/
  moon/        luna_0.png .. luna_29.png (phase frames)
  icon/        launcher icon sources
```

---

## Roadmap ideas

- Magnetic declination correction (compass uses magnetic vs. true north).
- Terrain elevation (DEM) for aligning with distant mountains.
- Higher‑precision ephemeris behind the existing `AstronomyService`.
- Localized native date/time pickers.

---

## Author

**Mereu Mihai** — mihaimereu97@gmail.com

A personal learning project. If you reuse it, a mention is appreciated.
Consider adding a `LICENSE` file (e.g. MIT) before publishing.
