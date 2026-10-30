import 'moon_info.dart';

/// O oportunitate fotografică găsită: o fereastră (start–end) într-o noapte în
/// care Luna îndeplinește toate condițiile scenei, plus „vârful" ei (momentul
/// de elevație maximă) și distanța/rating-ul de atunci.
class Opportunity {
  final DateTime start; // începutul ferestrei în care condițiile sunt îndeplinite
  final DateTime end; // sfârșitul ferestrei
  final DateTime bestMoment; // momentul cu elevația cea mai mare
  final double bestAltitude;
  final double bestAzimuth;
  final double illumination; // iluminarea maximă din fereastră (%)
  final MoonDistance distance; // la bestMoment (pentru rating/culoare)

  const Opportunity({
    required this.start,
    required this.end,
    required this.bestMoment,
    required this.bestAltitude,
    required this.bestAzimuth,
    required this.illumination,
    required this.distance,
  });
}
