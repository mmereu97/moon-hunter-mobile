import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../models/scene.dart';
import '../../state/app_state.dart';
import '../widgets/compass_widget.dart';
import 'opportunities_screen.dart';
import 'scene_map_screen.dart';

/// Editor pentru o scenă: nume, fereastra de azimut și elevație (range-slidere),
/// fereastra orară (selectoare de oră) și iluminarea minimă.
/// Modificările se salvează la apăsarea butonului „Salvează".
class SceneEditorScreen extends StatefulWidget {
  final Scene scene;
  const SceneEditorScreen({super.key, required this.scene});

  @override
  State<SceneEditorScreen> createState() => _SceneEditorScreenState();
}

class _SceneEditorScreenState extends State<SceneEditorScreen> {
  late TextEditingController _name;
  late RangeValues _azimuth;
  late RangeValues _elevation;
  late int _startMin;
  late int _endMin;
  late double _minIllum;

  @override
  void initState() {
    super.initState();
    final s = widget.scene;
    _name = TextEditingController(text: s.name);
    _azimuth = RangeValues(s.azimuthMin, s.azimuthMax);
    _elevation = RangeValues(s.elevationMin, s.elevationMax);
    _startMin = s.startMinutes;
    _endMin = s.endMinutes;
    _minIllum = s.minIllumination;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startMin : _endMin;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
    );
    if (picked == null) return;
    setState(() {
      final mins = picked.hour * 60 + picked.minute;
      if (isStart) {
        _startMin = mins;
      } else {
        _endMin = mins;
      }
    });
  }

  void _apply() {
    final s = widget.scene;
    final fallback = context.read<AppState>().s.sceneFallbackName;
    s.name = _name.text.trim().isEmpty ? fallback : _name.text.trim();
    s.azimuthMin = _azimuth.start;
    s.azimuthMax = _azimuth.end;
    s.elevationMin = _elevation.start;
    s.elevationMax = _elevation.end;
    s.startMinutes = _startMin;
    s.endMinutes = _endMin;
    s.minIllumination = _minIllum;
    context.read<AppState>().updateScene();
  }

  void _save() {
    _apply();
    Navigator.of(context).pop();
  }

  void _searchOpportunities() {
    _apply();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OpportunitiesScreen(scene: widget.scene),
      ),
    );
  }

  /// Deschide harta; la întoarcere resincronizează sliderele din valorile
  /// scenei (harta poate fi completat azimutul/elevația/locația).
  Future<void> _openMap() async {
    _apply(); // păstrăm modificările curente din formular
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SceneMapScreen(scene: widget.scene)),
    );
    if (changed == true && mounted) {
      final s = widget.scene;
      setState(() {
        _azimuth = RangeValues(s.azimuthMin, s.azimuthMax);
        _elevation = RangeValues(s.elevationMin, s.elevationMax);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().s;
    final crossesMidnight = _endMin <= _startMin;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.editScene),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(s.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _name,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(labelText: s.sceneNameLabel),
          ),
          const SizedBox(height: 24),

          OutlinedButton.icon(
            icon: const Icon(Icons.map),
            label: Text(s.planOnMapButton),
            onPressed: _openMap,
          ),
          const SizedBox(height: 16),

          // Previzualizare busolă: sectorul = fereastra de azimut planificată.
          Center(
            child: CompassWidget(
              azimuth: 0,
              altitude: 0,
              moonColor: Colors.transparent,
              showMoon: false,
              windowAzMin: _azimuth.start,
              windowAzMax: _azimuth.end,
              size: 220,
            ),
          ),
          const SizedBox(height: 8),

          _RangeBlock(
            title: s.azimuthWindow,
            help: s.azimuthWindowHelp,
            values: _azimuth,
            min: 0,
            max: 360,
            unit: '°',
            labelFor: (v) => '${v.round()}°',
            onChanged: (v) => setState(() => _azimuth = v),
          ),
          _RangeBlock(
            title: s.elevationWindow,
            help: s.elevationWindowHelp,
            values: _elevation,
            min: 0,
            max: 90,
            unit: '°',
            labelFor: (v) => '${v.round()}°',
            onChanged: (v) => setState(() => _elevation = v),
          ),

          const SizedBox(height: 8),
          Text(s.timeWindow,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          Text(s.timeWindowHelp,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickTime(isStart: true),
                  child: Text(s.fromTime(Scene.minutesToHHmm(_startMin))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickTime(isStart: false),
                  child: Text(s.toTime(Scene.minutesToHHmm(_endMin))),
                ),
              ),
            ],
          ),
          if (crossesMidnight)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(s.crossesMidnight,
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.minIllumination,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              Text('${_minIllum.round()}%',
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
          Text(s.minIlluminationHelp,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
          Slider(
            value: _minIllum,
            min: 0,
            max: 100,
            onChanged: (v) => setState(() => _minIllum = v),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: Text(s.findOpportunities),
            onPressed: _searchOpportunities,
          ),
        ],
      ),
    );
  }
}

class _RangeBlock extends StatelessWidget {
  final String title;
  final String help;
  final RangeValues values;
  final double min;
  final double max;
  final String unit;
  final String Function(double) labelFor;
  final ValueChanged<RangeValues> onChanged;

  const _RangeBlock({
    required this.title,
    required this.help,
    required this.values,
    required this.min,
    required this.max,
    required this.unit,
    required this.labelFor,
    required this.onChanged,
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
            Text('${labelFor(values.start)} – ${labelFor(values.end)}',
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
        Text(help,
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        RangeSlider(
          values: values,
          min: min,
          max: max,
          labels: RangeLabels(labelFor(values.start), labelFor(values.end)),
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
