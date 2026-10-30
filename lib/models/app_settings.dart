import 'location_profile.dart';

/// Setările aplicației, salvate pe disc.
/// Echivalentul fișierului `moon_settings.json` din versiunea Python.
///
/// Versiunea pe coordonate GPS: locația curentă este pur și simplu o pereche
/// lat/lon (introdusă din Google Maps), plus un nume opțional. S-a renunțat la
/// selecția județ/localitate. Profilurile salvate rămân (locații cu nume).
class AppSettings {
  double latitude;
  double longitude;
  String locationName; // ex: "Cabana X" sau "Locație curentă"
  String? timezone; // dedus din coordonate (poate fi null până la calcul)

  Map<String, LocationProfile> profiles;
  String lastProfile; // ultimul profil încărcat (numele lui)

  AppSettings({
    this.latitude = 46.9279, // Piatra Neamț, ca valoare implicită
    this.longitude = 26.3708,
    this.locationName = 'Locație curentă',
    this.timezone,
    Map<String, LocationProfile>? profiles,
    this.lastProfile = '',
  }) : profiles = profiles ?? {};

  factory AppSettings.defaults() => AppSettings();

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final rawProfiles = (json['profiles'] as Map<String, dynamic>?) ?? const {};

    return AppSettings(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 46.9279,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 26.3708,
      locationName: json['location_name'] as String? ?? 'Locație curentă',
      timezone: json['timezone'] as String?,
      lastProfile: json['last_profile'] as String? ?? '',
      profiles: rawProfiles.map(
        (name, data) => MapEntry(
          name,
          LocationProfile.fromJson(data as Map<String, dynamic>),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'location_name': locationName,
        'timezone': timezone,
        'last_profile': lastProfile,
        'profiles': profiles.map((name, p) => MapEntry(name, p.toJson())),
      };
}
