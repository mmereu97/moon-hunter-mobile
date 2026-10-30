import 'dart:math' as math;

// === SINGURUL loc din aplicație care depinde de biblioteca de astronomie. ===
// Dacă importul de mai jos nu se rezolvă, vezi nota din mesaj: pachetul
// `apsl_sun_calc` este derivat din `flutter_suncalc`, iar uneori importul
// corect este 'package:flutter_suncalc/flutter_suncalc.dart'. În ambele cazuri
// clasa se numește `SunCalc` și are aceleași metode.
import 'package:apsl_sun_calc/apsl_sun_calc.dart';

import '../models/moon_info.dart';
import 'astronomy_service.dart';

/// Durata medie a lunii sinodice (Lună nouă -> Lună nouă), în zile.
const double _synodicMonth = 29.530588853;

/// Implementare bazată pe suncalc (pur Dart, fără fișiere native, merge și pe web).
///
/// suncalc întoarce unghiuri în RADIANI și folosește o convenție de azimut
/// diferită de busolă (0 = Sud, crescând spre Vest). Aici facem toate
/// conversiile, astfel încât în afara acestui fișier totul e în GRADE busolă.
class SunCalcAstronomyService implements AstronomyService {
  @override
  MoonPosition moonPosition(DateTime time, double lat, double lon) {
    final pos = SunCalc.getMoonPosition(time.toUtc(), lat, lon);
    return MoonPosition(
      altitude: _toDegrees(_num(pos['altitude'])),
      azimuth: _toCompassAzimuth(_num(pos['azimuth'])),
    );
  }

  @override
  MoonDistance moonDistance(DateTime time) {
    // Distanța e geocentrică -> lat/lon nu contează, trimitem 0,0.
    final pos = SunCalc.getMoonPosition(time.toUtc(), 0, 0);
    return MoonDistance.fromKm(_num(pos['distance']));
  }

  @override
  MoonPhase moonPhase(DateTime time) {
    final illum = SunCalc.getMoonIllumination(time.toUtc());
    return _phaseFrom(illum);
  }

  @override
  MoonSnapshot snapshot(DateTime time, double lat, double lon) {
    final pos = SunCalc.getMoonPosition(time.toUtc(), lat, lon);
    final illum = SunCalc.getMoonIllumination(time.toUtc());

    return MoonSnapshot(
      time: time,
      position: MoonPosition(
        altitude: _toDegrees(_num(pos['altitude'])),
        azimuth: _toCompassAzimuth(_num(pos['azimuth'])),
      ),
      distance: MoonDistance.fromKm(_num(pos['distance'])),
      phase: _phaseFrom(illum),
    );
  }

  @override
  MoonTimes nextMoonTimes(DateTime from, double lat, double lon) {
    // Scanăm elevația din 10 în 10 minute, până la 48h în viitor, și detectăm
    // trecerile prin orizont (elevație = 0). Reutilizăm moonPosition (deja
    // testat), deci nu depindem de funcția de rise/set a bibliotecii.
    const step = Duration(minutes: 10);
    final end = from.add(const Duration(hours: 48));

    DateTime t = from;
    double prevAlt = moonPosition(t, lat, lon).altitude;
    DateTime? rise;
    DateTime? set;

    while (t.isBefore(end)) {
      final next = t.add(step);
      final alt = moonPosition(next, lat, lon).altitude;

      // neg -> poz = răsărit
      if (rise == null && prevAlt <= 0 && alt > 0) {
        rise = _refineCrossing(t, next, lat, lon, rising: true);
      }
      // poz -> neg = apus
      if (set == null && prevAlt > 0 && alt <= 0) {
        set = _refineCrossing(t, next, lat, lon, rising: false);
      }
      if (rise != null && set != null) break;

      prevAlt = alt;
      t = next;
    }

    return MoonTimes(nextRise: rise, nextSet: set);
  }

  /// Rafinează prin căutare binară momentul trecerii prin orizont între [a] și
  /// [b], până la ~secunde. [rising] = true pentru răsărit (după trecere e
  /// deasupra orizontului), false pentru apus.
  DateTime _refineCrossing(DateTime a, DateTime b, double lat, double lon,
      {required bool rising}) {
    for (int i = 0; i < 16; i++) {
      final mid = a.add(Duration(
          microseconds: b.difference(a).inMicroseconds ~/ 2));
      final isAbove = moonPosition(mid, lat, lon).altitude > 0;
      if (isAbove == rising) {
        b = mid; // trecerea e în prima jumătate
      } else {
        a = mid; // trecerea e în a doua jumătate
      }
    }
    return b;
  }

  @override
  List<DateTime> nextFullMoons(DateTime from, int count) {
    // Faza suncalc: 0 = Lună nouă, 0.5 = Lună plină, 1 = Lună nouă din nou.
    // Luna plină = momentul în care faza trece crescător prin 0.5.
    final result = <DateTime>[];
    const step = Duration(hours: 6);
    final end = from.add(Duration(days: 30 * (count + 2)));

    var t = from;
    double prev = _phase(t);

    while (t.isBefore(end) && result.length < count) {
      final next = t.add(step);
      final cur = _phase(next);
      // Trecere crescătoare prin 0.5 (excludem saltul 1->0 prin cur > prev).
      if (prev < 0.5 && cur >= 0.5 && cur > prev) {
        result.add(_refinePhase(t, next));
      }
      prev = cur;
      t = next;
    }
    return result;
  }

  /// Rafinează prin căutare binară momentul în care faza = 0.5 (Lună plină).
  DateTime _refinePhase(DateTime a, DateTime b) {
    for (int i = 0; i < 20; i++) {
      final mid =
          a.add(Duration(microseconds: b.difference(a).inMicroseconds ~/ 2));
      if (_phase(mid) < 0.5) {
        a = mid;
      } else {
        b = mid;
      }
    }
    return b;
  }

  double _phase(DateTime t) =>
      _num(SunCalc.getMoonIllumination(t.toUtc())['phase']);

  // --- Helperi privați (toată dependența de forma datelor stă aici) ---

  MoonPhase _phaseFrom(dynamic illum) {
    final fraction = _num(illum['fraction']); // 0..1
    final phase = _num(illum['phase']); // 0..1 (0 = Lună nouă, 0.5 = Lună plină)
    return MoonPhase(
      illumination: fraction * 100,
      ageDays: phase * _synodicMonth,
    );
  }

  /// Extrage un double dintr-o valoare.
  /// NOTĂ: presupune că suncalc întoarce un Map (ex. pos['altitude']). Dacă
  /// versiunea pachetului întoarce un OBIECT tipizat (ex. pos.altitude),
  /// schimbi accesările `pos['cheie']` în `pos.cheie` — doar în acest fișier.
  double _num(dynamic v) => (v as num).toDouble();

  double _toDegrees(double radians) => radians * 180 / math.pi;

  /// Convertește azimutul suncalc (radiani, 0 = Sud, crescător spre Vest)
  /// în azimut busolă (grade, 0 = Nord).
  ///   suncalc 0     (Sud)  -> 180
  ///   suncalc +90°  (Vest) -> 270
  ///   suncalc -90°  (Est)  -> 90
  ///   suncalc 180°  (Nord) -> 0
  double _toCompassAzimuth(double radians) {
    final deg = radians * 180 / math.pi + 180;
    return (deg % 360 + 360) % 360; // normalizat în [0, 360)
  }
}
