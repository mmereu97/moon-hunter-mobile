# AGENTS.md

Guidance for AI coding agents (and human contributors) working on **Moon Hunter**.
Read this before making changes. For the deeper design, see `ARCHITECTURE.md`.

## What this project is

A Flutter (Android‑first) moon‑photography planner. It computes the Moon's
position/phase/distance locally and helps plan shots via scenes, an opportunity
scanner, a map planner and a live compass. It is a port of an older Python/PyQt5
app. The author builds with AI agents and does **not** hand‑write code, so changes should
be delivered as complete, copy‑pasteable files and explained plainly.

## Conventions

- **Comments are written in Romanian.** Keep new comments in Romanian to match.
- **All user‑facing strings are bilingual (RO/EN)** and must go through the
  `S` class in `lib/core/strings.dart`. Never hard‑code display text in a widget.
- **Code identifiers, types and method names are English.**
- Prefer small, focused widgets. Match the existing dark theme and the accent
  palette in `lib/core/constants.dart`.
- Keep prose/UI minimal and consistent with what exists; don't introduce new
  state‑management libraries.

## Architecture in one minute

Layered, with a single central store:

- `lib/core/` — `constants.dart` (thresholds, colors), `theme.dart`,
  `strings.dart` (the `S` i18n class + `AppLang`).
- `lib/models/` — plain data: `MoonPosition`, `MoonDistance`, `MoonPhase`,
  `DistanceStatus` (`moon_info.dart`), `Scene`, `Opportunity`, `LocationProfile`.
- `lib/services/` — `astronomy_service.dart` (interface) and
  `suncalc_astronomy_service.dart` (impl), `opportunity_service.dart`
  (the scanner), `notification_service.dart`.
- `lib/state/app_state.dart` — `AppState extends ChangeNotifier`. The single
  source of truth: location, time‑shift, compass tuning, scenes, profiles,
  language, notifications flag. Exposes `s` (current `S`). A 1‑second ticker
  recomputes the live snapshot.
- `lib/data/settings_repository.dart` — reads/writes `moon_settings.json`.
- `lib/ui/screens` and `lib/ui/widgets` — presentation. Home screen lives in
  `main.dart`.

UI reads state with `provider`: `context.watch<AppState>()` to rebuild,
`context.read<AppState>()` for actions. Many widgets use `Selector` to avoid
rebuilding on every tick.

## Invariants & decisions (do not break)

- **Astronomy goes through `AstronomyService`.** Don't call `apsl_sun_calc`
  directly from UI/state. Suncalc azimuth is measured from south→west in
  radians; it is converted to compass degrees (0 = N) as
  `(rad * 180 / pi + 180) % 360`. Suncalc already includes atmospheric
  refraction. Distance is geocentric.
- **Distance rating colors:** rating ≥ 8 green, ≥ 5 yellow, else red
  (`MoonDistance.color`). Higher rating = closer to perigee = "better"/bigger.
- **Phase image index** is `ageDays.round() % 30` (frames `luna_0..luna_29`);
  the modulo avoids a missing `luna_30`.
- **Opportunity scanner** (`OpportunityService`) steps every 15 minutes, skips
  steps outside a scene's time window before doing any astronomy (this is why it
  is fast), groups matching nights that are consecutive, and keeps the
  max‑illumination night per group. Azimuth/time windows may wrap (handle 0/360
  and midnight).
- **Scene azimuth window** is stored as `azimuthMin..azimuthMax` and must remain
  valid for a `RangeSlider` (start ≤ end, within 0..360). The map planner
  deliberately clamps without modulo to avoid a wrapping range near north.
- **Notifications** use *inexact* scheduling (no exact‑alarm permission needed),
  schedule ~30 min before each opportunity, scan 120 days, cap at 50, and the
  timezone is currently hard‑coded to `Europe/Bucharest` (personal app). If you
  generalize this, add `flutter_timezone` and read the device zone.
- **Persistence keys** in `moon_settings.json`: `latitude`, `longitude`,
  `location_name`, `compass_emerge`, `compass_float_start`, `compass_float_gap`,
  `timeshift_expanded`, `scenes`, `profiles`, `lang`, `notifications`. The active
  time‑shift moment is intentionally **not** persisted.

## Build & run

```bash
flutter pub get
flutter run                      # debug on device/emulator
flutter build apk --release      # release APK
dart run flutter_launcher_icons  # regenerate launcher icon
```

### Android setup that must stay in place

- `android/app/build.gradle.kts`: `isCoreLibraryDesugaringEnabled = true` in
  `compileOptions`, plus `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`
  in `dependencies` (required by `flutter_local_notifications`).
- `AndroidManifest.xml` permissions: `INTERNET`, `ACCESS_FINE_LOCATION`,
  `ACCESS_COARSE_LOCATION`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`.
- `flutter_launcher_icons` is configured with `ios: false` (developed on Windows).

### Version gotcha

`flutter_local_notifications` 18.x requires
`uiLocalNotificationDateInterpretation` in `zonedSchedule`; 19+ removed it. If you
bump the package, adjust `notification_service.dart` accordingly.

## How to add a translatable string

1. Add a getter (or method) to `S` in `lib/core/strings.dart` with
   `_t('Română', 'English')`.
2. In the widget, get `final s = context.watch<AppState>().s;` and use `s.yourKey`.
3. For widgets that must not rebuild every tick, wrap the translated part in a
   `Selector<AppState, AppLang>` and build `S(lang)` inside.

## How to add a screen

Create it under `lib/ui/screens/`, translate via `S`, and navigate with a
`MaterialPageRoute`. Reach settings‑like entries from `SettingsScreen` and the
app‑bar icons in `main.dart`.

## Known cleanup candidates

- `lib/state/astronomy_service.dart` appears to be a leftover duplicate of
  `lib/services/astronomy_service.dart`; verify imports and remove the unused one.
- `lib/models/app_settings.dart` is largely unused since persistence moved into
  `AppState` + `SettingsRepository`.
- `MoonPhase.phaseLabel` (Romanian‑only) is superseded by `S.phaseLine`.

## Testing the time‑sensitive features

- **Opportunities:** make a scene with wide conditions (azimuth 0–360, elevation
  0–90, time 00:00–23:59, illumination 0) to guarantee near‑term results.
- **Notifications:** the same wide scene plus enabling the toggle should schedule
  an alert for the next opportunity; inexact scheduling may fire a few minutes
  late, and aggressive battery optimization can delay it.
