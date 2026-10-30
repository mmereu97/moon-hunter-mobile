import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../state/app_state.dart';
import '../widgets/compass_widget.dart';

/// Ecran de reglaj fin al busolei.
///
/// Sus, o busolă de previzualizare cu o "elevație de probă" pe care o derulezi
/// manual, ca să vezi cum se așază Luna (scufundată / tangentă / plutind) la
/// orice înălțime. Mai jos, cele trei praguri reglabile. Modificările se aplică
/// instant și pe ecranul principal.
class CompassSettingsScreen extends StatefulWidget {
  const CompassSettingsScreen({super.key});

  @override
  State<CompassSettingsScreen> createState() => _CompassSettingsScreenState();
}

class _CompassSettingsScreenState extends State<CompassSettingsScreen> {
  // Elevația de probă pentru previzualizare (nu vine din astronomie).
  double _sampleElevation = 10;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.s;

    return Scaffold(
      appBar: AppBar(title: Text(s.compassTuning)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Previzualizare cu elevația de probă.
            Center(
              child: CompassWidget(
                azimuth: 45, // direcție fixă pentru previzualizare
                altitude: _sampleElevation,
                moonColor: AppColors.ratingGood,
                emergeBand: state.compassEmergeBand,
                floatStart: state.compassFloatStart,
                floatGap: state.compassFloatGap,
                size: 240,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                s.sampleElevation(_sampleElevation.toStringAsFixed(0)),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Slider(
              value: _sampleElevation,
              min: -90,
              max: 90,
              divisions: 180,
              label: '${_sampleElevation.toStringAsFixed(0)}°',
              onChanged: (v) => setState(() => _sampleElevation = v),
            ),
            const Divider(height: 32, color: Colors.white24),

            _TuningSlider(
              title: s.emergeTitle,
              help: s.emergeHelp,
              value: state.compassEmergeBand,
              min: 1,
              max: 20,
              unit: '°',
              onChanged: (v) => context.read<AppState>().setCompassTuning(emergeBand: v),
            ),
            _TuningSlider(
              title: s.floatStartTitle,
              help: s.floatStartHelp,
              value: state.compassFloatStart,
              min: 5,
              max: 60,
              unit: '°',
              onChanged: (v) => context.read<AppState>().setCompassTuning(floatStart: v),
            ),
            _TuningSlider(
              title: s.floatGapTitle,
              help: s.floatGapHelp,
              value: state.compassFloatGap,
              min: 0.1,
              max: 0.8,
              unit: '',
              decimals: 2,
              onChanged: (v) => context.read<AppState>().setCompassTuning(floatGap: v),
            ),
          ],
        ),
      ),
    );
  }
}

class _TuningSlider extends StatelessWidget {
  final String title;
  final String help;
  final double value;
  final double min;
  final double max;
  final String unit;
  final int decimals;
  final ValueChanged<double> onChanged;

  const _TuningSlider({
    required this.title,
    required this.help,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
    this.decimals = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            Text('${value.toStringAsFixed(decimals)}$unit',
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
        Text(help,
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
