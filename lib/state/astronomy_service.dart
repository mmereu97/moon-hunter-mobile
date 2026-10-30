import '../models/moon_info.dart';

/// Pachet cu tot ce știm despre Lună la un moment și o locație dată.
/// Convenabil pentru UI: o singură structură conține poziția, distanța și faza.
class MoonSnapshot {
  final DateTime time;
  final MoonPosition position;
  final MoonDistance distance;
  final MoonPhase phase;

  const MoonSnapshot({
    required this.time,
    required this.position,
    required this.distance,
    required this.phase,
  });
}

/// Orele de răsărit și apus ale Lunii (cele mai apropiate, în viitor).
/// Oricare poate fi null dacă nu are loc în intervalul căutat.
class MoonTimes {
  final DateTime? nextRise;
  final DateTime? nextSet;

  const MoonTimes({this.nextRise, this.nextSet});
}

/// Interfața pentru calcule astronomice.
///
/// Rolul ei: ascunde biblioteca concretă (acum suncalc) de restul aplicației.
/// Dacă vrei mai târziu precizie de Swiss Ephemeris, scrii o nouă clasă care
/// implementează aceeași interfață și nu modifici nimic în UI / state.
///
/// Convenții (garantate de interfață, indiferent de bibliotecă):
///   - altitude (elevație): grade, >0 = deasupra orizontului
///   - azimuth: grade busolă, 0 = Nord, 90 = Est, 180 = Sud, 270 = Vest
///   - distance: km (geocentric)
///   - illumination: procent 0..100
abstract class AstronomyService {
  /// Poziția Lunii (elevație + azimut) pentru un observator la lat/lon.
  MoonPosition moonPosition(DateTime time, double lat, double lon);

  /// Distanța Pământ–Lună (geocentrică, nu depinde de observator).
  MoonDistance moonDistance(DateTime time);

  /// Faza Lunii (iluminare + vârstă în zile).
  MoonPhase moonPhase(DateTime time);

  /// Toate datele deodată (un singur calcul, mai eficient pentru UI).
  MoonSnapshot snapshot(DateTime time, double lat, double lon);

  /// Următorul răsărit și apus al Lunii, căutate înainte de la [from].
  MoonTimes nextMoonTimes(DateTime from, double lat, double lon);

  /// Datele următoarelor [count] luni pline, începând de la [from].
  List<DateTime> nextFullMoons(DateTime from, int count);
}
