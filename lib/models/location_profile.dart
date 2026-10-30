/// Profil de locație salvat de utilizator.
/// Echivalentul clasei Python `LocationProfile`.
class LocationProfile {
  final String name;
  final double latitude;
  final double longitude;
  final String? timezone;

  const LocationProfile({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.timezone,
  });

  LocationProfile copyWith({
    String? name,
    double? latitude,
    double? longitude,
    String? timezone,
  }) {
    return LocationProfile(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
    );
  }

  factory LocationProfile.fromJson(Map<String, dynamic> json) {
    return LocationProfile(
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'timezone': timezone,
      };
}
