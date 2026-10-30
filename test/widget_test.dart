import 'package:flutter_test/flutter_test.dart';

import 'package:moon_hunter/services/suncalc_astronomy_service.dart';

/// The astronomy engine, checked against published lunar events.
void main() {
  final astro = SunCalcAstronomyService();
  const lat = 46.9279, lon = 26.3708; // Piatra Neamț, the app's default location

  test('full moon of 5 November 2025 is almost fully lit', () {
    final phase = astro.moonPhase(DateTime.utc(2025, 11, 5, 13, 19));
    expect(phase.illumination, greaterThan(98));
  });

  test('new moon of 20 November 2025 is almost dark', () {
    final phase = astro.moonPhase(DateTime.utc(2025, 11, 20, 6, 47));
    expect(phase.illumination, lessThan(2));
    expect(phase.imageIndex, inInclusiveRange(0, 29));
  });

  test('distance of the November 2025 supermoon, within the engine\'s known accuracy', () {
    // Published perigee: ~356,800 km on 5 Nov 2025. SunCalc uses a simplified distance
    // formula and is about 7,000 km off here (see README, "Known limitations").
    final d = astro.moonDistance(DateTime.utc(2025, 11, 5, 22, 0));
    expect(d.distanceKm, inInclusiveRange(356800 - 10000, 356800 + 10000));
    expect(d.rating, inInclusiveRange(1, 10));
  });

  test('next full moon after 1 November 2025 is found within a day of 5 November', () {
    final next = astro.nextFullMoons(DateTime.utc(2025, 11, 1), 1).first;
    final published = DateTime.utc(2025, 11, 5, 13, 19);
    expect(next.difference(published).inHours.abs(), lessThan(24));
  });

  test('position is always a valid sky direction', () {
    for (var h = 0; h < 48; h += 3) {
      final p = astro.moonPosition(DateTime.utc(2026, 1, 1).add(Duration(hours: h)), lat, lon);
      expect(p.azimuth, inInclusiveRange(0, 360));
      expect(p.altitude, inInclusiveRange(-90, 90));
    }
  });
}
