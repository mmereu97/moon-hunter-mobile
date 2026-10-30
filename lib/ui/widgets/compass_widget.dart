import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/constants.dart';

/// Busola ca grafic polar: unghiul = azimutul, distanța față de centru = elevația.
///
/// Cercul = orizontul, cu gradații fine (la 6°) și numere de azimut (la 30°),
/// ca să poți citi exact între ce grade pică Luna. Pragurile [emergeBand],
/// [floatStart], [floatGap] controlează cum se raportează discul Lunii la orizont.
class CompassWidget extends StatelessWidget {
  final double azimuth;
  final double altitude;
  final Color moonColor;
  final double? riseAzimuth;
  final double size;
  final double emergeBand;
  final double floatStart;
  final double floatGap;

  /// Mod planificare: ascunde Luna și desenează fereastra de azimut a scenei.
  final bool showMoon;
  final double? windowAzMin;
  final double? windowAzMax;

  const CompassWidget({
    super.key,
    required this.azimuth,
    required this.altitude,
    required this.moonColor,
    this.riseAzimuth,
    this.size = 260,
    this.emergeBand = 5,
    this.floatStart = 30,
    this.floatGap = 0.45,
    this.showMoon = true,
    this.windowAzMin,
    this.windowAzMax,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CompassPainter(
          azimuth: azimuth,
          altitude: altitude,
          moonColor: moonColor,
          riseAzimuth: riseAzimuth,
          emergeBand: emergeBand,
          floatStart: floatStart,
          floatGap: floatGap,
          showMoon: showMoon,
          windowAzMin: windowAzMin,
          windowAzMax: windowAzMax,
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final double azimuth;
  final double altitude;
  final Color moonColor;
  final double? riseAzimuth;
  final double emergeBand;
  final double floatStart;
  final double floatGap;
  final bool showMoon;
  final double? windowAzMin;
  final double? windowAzMax;

  _CompassPainter({
    required this.azimuth,
    required this.altitude,
    required this.moonColor,
    required this.riseAzimuth,
    required this.emergeBand,
    required this.floatStart,
    required this.floatGap,
    required this.showMoon,
    required this.windowAzMin,
    required this.windowAzMax,
  });

  static const double _moonDotR = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        math.min(size.width, size.height) / 2 / (1 + floatGap) - 10;
    final visible = altitude > 0;

    // "Pământul": disc întunecat.
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF181818));

    // Inelul orizontului.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white24,
    );

    // Gradații: fine la 6°, majore la 30°.
    for (int a = 0; a < 360; a += 6) {
      final major = a % 30 == 0;
      final inner = major ? radius - 10 : radius - 5;
      canvas.drawLine(
        _pos(center, inner, a.toDouble()),
        _pos(center, radius, a.toDouble()),
        Paint()
          ..color = major ? Colors.white54 : Colors.white24
          ..strokeWidth = major ? 1.5 : 1,
      );
    }

    // Fereastra de azimut a scenei (mod planificare): sector colorat.
    if (windowAzMin != null && windowAzMax != null) {
      final span = _azSpan(windowAzMin!, windowAzMax!);
      final steps = math.max(2, (span / 3).ceil());
      final path = Path()..moveTo(center.dx, center.dy);
      for (int i = 0; i <= steps; i++) {
        final az = windowAzMin! + span * i / steps;
        final p = _pos(center, radius, az);
        path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = AppColors.accent.withAlpha(80));
      // Marginile sectorului.
      for (final az in [windowAzMin!, windowAzMax!]) {
        canvas.drawLine(
          center,
          _pos(center, radius, az),
          Paint()
            ..color = AppColors.accentHover
            ..strokeWidth = 2,
        );
      }
    }

    // Etichete la fiecare 30°: litere la cardinale, numere în rest.
    // Stau în interior când Luna e răsărită, în exterior când e sub orizont.
    final labelR = visible ? radius - 22 : radius + 14;
    for (int a = 0; a < 360; a += 30) {
      final isCardinal = a % 90 == 0;
      final text = switch (a) {
        0 => 'N',
        90 => 'E',
        180 => 'S',
        270 => 'V',
        _ => '$a',
      };
      _label(canvas, center, labelR, a.toDouble(), text,
          fontSize: isCardinal ? 15 : 11,
          color: isCardinal ? Colors.white : Colors.white54,
          bold: isCardinal);
    }

    // Punct central.
    canvas.drawCircle(center, 3, Paint()..color = Colors.white38);

    // Marcajul de răsărit (când Luna e sub orizont): pe cerc.
    if (!visible && riseAzimuth != null) {
      canvas.drawCircle(
        _pos(center, radius, riseAzimuth!),
        6,
        Paint()..color = moonColor,
      );
    }

    // Luna.
    if (showMoon) {
      final moonR = _radiusForElevation(radius, altitude);
      final moonPos = _pos(center, moonR, azimuth);
      final currentColor = visible ? moonColor : AppColors.moonBelowHorizon;

      canvas.drawLine(
        center,
        moonPos,
        Paint()
          ..color = currentColor
          ..strokeWidth = 2,
      );
      canvas.drawCircle(moonPos, _moonDotR, Paint()..color = currentColor);
    }
  }

  /// Mărimea în grade a sectorului de azimut (gestionează trecerea prin 0/360).
  double _azSpan(double min, double max) =>
      max >= min ? max - min : (360 - min) + max;

  /// Mapează elevația la raza centrului discului Lunii.
  double _radiusForElevation(double r, double elevationDeg) {
    final e = elevationDeg.clamp(-90.0, 90.0);
    final gap = r * floatGap;

    if (e >= floatStart) {
      final t = (e - floatStart) / (90 - floatStart);
      return r + _moonDotR + t * gap;
    } else if (e >= emergeBand) {
      return r + _moonDotR;
    } else if (e >= -emergeBand) {
      return r + (e / emergeBand) * _moonDotR;
    } else {
      final t = (-e - emergeBand) / (90 - emergeBand);
      return r - _moonDotR - t * gap;
    }
  }

  Offset _pos(Offset center, double rad, double azimuthDeg) {
    final angle = (90 - azimuthDeg) * math.pi / 180;
    return Offset(
      center.dx + rad * math.cos(angle),
      center.dy - rad * math.sin(angle),
    );
  }

  void _label(Canvas canvas, Offset center, double r, double azimuthDeg,
      String t,
      {required double fontSize, required Color color, required bool bold}) {
    final p = _pos(center, r, azimuthDeg);
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_CompassPainter old) =>
      old.azimuth != azimuth ||
      old.altitude != altitude ||
      old.moonColor != moonColor ||
      old.riseAzimuth != riseAzimuth ||
      old.emergeBand != emergeBand ||
      old.floatStart != floatStart ||
      old.floatGap != floatGap ||
      old.showMoon != showMoon ||
      old.windowAzMin != windowAzMin ||
      old.windowAzMax != windowAzMax;
}
