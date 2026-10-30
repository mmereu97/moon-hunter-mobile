import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/strings.dart';
import 'core/theme.dart';
import 'data/settings_repository.dart';
import 'models/location_profile.dart';
import 'models/moon_info.dart'; // pentru extension-ul `.label` pe DistanceStatus
import 'services/suncalc_astronomy_service.dart';
import 'state/app_state.dart';
import 'ui/screens/app_info_dialog.dart';
import 'ui/screens/full_moon_ratings_screen.dart';
import 'ui/screens/scenes_list_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/widgets/moon_image.dart';
import 'ui/widgets/oriented_compass.dart';
import 'ui/widgets/time_shift_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Încărcăm setările salvate înainte de a porni aplicația.
  final repo = SettingsRepository();
  final saved = await repo.load();

  runApp(
    ChangeNotifierProvider(
      create: (_) =>
          AppState(SunCalcAstronomyService(), repo: repo, saved: saved),
      child: const MoonHunterApp(),
    ),
  );
}

class MoonHunterApp extends StatelessWidget {
  const MoonHunterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moon Hunter',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const DemoHome(),
    );
  }
}

class DemoHome extends StatelessWidget {
  const DemoHome({super.key});

  @override
  Widget build(BuildContext context) {
    // Fundalul se schimbă cu direcția timpului; reacționăm și la limbă.
    return Selector<AppState, (TimeDirection, AppLang)>(
      selector: (_, s) => (s.timeDirection, s.lang),
      builder: (context, data, _) {
        final dir = data.$1;
        final s = S(data.$2);
        final bg = switch (dir) {
          TimeDirection.real => AppColors.background,
          TimeDirection.past => AppColors.backgroundPast,
          TimeDirection.future => AppColors.backgroundFuture,
        };
        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            title: const Text('Moon Hunter'),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: s.about,
                onPressed: () => showAppInfo(context),
              ),
              IconButton(
                icon: const Icon(Icons.photo_camera_outlined),
                tooltip: s.scenes,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ScenesListScreen(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.nightlight_round),
                tooltip: s.fullMoonRatings,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FullMoonRatingsScreen(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: s.settings,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
              ),
            ],
          ),
          body: const SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 6, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vedeta 1: busola.
                CompassSection(),
                SizedBox(height: 8),
                // Time Shift (colapsabil) — chiar sub busolă, ca s-o vezi
                // reacționând în timp ce derulezi timpul.
                TimeShiftWidget(),
                SizedBox(height: 8),
                // Vedeta 2: faza Lunii.
                PhaseSection(),
                SizedBox(height: 16),
                // Control rar folosit, jos de tot.
                LocationInput(),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Formatează o oră (HH:mm), adăugând data dacă e în altă zi.
String _fmtTime(DateTime? dt) {
  if (dt == null) return '—';
  final local = dt.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  final now = DateTime.now();
  final sameDay = local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  if (sameDay) return '$hh:$mm';
  final dd = local.day.toString().padLeft(2, '0');
  final mo = local.month.toString().padLeft(2, '0');
  return '$hh:$mm ($dd/$mo)';
}

/// Vedeta 1: busola (poziția Lunii) + statistici.
class CompassSection extends StatelessWidget {
  const CompassSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.s;
    final snap = state.snapshot;
    final pos = snap.position;
    final dist = snap.distance;
    final times = state.moonTimes;

    final contentWidth = MediaQuery.of(context).size.width - 40;
    final compassSize = contentWidth.clamp(240.0, 400.0);

    return Column(
      children: [
        OrientedCompass(
          azimuth: pos.azimuth,
          altitude: pos.altitude,
          moonColor: dist.color,
          riseAzimuth: state.riseAzimuth,
          emergeBand: state.compassEmergeBand,
          floatStart: state.compassFloatStart,
          floatGap: state.compassFloatGap,
          size: compassSize,
        ),
        const SizedBox(height: 4),
        Text(
          s.elevAzLine(
              pos.altitude.toStringAsFixed(1), pos.azimuth.toStringAsFixed(1)),
          style: const TextStyle(color: Colors.white70),
        ),
        Text(
          pos.isVisible ? s.moonVisible : s.moonBelow,
          style: TextStyle(
              color: pos.isVisible ? Colors.greenAccent : Colors.white54),
        ),
        const SizedBox(height: 4),
        Text(
          s.riseSetLine(_fmtTime(times.nextRise), _fmtTime(times.nextSet)),
          style: const TextStyle(color: Colors.white70),
        ),
        if (state.riseAzimuth != null)
          Text(
            s.risesAtAzimuth(state.riseAzimuth!.toStringAsFixed(1)),
            style: const TextStyle(color: Colors.white70),
          ),
      ],
    );
  }
}

/// Vedeta 2: faza Lunii (imagine) + distanță/rating.
class PhaseSection extends StatelessWidget {
  const PhaseSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.s;
    final snap = state.snapshot;
    final phase = snap.phase;
    final dist = snap.distance;

    final contentWidth = MediaQuery.of(context).size.width - 40;
    final moonSize = (contentWidth * 0.62).clamp(180.0, 300.0);

    return Column(
      children: [
        MoonImage(phase: phase, size: moonSize),
        const SizedBox(height: 12),
        Text(
          s.phaseLine(phase.isWaning, phase.illumination.round()),
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          s.moonAgeLine(phase.ageDays.toStringAsFixed(1), phase.imageIndex),
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        Text(
          s.distanceLine(
              dist.distanceKm.toStringAsFixed(0), dist.status, dist.rating),
          style: TextStyle(color: dist.color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Câmp pentru lipit coordonatele din Google Maps. Are stare proprie și NU
/// ascultă AppState la fiecare tic; doar eticheta cu coordonatele curente se
/// actualizează (prin Selector), ca să nu se reconstruiască TextField-ul.
class LocationInput extends StatefulWidget {
  const LocationInput({super.key});

  @override
  State<LocationInput> createState() => _LocationInputState();
}

class _LocationInputState extends State<LocationInput> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final state = context.read<AppState>();
    final ok = state.setLocationFromText(_controller.text);
    setState(() => _error = ok ? null : state.s.invalidFormat);
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AppState, AppLang>(
      selector: (_, st) => st.lang,
      builder: (context, lang, _) {
        final s = S(lang);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.place, size: 18, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text(s.location,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Selector<AppState, String>(
                      selector: (_, st) =>
                          '${st.latitude.toStringAsFixed(4)}, ${st.longitude.toStringAsFixed(4)}',
                      builder: (_, coords, __) => Text(
                        coords,
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(s.coordsLabel,
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: '46.9279, 26.3708',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _apply(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _apply, child: Text(s.setBtn)),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.redAccent)),
                  ),
                const SizedBox(height: 8),
                // Profiluri de locație salvate.
                const _ProfilesRow(),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Rândul cu profilurile salvate + butonul de salvare a locației curente.
/// Folosește un Selector pe numărul de profiluri, ca să se reconstruiască doar
/// la adăugare/ștergere, nu la fiecare tic de ceas.
class _ProfilesRow extends StatelessWidget {
  const _ProfilesRow();

  Future<void> _saveDialog(BuildContext context) async {
    final s = context.read<AppState>().s;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: Text(s.saveLocation,
            style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: s.nameHint),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(s.save),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty && context.mounted) {
      context.read<AppState>().saveProfile(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AppState, (int, AppLang)>(
      selector: (_, s) => (s.profiles.length, s.lang),
      builder: (context, data, __) {
        final s = S(data.$2);
        final profiles = context.read<AppState>().profiles;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final p in profiles)
              InputChip(
                label: Text(p.name),
                onPressed: () => context.read<AppState>().loadProfile(p),
                onDeleted: () => context.read<AppState>().deleteProfile(p),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: Text(s.saveLocation),
              onPressed: () => _saveDialog(context),
            ),
          ],
        );
      },
    );
  }
}
