# Architecture

This document describes how **Moon Hunter** is put together. For quick
contributor rules see `AGENTS.md`; for the user‑facing overview see `README.md`.

## Goals

- Compute the Moon's position, phase and distance **locally** (offline, instant).
- Keep the astronomy engine swappable behind an interface.
- Drive everything from a single observable store so the UI stays in sync as
  time advances or the user shifts time.

## Layers

```
            ┌─────────────────────────────────────────────┐
   UI       │ main.dart (home)  +  ui/screens  +  ui/widgets│
            └───────────────▲─────────────────────┬─────────┘
                            │ watch/read           │ navigate
            ┌───────────────┴─────────────────────▼─────────┐
   State    │            AppState (ChangeNotifier)           │
            │  location · time‑shift · compass tuning ·      │
            │  scenes · profiles · language · notifications  │
            └───┬───────────────┬───────────────┬───────────┘
                │               │               │
   Services ┌───▼────┐   ┌──────▼──────┐  ┌──────▼─────────┐
            │Astronomy│   │Opportunity  │  │Notification    │
            │Service  │   │Service      │  │Service         │
            └───┬─────┘   └─────────────┘  └────────────────┘
                │
   Engine  ┌────▼───────────────┐
            │ apsl_sun_calc       │  (pure‑Dart Suncalc)
            └─────────────────────┘

   Data     SettingsRepository  ⇄  moon_settings.json
   Models   plain data classes (no logic-heavy dependencies)
```

## Core (`lib/core`)

- **`constants.dart`** — perigee/apogee thresholds and total range used for the
  distance rating; the color palette (`AppColors`), including the time‑direction
  background tints (sepia past, purple future) and the rating colors.
- **`theme.dart`** — the dark Material theme.
- **`strings.dart`** — `AppLang { ro, en }` and the `S` class. Every UI string is
  a getter/method returning the right language via a private `_t(ro, en)` helper.
  Composite lines (e.g. phase/distance sentences, the scene summary) are methods
  so grammar stays correct per language.

## Models (`lib/models`)

- **`moon_info.dart`**
  - `MoonPosition { altitude, azimuth }` (degrees; azimuth 0 = N).
  - `DistanceStatus { perigeu, apogeu, intermediar }`.
  - `MoonDistance` — from a distance in km computes a 1–10 `rating`, a `status`
    and a `color`. Rating 10 ≈ perigee ("supermoon"), 1 ≈ apogee.
  - `MoonPhase { illumination, ageDays }` with `imageIndex = ageDays.round() % 30`
    and `imageAsset`.
  - `FullMoonRating { date, distance }`.
- **`scene.dart`** — `Scene`: id, name, lat/lon, `azimuthMin/Max`,
  `elevationMin/Max`, `startMinutes/endMinutes` (minutes from midnight; if
  end ≤ start the window crosses midnight), `minIllumination`. JSON in/out.
- **`opportunity.dart`** — `Opportunity`: the matching window (`start`/`end`),
  the `bestMoment` (peak elevation) with its altitude/azimuth, peak
  `illumination`, and the `MoonDistance` at that moment. A computed result, not
  persisted.
- **`location_profile.dart`** — a saved named location.

## Services (`lib/services`)

- **`astronomy_service.dart`** — the interface the rest of the app depends on:
  `moonPosition`, `moonDistance`, `moonPhase`, `snapshot`, `nextMoonTimes`,
  `nextFullMoons`, plus `MoonSnapshot` and `MoonTimes`.
- **`suncalc_astronomy_service.dart`** — the implementation over
  `apsl_sun_calc`. Important details:
  - Suncalc returns azimuth in radians measured from **south→west**; it is
    converted to compass degrees with `(rad * 180 / pi + 180) % 360`.
  - Suncalc includes atmospheric refraction (the original Python `skyfield`
    did not), so elevations differ slightly — accepted as negligible.
  - Rise/set are found by scanning for altitude zero‑crossings; full moons by
    scanning for the phase‑0.5 crossing.
- **`opportunity_service.dart`** — the scanner. For a scene over N days:
  1. Step every 15 minutes. If the step is outside the scene's time window,
     skip immediately (no astronomy) — the key speed‑up.
  2. Otherwise check azimuth ∈ window (wrap‑aware), elevation ∈ window,
     illumination ≥ minimum.
  3. Accumulate contiguous matching steps into intervals, tracking the peak
     elevation moment and max illumination.
  4. Group intervals on consecutive calendar days and keep the
     max‑illumination night per group.
  It yields control periodically and reports progress so the UI stays responsive.
- **`notification_service.dart`** — wraps `flutter_local_notifications`:
  initialises timezones (`Europe/Bucharest`), requests the Android 13+
  permission, and schedules/cancels notifications. Uses
  `AndroidScheduleMode.inexactAllowWhileIdle` (no exact‑alarm permission) and
  caps at 50 future items.

## State (`lib/state/app_state.dart`)

`AppState extends ChangeNotifier` is the single source of truth. It holds the
current location, the time‑shift offset and direction, compass tuning, the scene
and profile lists, the language and the notifications flag. It exposes `s` (the
current `S`) and a cached `MoonSnapshot`/`MoonTimes`.

- A **1‑second ticker** advances the reference time and periodically recomputes
  rise/set; the snapshot getters call the `AstronomyService` for the current
  reference time.
- **Time‑shift** sets a `TimeDirection { real, past, future }` used to tint the
  whole app.
- Scene CRUD persists and, if notifications are on, calls `refreshNotifications`.
- `refreshNotifications` scans each scene 120 days ahead, builds `NotifItem`s
  ~30 min before each opportunity, and hands them to the `NotificationService`.
- All mutations call `_persist()` (write JSON) and `notifyListeners()`.

## Data (`lib/data/settings_repository.dart`)

Loads/saves `moon_settings.json` (via `path_provider`). `main()` is async: it
loads the saved map first, then constructs `AppState` with it. Persisted keys are
listed in `AGENTS.md`. The active time‑shift moment is deliberately not saved, so
the app always opens in real time.

## UI (`lib/ui`, `main.dart`)

- **`main.dart`** — `MoonHunterApp` → `DemoHome`. The home screen is a
  `Selector<AppState, (TimeDirection, AppLang)>` so it rebuilds only when the
  time direction or language changes; the background tints accordingly. Body:
  `CompassSection` → `TimeShiftWidget` → `PhaseSection` → `LocationInput`. The
  app bar links to About, Scenes, Full‑moon ratings and Settings.
- **`ui/widgets/compass_widget.dart`** — the polar plot. Angle = azimuth, radial
  distance = elevation. The Moon disc sits tangent at the horizon ("rising out of
  the sea"), then floats outward toward the zenith; three tuning parameters
  (`emergeBand`, `floatStart`, `floatGap`) shape this. Fine 6° ticks, 30° azimuth
  numbers and N/E/S/V letters. An optional translucent wedge shows a scene's
  azimuth window (planning mode, `showMoon: false`).
- **`ui/widgets/oriented_compass.dart`** — wraps the compass and rotates it by the
  device heading (`flutter_compass`); falls back to north‑up without a sensor.
- **`ui/widgets/time_shift_widget.dart`** — collapsible time scrubber.
- **`ui/screens/`** — scenes list, scene editor (with a north‑up compass preview
  of the azimuth window), opportunities (progress + results), map planner
  (`flutter_map`, two pins, bearing/distance, GPS), full‑moon ratings, compass
  tuning, settings, and the about dialog.

## Data flow example

1. The ticker advances the reference time and calls `notifyListeners()`.
2. `CompassSection`/`PhaseSection` (`context.watch<AppState>()`) rebuild.
3. They read `state.snapshot`, which asks the `AstronomyService` for the Moon's
   position/phase/distance at the reference time.
4. The compass repaints; phase image and distance update.
5. Shifting time or changing language flips the `Selector` value and re‑tints /
   re‑translates the screen.
