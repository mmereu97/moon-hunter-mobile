import 'dart:ui';
import '../core/constants.dart';

/// Poziția Lunii pe cer la un moment dat.
class MoonPosition {
  final double altitude; // elevație, grade (>0 = deasupra orizontului)
  final double azimuth; // azimut, grade (0 = N, 90 = E, 180 = S, 270 = V)

  const MoonPosition({required this.altitude, required this.azimuth});

  bool get isVisible => altitude > 0;
}

/// Clasificarea distanței Pământ–Lună.
enum DistanceStatus { perigeu, apogeu, intermediar }

extension DistanceStatusLabel on DistanceStatus {
  String get label => switch (this) {
        DistanceStatus.perigeu => 'PERIGEU',
        DistanceStatus.apogeu => 'APOGEU',
        DistanceStatus.intermediar => 'INTERMEDIAR',
      };
}

/// Informații despre distanța Lunii și ratingul derivat.
///
/// Portează logica din `calculate_moon_distance` / `calculate_moon_distance_at`.
/// Ratingul: 10 = aproape (perigeu / "supermoon"), 1 = departe (apogeu).
class MoonDistance {
  final double distanceKm;
  final DistanceStatus status;
  final int rating; // 1..10
  final double percentage; // poziția în intervalul perigeu..apogeu (0..100)

  const MoonDistance({
    required this.distanceKm,
    required this.status,
    required this.rating,
    required this.percentage,
  });

  /// Culoarea asociată ratingului (verde / galben / roșu).
  Color get color {
    if (rating >= 8) return AppColors.ratingGood;
    if (rating >= 5) return AppColors.ratingMid;
    return AppColors.ratingBad;
  }

  /// Construiește un [MoonDistance] dintr-o distanță în km, aplicând exact
  /// formula din originalul Python.
  factory MoonDistance.fromKm(double distanceKm) {
    final currentPosition = distanceKm - MoonConstants.perigeeMin;
    final rating =
        (10 - (currentPosition / MoonConstants.totalRange * 9).round())
            .clamp(1, 10);

    final DistanceStatus status;
    if (distanceKm >= MoonConstants.perigeeMin &&
        distanceKm <= MoonConstants.perigeeMax) {
      status = DistanceStatus.perigeu;
    } else if (distanceKm >= MoonConstants.apogeeMin &&
        distanceKm <= MoonConstants.apogeeMax) {
      status = DistanceStatus.apogeu;
    } else {
      status = DistanceStatus.intermediar;
    }

    return MoonDistance(
      distanceKm: distanceKm,
      status: status,
      rating: rating,
      percentage: currentPosition / MoonConstants.totalRange * 100,
    );
  }
}

/// Faza Lunii la un moment dat (înlocuiește datele de la farmsense.net,
/// calculate acum local).
class MoonPhase {
  final double illumination; // procent 0..100
  final double ageDays; // vârsta în zile (0..~29.5)

  const MoonPhase({required this.illumination, required this.ageDays});

  bool get isWaning => ageDays > MoonConstants.waningAgeThreshold;

  String get phaseLabel => isWaning ? 'descreștere' : 'creștere';

  /// Indexul imaginii lunii (luna_0.png .. luna_29.png).
  /// FIX față de Python: în original `round(varsta_luna)` putea da 30
  /// (pentru vârste >= 29.5), iar `luna_30.png` nu există -> imaginea lipsea.
  /// Modulo 30 "învârte" indexul înapoi la 0 (vârsta ~29.5 ≈ Lună nouă ≈ luna_0),
  /// ceea ce e și astronomic corect.
  int get imageIndex => ageDays.round() % 30;

  /// Numele fișierului asset pentru faza curentă.
  String get imageAsset => 'assets/moon/luna_$imageIndex.png';
}

/// O lună plină viitoare împreună cu distanța/rating-ul ei (pentru ecranul
/// "Rating luni pline").
class FullMoonRating {
  final DateTime date;
  final MoonDistance distance;

  const FullMoonRating({required this.date, required this.distance});
}
