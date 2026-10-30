import 'package:flutter/material.dart';

/// Constante astronomice și de UI, extrase din logica originală Python.
///
/// În versiunea Python aceste valori erau "hardcodate" în mai multe locuri
/// (calculate_moon_distance / calculate_moon_distance_at). Aici sunt o
/// singură sursă de adevăr.
class MoonConstants {
  MoonConstants._();

  // Praguri de distanță Pământ–Lună (km), ca în originalul Python.
  static const double perigeeMin = 356400;
  static const double perigeeMax = 370400;
  static const double apogeeMin = 404000;
  static const double apogeeMax = 406700;

  /// Intervalul total folosit pentru a normaliza ratingul (perigeu..apogeu).
  static double get totalRange => apogeeMax - perigeeMin;

  /// Pragul de vârstă (zile) peste care Luna este în descreștere (waning).
  static const double waningAgeThreshold = 14.765;
}

/// Paleta de culori, reprodusă din tema dark a aplicației originale.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF2B2B2B);
  static const Color surface = Color(0xFF333333);
  static const Color accent = Color(0xFF0D47A1); // albastru
  static const Color accentHover = Color(0xFF1565C0);
  static const Color border = Color(0xFF404040);

  // Culori pentru rating-ul distanței (perigeu/intermediar/apogeu).
  static const Color ratingGood = Color(0xFF4CAF50); // verde - aproape (perigeu)
  static const Color ratingMid = Color(0xFFFFC107); // galben - intermediar
  static const Color ratingBad = Color(0xFFF44336); // roșu - departe (apogeu)

  // Punct "Luna sub orizont" pe busolă.
  static const Color moonBelowHorizon = Color(0xFF0D47A1);

  // Time Shift: fundal sepia pentru trecut, mov pentru viitor.
  static const Color backgroundPast = Color(0xFF2B2318); // sepia închis
  static const Color backgroundFuture = Color(0xFF231E2E); // mov închis
  static const Color past = Color(0xFFD2A86A); // accent sepia (cald)
  static const Color future = Color(0xFFB39DDB); // accent mov
}
