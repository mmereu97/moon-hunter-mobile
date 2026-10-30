import '../models/moon_info.dart';

/// Limbile disponibile în aplicație.
enum AppLang { ro, en }

/// Toate textele interfeței, în română și engleză. Se obține din `AppState`
/// prin `context.watch<AppState>().s`. La schimbarea limbii, ecranele care
/// ascultă starea se reconstruiesc automat în limba aleasă.
class S {
  final AppLang lang;
  const S(this.lang);

  bool get isEn => lang == AppLang.en;
  String _t(String ro, String en) => isEn ? en : ro;

  // --- Bara de sus (tooltips) ---
  String get about => _t('Despre', 'About');
  String get scenes => _t('Scene', 'Scenes');
  String get fullMoonRatings => _t('Rating luni pline', 'Full moon ratings');
  String get compassTuning => _t('Reglaj busolă', 'Compass tuning');

  // --- Secțiunea busolă (ecran principal) ---
  String elevAzLine(String elev, String az) => _t(
        'Elevație: $elev°   Azimut: $az°',
        'Elevation: $elev°   Azimuth: $az°',
      );
  String get moonVisible => _t('Luna este vizibilă', 'The Moon is visible');
  String get moonBelow =>
      _t('Luna este sub orizont', 'The Moon is below the horizon');
  String riseSetLine(String rise, String set) =>
      _t('Răsărit: $rise     Apus: $set', 'Rise: $rise     Set: $set');
  String risesAtAzimuth(String az) =>
      _t('Răsare la azimut: $az°', 'Rises at azimuth: $az°');

  // --- Secțiunea fază ---
  String phaseLine(bool waning, int illum) => _t(
        'Faza: ${waning ? 'descreștere' : 'creștere'} $illum% vizibilă',
        'Phase: ${waning ? 'waning' : 'waxing'} $illum% lit',
      );
  String moonAgeLine(String age, int idx) => _t(
        'Vârsta Lunii: $age zile (luna_$idx.png)',
        'Moon age: $age days (luna_$idx.png)',
      );
  String distanceLine(String km, DistanceStatus status, int rating) => _t(
        'Distanță: $km km — ${distanceStatus(status)} ($rating/10)',
        'Distance: $km km — ${distanceStatus(status)} ($rating/10)',
      );
  String distanceStatus(DistanceStatus status) => switch (status) {
        DistanceStatus.perigeu => _t('PERIGEU', 'PERIGEE'),
        DistanceStatus.apogeu => _t('APOGEU', 'APOGEE'),
        DistanceStatus.intermediar => _t('INTERMEDIAR', 'INTERMEDIATE'),
      };

  // --- Cardul de locație ---
  String get location => _t('Locație', 'Location');
  String get coordsLabel => _t(
        'Coordonate (lipește din Google Maps):',
        'Coordinates (paste from Google Maps):',
      );
  String get setBtn => _t('Setează', 'Set');
  String get invalidFormat => _t(
        'Format invalid. Exemplu: 46.9279, 26.3708',
        'Invalid format. Example: 46.9279, 26.3708',
      );
  String get saveLocation => _t('Salvează locația', 'Save location');
  String get save => _t('Salvează', 'Save');
  String get cancel => _t('Anulează', 'Cancel');
  String get nameHint => _t('Nume (ex: Cabana X)', 'Name (e.g. Cabin X)');

  // --- Time Shift ---
  String get timeShift => 'Time Shift';
  String get day => _t('Zi', 'Day');
  String get hour => _t('Oră', 'Hour');
  String get min => _t('Min', 'Min');
  String get pickDateTime => _t('Alege data/ora', 'Pick date/time');
  String get now => _t('Acum', 'Now');
  String get timeReal => _t('TIMP REAL', 'REAL TIME');
  String get timePast => _t('TRECUT', 'PAST');
  String get timeFuture => _t('VIITOR', 'FUTURE');

  // --- Dialogul „Despre" ---
  String get appSubtitle =>
      _t('Planificator de fotografie cu Luna', 'Moon photography planner');
  String get author => _t('Autor', 'Author');
  String get contact => _t('Contact', 'Contact');
  String get close => _t('Închide', 'Close');

  // --- Lista de scene ---
  String get scenesEmptyHint => _t(
        'Nicio scenă încă.\nApasă + ca să creezi una:\ndefinești fereastra de azimut, elevație, ora și iluminarea,\niar aplicația va găsi când Luna le îndeplinește.',
        'No scenes yet.\nTap + to create one:\nset the azimuth, elevation, time and illumination window,\nand the app will find when the Moon meets them.',
      );
  String get newSceneName => _t('Scenă nouă', 'New scene');
  String get sceneFallbackName => _t('Scenă', 'Scene');
  String get findOpportunities =>
      _t('Caută oportunități', 'Find opportunities');
  String get deleteSceneTitle => _t('Șterge scena?', 'Delete scene?');
  String deleteSceneBody(String name) => _t(
        '„$name" va fi ștearsă definitiv.',
        '"$name" will be permanently deleted.',
      );
  String get delete => _t('Șterge', 'Delete');
  String sceneSummary(int azMin, int azMax, int elMin, int elMax, String start,
          String end, int illum) =>
      _t(
        'Azimut $azMin–$azMax°  •  Elev $elMin–$elMax°\nOra $start–$end  •  Ilum ≥ $illum%',
        'Azimuth $azMin–$azMax°  •  Elev $elMin–$elMax°\nTime $start–$end  •  Illum ≥ $illum%',
      );

  // --- Editorul de scenă ---
  String get editScene => _t('Editare scenă', 'Edit scene');
  String get sceneNameLabel => _t('Nume scenă', 'Scene name');
  String get planOnMapButton => _t(
        'Planifică pe hartă (aliniere între 2 puncte)',
        'Plan on map (align between 2 points)',
      );
  String get azimuthWindow => _t('Fereastra de azimut', 'Azimuth window');
  String get azimuthWindowHelp => _t(
        'Direcția (busolă) în care vrei Luna: ex. printr-o fereastră.',
        'The compass direction where you want the Moon: e.g. through a window.',
      );
  String get elevationWindow => _t('Fereastra de elevație', 'Elevation window');
  String get elevationWindowHelp => _t(
        'Cât de sus pe cer (0° = orizont, 90° = la zenit).',
        'How high in the sky (0° = horizon, 90° = zenith).',
      );
  String get timeWindow => _t('Fereastra orară', 'Time window');
  String get timeWindowHelp => _t(
        'Între ce ore cauți oportunitatea.',
        'Between which hours to search.',
      );
  String fromTime(String t) => _t('De la $t', 'From $t');
  String toTime(String t) => _t('Până la $t', 'Until $t');
  String get crossesMidnight => _t(
        'Fereastra trece peste miezul nopții.',
        'The window crosses midnight.',
      );
  String get minIllumination => _t('Iluminare minimă', 'Minimum illumination');
  String get minIlluminationHelp => _t(
        'Cât de „plină" minim să fie Luna.',
        'How "full" the Moon must be at minimum.',
      );

  // --- Oportunități ---
  String opportunitiesTitle(String name) =>
      _t('Oportunități — $name', 'Opportunities — $name');
  String get scanningYear =>
      _t('Se scanează anul următor...', 'Scanning the next year...');
  String get noOpportunities => _t(
        'Nicio oportunitate în următorul an pentru aceste condiții.\nÎncearcă să lărgești fereastra de azimut/elevație, ora sau să scazi iluminarea minimă.',
        'No opportunities in the next year for these conditions.\nTry widening the azimuth/elevation window, the time, or lowering the minimum illumination.',
      );
  String illuminatedPct(int pct) => _t('$pct% iluminată', '$pct% lit');
  String windowPeakLine(String window, String peak) => _t(
        'Fereastră: $window     Vârf: $peak',
        'Window: $window     Peak: $peak',
      );
  String atPeakLine(String el, String az) => _t(
        'La vârf: elevație $el°, azimut $az°',
        'At peak: elevation $el°, azimuth $az°',
      );
  String weekdayAbbr(int weekday) {
    const ro = ['', 'Lun', 'Mar', 'Mie', 'Joi', 'Vin', 'Sâm', 'Dum'];
    const en = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return (isEn ? en : ro)[weekday];
  }

  // --- Harta ---
  String get planOnMapTitle => _t('Planifică pe hartă', 'Plan on map');
  String get mapStandard => _t('Hartă standard', 'Standard map');
  String get satellite => _t('Satelit', 'Satellite');
  String get placeLabel => _t('Pun: ', 'Place: ');
  String get shootingSpot => _t('Loc filmare', 'Shooting spot');
  String get target => _t('Țintă', 'Target');
  String get myLocation => _t('Locația mea', 'My location');
  String get tapToPlaceTarget => _t(
        'Atinge harta ca să pui ținta (vârful bradului, clădirea etc.).',
        'Tap the map to place the target (treetop, building, etc.).',
      );
  String azimutValue(String az) => _t('Azimut: $az°', 'Azimuth: $az°');
  String distanceValue(String label) =>
      _t('Distanță: $label', 'Distance: $label');
  String get targetHeightLabel => _t(
        'Înălțime țintă peste tine (m) — opțional',
        'Target height above you (m) — optional',
      );
  String get targetHeightHint => _t('ex: 12', 'e.g. 12');
  String get targetHeightHelp => _t(
        'Pentru „Luna în vârful bradului": diferența de înălțime dintre vârf și ochii tăi. Lași gol dacă reglezi elevația manual.',
        'For "the Moon at the treetop": the height difference between the top and your eyes. Leave empty if you set elevation manually.',
      );
  String get applyToScene => _t('Aplică la scenă', 'Apply to scene');
  String get enableGpsTitle =>
      _t('Pornește locația (GPS)', 'Turn on location (GPS)');
  String get enableGpsBody => _t(
        'Ca să te poziționez pe hartă, pornește locația pe telefon.',
        'To position you on the map, turn on location on your phone.',
      );
  String get later => _t('Mai târziu', 'Later');
  String get settings => _t('Setări', 'Settings');
  String get locationDenied => _t(
        'Permisiunea de locație e refuzată. O poți activa din setările aplicației.',
        'Location permission is denied. You can enable it from the app settings.',
      );
  String get locationFailed =>
      _t('Nu am putut obține locația GPS.', 'Could not get the GPS location.');

  // --- Reglaj busolă ---
  String sampleElevation(String deg) =>
      _t('Elevație de probă: $deg°', 'Sample elevation: $deg°');
  String get emergeTitle => _t('Ieșirea din apă', 'Rising out of the water');
  String get emergeHelp => _t(
        'Pe câte grade trece Luna de la "jumătate răsărită" la disc întreg.',
        'Over how many degrees the Moon goes from "half-risen" to a full disc.',
      );
  String get floatStartTitle => _t('Începe să plutească', 'Starts floating');
  String get floatStartHelp => _t(
        'De la ce elevație Luna se ridică deasupra orizontului (lasă spațiu).',
        'From what elevation the Moon lifts above the horizon (leaves a gap).',
      );
  String get floatGapTitle => _t('Cât de sus plutește', 'How high it floats');
  String get floatGapHelp => _t(
        'Distanța maximă față de orizont la 90° (fracțiune din rază).',
        'Max distance from the horizon at 90° (fraction of the radius).',
      );

  // --- Setări ---
  String get settingsTitle => _t('Setări', 'Settings');
  String get languageLabel => _t('Limbă', 'Language');
  String get notifications => _t('Notificări', 'Notifications');
  String get notificationsHelp => _t(
        'Anunță-mă când începe o perioadă potrivită pentru o scenă.',
        'Notify me when a matching period for a scene begins.',
      );

  // --- Notificări (conținut) ---
  String get notifTitle =>
      _t('Oportunitate foto cu Luna', 'Moon photo opportunity');
  String notifBody(String scene, String time) => _t(
        'Scena „$scene": Luna intră în fereastră în jur de $time.',
        'Scene "$scene": the Moon enters the window around $time.',
      );
}
