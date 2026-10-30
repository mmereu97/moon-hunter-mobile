import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

import 'compass_widget.dart';

/// Învelește [CompassWidget] și îl rotește după orientarea telefonului, astfel
/// încât vârful de sus al ecranului = direcția în care ții telefonul.
/// Când punctul Lunii ajunge sus (sub indicatorul roșu), Luna e fix înainte.
///
/// Dacă dispozitivul nu are senzor (ex. emulator), rămâne cu Nordul sus.
class OrientedCompass extends StatefulWidget {
  final double azimuth;
  final double altitude;
  final Color moonColor;
  final double? riseAzimuth;
  final double emergeBand;
  final double floatStart;
  final double floatGap;
  final double size;

  const OrientedCompass({
    super.key,
    required this.azimuth,
    required this.altitude,
    required this.moonColor,
    this.riseAzimuth,
    this.emergeBand = 5,
    this.floatStart = 30,
    this.floatGap = 0.45,
    this.size = 260,
  });

  @override
  State<OrientedCompass> createState() => _OrientedCompassState();
}

class _OrientedCompassState extends State<OrientedCompass> {
  double? _heading; // grade, 0 = Nord (magnetic)
  StreamSubscription<CompassEvent>? _sub;

  @override
  void initState() {
    super.initState();
    final events = FlutterCompass.events;
    if (events != null) {
      _sub = events.listen(
        (e) {
          if (mounted) setState(() => _heading = e.heading);
        },
        onError: (_) {},
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dial = CompassWidget(
      azimuth: widget.azimuth,
      altitude: widget.altitude,
      moonColor: widget.moonColor,
      riseAzimuth: widget.riseAzimuth,
      emergeBand: widget.emergeBand,
      floatStart: widget.floatStart,
      floatGap: widget.floatGap,
      size: widget.size,
    );

    final h = _heading;
    // Fără senzor (emulator): Nordul sus, fără rotire.
    if (h == null) return dial;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotim cadranul invers față de telefon, ca sus să fie direcția privirii.
          Transform.rotate(angle: -h * math.pi / 180, child: dial),
          // Indicator fix "înainte" (direcția în care ții telefonul).
          const Align(
            alignment: Alignment.topCenter,
            child: Icon(Icons.arrow_drop_down,
                color: Colors.redAccent, size: 36),
          ),
        ],
      ),
    );
  }
}
