import 'dart:async';

import '../models/opportunity.dart';
import '../models/scene.dart';
import 'astronomy_service.dart';

/// Motorul care găsește oportunitățile pentru o scenă: scanează timpul în pași
/// de 15 minute și identifică ferestrele în care Luna îndeplinește simultan
/// toate condițiile (azimut, elevație, oră, iluminare).
///
/// Optimizare: dacă momentul nu e în fereastra orară a scenei, sărim instant
/// (fără calcule astronomice). Pentru a nu bloca interfața, scanarea cedează
/// controlul periodic și raportează progresul.
class OpportunityService {
  final AstronomyService astro;
  OpportunityService(this.astro);

  Future<List<Opportunity>> find(
    Scene scene, {
    int days = 365,
    void Function(double progress)? onProgress,
  }) async {
    final lat = scene.latitude;
    final lon = scene.longitude;
    final from = DateTime.now();
    final totalSteps = days * 96; // 96 pași de 15 min pe zi

    // Acumulator pentru intervalul curent.
    DateTime? curStart;
    DateTime? curEnd;
    double maxIllum = 0;
    double bestEl = -999;
    DateTime? bestDt;
    double bestAz = 0;

    final intervals = <_Interval>[];

    void closeInterval() {
      if (curStart != null && bestDt != null) {
        intervals.add(_Interval(
          start: curStart!,
          end: curEnd!,
          maxIllum: maxIllum,
          bestEl: bestEl,
          bestDt: bestDt!,
          bestAz: bestAz,
        ));
      }
      curStart = null;
      curEnd = null;
      maxIllum = 0;
      bestEl = -999;
      bestDt = null;
      bestAz = 0;
    }

    for (int i = 0; i < totalSteps; i++) {
      final t = from.add(Duration(minutes: 15 * i));
      bool ok = false;

      if (_timeInWindow(t, scene.startMinutes, scene.endMinutes)) {
        final pos = astro.moonPosition(t, lat, lon);
        if (_azIn(pos.azimuth, scene.azimuthMin, scene.azimuthMax) &&
            pos.altitude >= scene.elevationMin &&
            pos.altitude <= scene.elevationMax) {
          final illum = astro.moonPhase(t).illumination;
          if (illum >= scene.minIllumination) {
            ok = true;
            curStart ??= t;
            curEnd = t;
            if (illum > maxIllum) maxIllum = illum;
            if (pos.altitude > bestEl) {
              bestEl = pos.altitude;
              bestDt = t;
              bestAz = pos.azimuth;
            }
          }
        }
      }

      if (!ok && curStart != null) closeInterval();

      if (i % 500 == 0) {
        onProgress?.call(i / totalSteps);
        await Future<void>.delayed(Duration.zero); // cedăm controlul interfeței
      }
    }
    closeInterval();
    onProgress?.call(1);

    // Grupăm intervalele pe zile consecutive și alegem, din fiecare grup, pe
    // cel cu iluminarea maximă (ca în originalul Python).
    intervals.sort((a, b) => a.start.compareTo(b.start));
    final selected = <_Interval>[];
    var group = <_Interval>[];
    DateTime? prevDate;
    for (final iv in intervals) {
      final d = DateTime(iv.start.year, iv.start.month, iv.start.day);
      if (prevDate == null || d.difference(prevDate).inDays <= 1) {
        group.add(iv);
      } else {
        selected.add(_best(group));
        group = [iv];
      }
      prevDate = d;
    }
    if (group.isNotEmpty) selected.add(_best(group));

    return selected
        .map((iv) => Opportunity(
              start: iv.start,
              end: iv.end,
              bestMoment: iv.bestDt,
              bestAltitude: iv.bestEl,
              bestAzimuth: iv.bestAz,
              illumination: iv.maxIllum,
              distance: astro.moonDistance(iv.bestDt),
            ))
        .toList();
  }

  _Interval _best(List<_Interval> g) =>
      g.reduce((a, b) => b.maxIllum > a.maxIllum ? b : a);

  bool _timeInWindow(DateTime t, int startMin, int endMin) {
    final tod = t.hour * 60 + t.minute;
    if (startMin == endMin) return true; // fereastră de 24h
    if (startMin < endMin) return tod >= startMin && tod < endMin;
    return tod >= startMin || tod < endMin; // trece peste miezul nopții
  }

  bool _azIn(double az, double min, double max) {
    if (min <= max) return az >= min && az <= max;
    return az >= min || az <= max; // interval care trece prin 0/360
  }
}

class _Interval {
  final DateTime start;
  final DateTime end;
  final double maxIllum;
  final double bestEl;
  final DateTime bestDt;
  final double bestAz;

  _Interval({
    required this.start,
    required this.end,
    required this.maxIllum,
    required this.bestEl,
    required this.bestDt,
    required this.bestAz,
  });
}
