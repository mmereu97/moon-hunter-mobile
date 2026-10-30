import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../models/scene.dart';
import '../../state/app_state.dart';

/// Planificarea unei scene pe hartă, cu două pinuri:
///  - Locul de filmare (A) = de unde fotografiezi (implicit locația scenei).
///  - Ținta (B) = obiectul cu care aliniezi Luna (brad, clădire, munte).
///
/// Din cele două puncte se calculează azimutul (direcția A→B) și distanța.
/// Opțional, dacă introduci înălțimea țintei peste tine, se calculează și
/// elevația la care trebuie să fie Luna. „Aplică la scenă" completează automat
/// fereastra de azimut (și elevație) a scenei.
class SceneMapScreen extends StatefulWidget {
  final Scene scene;
  const SceneMapScreen({super.key, required this.scene});

  @override
  State<SceneMapScreen> createState() => _SceneMapScreenState();
}

enum _PlaceMode { observer, target }

class _SceneMapScreenState extends State<SceneMapScreen> {
  final _mapController = MapController();
  final _heightCtrl = TextEditingController();

  late LatLng _observer;
  LatLng? _target;
  bool _satellite = false;
  _PlaceMode _mode = _PlaceMode.target;

  static const _osm = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _esri =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  @override
  void initState() {
    super.initState();
    _observer = LatLng(widget.scene.latitude, widget.scene.longitude);
    // La deschidere, încearcă să te poziționeze pe locația GPS reală.
    WidgetsBinding.instance.addPostFrameCallback((_) => _locateMe());
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    super.dispose();
  }

  void _onTap(TapPosition _, LatLng point) {
    setState(() {
      if (_mode == _PlaceMode.observer) {
        _observer = point;
      } else {
        _target = point;
      }
    });
  }

  /// Obține locația GPS reală și centrează harta acolo. Dacă GPS-ul e oprit
  /// sau permisiunea lipsește, cere utilizatorului să le activeze.
  Future<void> _locateMe() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) _showEnableDialog();
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) _snack(context.read<AppState>().s.locationDenied);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() => _observer = LatLng(pos.latitude, pos.longitude));
      _mapController.move(_observer, 16);
    } catch (_) {
      if (mounted) _snack(context.read<AppState>().s.locationFailed);
    }
  }

  void _showEnableDialog() {
    final s = context.read<AppState>().s;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: Text(s.enableGpsTitle,
            style: const TextStyle(color: Colors.white)),
        content: Text(
          s.enableGpsBody,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(s.later),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Geolocator.openLocationSettings();
            },
            child: Text(s.settings),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Azimutul (bearing) de la A la B, în grade busolă (0 = N).
  double _bearing(LatLng a, LatLng b) {
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// Distanța A–B în metri (haversine).
  double _distanceMeters(LatLng a, LatLng b) {
    const r = 6371000.0;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  void _apply() {
    final s = widget.scene;
    s.latitude = _observer.latitude;
    s.longitude = _observer.longitude;

    if (_target != null) {
      final az = _bearing(_observer, _target!);
      const tol = 2.0;
      // Fără wrap peste 0/360, ca să rămână valid pentru RangeSlider din editor.
      s.azimuthMin = (az - tol).clamp(0.0, 360.0);
      s.azimuthMax = (az + tol).clamp(0.0, 360.0);

      final height = double.tryParse(_heightCtrl.text.replaceAll(',', '.'));
      if (height != null && height != 0) {
        final d = _distanceMeters(_observer, _target!);
        if (d > 0) {
          final el = math.atan(height / d) * 180 / math.pi;
          s.elevationMin = (el - 1).clamp(0.0, 90.0);
          s.elevationMax = (el + 1).clamp(0.0, 90.0);
        }
      }
    }

    context.read<AppState>().updateScene();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().s;
    final target = _target;
    final az = target != null ? _bearing(_observer, target) : null;
    final dist = target != null ? _distanceMeters(_observer, target) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.planOnMapTitle),
        actions: [
          IconButton(
            tooltip: _satellite ? s.mapStandard : s.satellite,
            icon: Icon(_satellite ? Icons.map : Icons.satellite_alt),
            onPressed: () => setState(() => _satellite = !_satellite),
          ),
        ],
      ),
      body: Column(
        children: [
          // Selectorul: ce pin pune următorul tap.
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Text(s.placeLabel,
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(width: 4),
                ChoiceChip(
                  label: Text(s.shootingSpot),
                  selected: _mode == _PlaceMode.observer,
                  onSelected: (_) =>
                      setState(() => _mode = _PlaceMode.observer),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(s.target),
                  selected: _mode == _PlaceMode.target,
                  onSelected: (_) => setState(() => _mode = _PlaceMode.target),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.my_location, size: 18),
                  label: Text(s.myLocation),
                  onPressed: _locateMe,
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _observer,
                initialZoom: 16,
                maxZoom: 19,
                onTap: _onTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: _satellite ? _esri : _osm,
                  maxZoom: 19,
                  userAgentPackageName: 'com.example.moonhunter',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _observer,
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.my_location,
                          color: Colors.lightBlueAccent, size: 34),
                    ),
                    if (target != null)
                      Marker(
                        point: target,
                        width: 44,
                        height: 44,
                        alignment: Alignment.topCenter,
                        child: const Icon(Icons.location_on,
                            color: Colors.redAccent, size: 40),
                      ),
                  ],
                ),
              ],
            ),
          ),
          _buildPanel(s, az, dist),
        ],
      ),
    );
  }

  Widget _buildPanel(S s, double? az, double? dist) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF232323),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (az == null)
            Text(
              s.tapToPlaceTarget,
              style: const TextStyle(color: Colors.white54),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.azimutValue(az.toStringAsFixed(1)),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text(s.distanceValue(_distLabel(dist!)),
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _heightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: s.targetHeightLabel,
                      hintText: s.targetHeightHint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              s.targetHeightHelp,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: Text(s.applyToScene),
              onPressed: az == null ? null : _apply,
            ),
          ),
        ],
      ),
    );
  }

  String _distLabel(double meters) =>
      meters >= 1000 ? '${(meters / 1000).toStringAsFixed(2)} km' : '${meters.round()} m';
}
