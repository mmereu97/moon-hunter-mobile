/// O scenă fotografică: condițiile pe care Luna trebuie să le îndeplinească
/// simultan pentru o poză dorită dintr-un anumit loc.
///
/// Versiune simplificată pentru fluxul GPS: fereastra orară e ținută în minute
/// de la miezul nopții (0..1439). Dacă [endMinutes] <= [startMinutes], fereastra
/// trece peste miezul nopții (ex. 22:00 -> 02:00).
class Scene {
  final String id;
  String name;
  double latitude;
  double longitude;
  double azimuthMin;
  double azimuthMax;
  double elevationMin;
  double elevationMax;
  int startMinutes;
  int endMinutes;
  double minIllumination; // procent 0..100

  Scene({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.azimuthMin = 0,
    this.azimuthMax = 360,
    this.elevationMin = 0,
    this.elevationMax = 90,
    this.startMinutes = 20 * 60, // 20:00
    this.endMinutes = 23 * 60, // 23:00
    this.minIllumination = 0,
  });

  /// "HH:mm" pentru un total de minute de la miezul nopții.
  static String minutesToHHmm(int minutes) {
    final h = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String get startLabel => minutesToHHmm(startMinutes);
  String get endLabel => minutesToHHmm(endMinutes);

  factory Scene.fromJson(Map<String, dynamic> json) {
    return Scene(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Scenă',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      azimuthMin: (json['azimuth_min'] as num?)?.toDouble() ?? 0,
      azimuthMax: (json['azimuth_max'] as num?)?.toDouble() ?? 360,
      elevationMin: (json['elevation_min'] as num?)?.toDouble() ?? 0,
      elevationMax: (json['elevation_max'] as num?)?.toDouble() ?? 90,
      startMinutes: (json['start_minutes'] as num?)?.toInt() ?? 20 * 60,
      endMinutes: (json['end_minutes'] as num?)?.toInt() ?? 23 * 60,
      minIllumination: (json['min_illumination'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'azimuth_min': azimuthMin,
        'azimuth_max': azimuthMax,
        'elevation_min': elevationMin,
        'elevation_max': elevationMax,
        'start_minutes': startMinutes,
        'end_minutes': endMinutes,
        'min_illumination': minIllumination,
      };
}
