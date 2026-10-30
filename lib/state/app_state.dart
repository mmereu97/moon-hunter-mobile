import 'dart:async';
import 'package:flutter/foundation.dart';

import '../core/strings.dart';
import '../data/settings_repository.dart';
import '../models/location_profile.dart';
import '../models/moon_info.dart';
import '../models/opportunity.dart';
import '../models/scene.dart';
import '../services/astronomy_service.dart';
import '../services/notification_service.dart';
import '../services/opportunity_service.dart';

/// Direcția față de timpul real: acum, trecut sau viitor.
enum TimeDirection { real, past, future }

/// Starea centrală a aplicației.
///
/// Ține locația, momentul de referință și reglajele, expune datele Lunii și
/// (prin [SettingsRepository]) salvează/încarcă setările între porniri.
class AppState extends ChangeNotifier {
  final AstronomyService _astro;
  final SettingsRepository? _repo;
  Timer? _ticker;
  int _tickCount = 0;

  double latitude = 46.9279; // Piatra Neamț, implicit
  double longitude = 26.3708;
  String locationName = 'Locație curentă';

  DateTime? _timeshift;
  MoonTimes _moonTimes = const MoonTimes();

  // --- Reglaje busolă ---
  double compassEmergeBand = 5;
  double compassFloatStart = 30;
  double compassFloatGap = 0.45;

  /// Panoul Time Shift e desfășurat? Implicit colapsat.
  bool timeShiftExpanded = false;

  /// Scenele fotografice salvate.
  List<Scene> scenes = [];

  /// Profiluri de locație salvate (locuri cu nume, pentru comutare rapidă).
  List<LocationProfile> profiles = [];

  /// Limba interfeței (memorată între porniri).
  AppLang lang = AppLang.ro;

  /// Notificările pentru oportunități sunt active? (memorat)
  bool notificationsEnabled = false;

  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled = value;
    _persist();
    notifyListeners();
    if (value) {
      final granted = await NotificationService.instance.requestPermission();
      if (granted) await refreshNotifications();
    } else {
      await NotificationService.instance.cancelAll();
    }
  }

  /// Recalculează oportunitățile tuturor scenelor (pe 120 de zile) și
  /// (re)programează notificările. Apelat când se activează notificările,
  /// când se schimbă scenele și la pornirea aplicației.
  Future<void> refreshNotifications() async {
    if (!notificationsEnabled || scenes.isEmpty) {
      await NotificationService.instance.cancelAll();
      return;
    }
    final svc = OpportunityService(_astro);
    final strings = s;
    final items = <NotifItem>[];
    for (final scene in scenes) {
      final opps = await svc.find(scene, days: 120);
      for (final o in opps) {
        // Anunțăm cu 30 de minute înainte (sau la start dacă e prea aproape).
        final lead = o.start.subtract(const Duration(minutes: 30));
        final when = lead.isAfter(DateTime.now()) ? lead : o.start;
        items.add(NotifItem(
          when: when,
          title: strings.notifTitle,
          body: strings.notifBody(scene.name, _hhmm(o.start)),
        ));
      }
    }
    items.sort((a, b) => a.when.compareTo(b.when));
    await NotificationService.instance.schedule(items);
  }

  String _hhmm(DateTime dt) {
    final l = dt.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  /// Textele interfeței în limba curentă.
  S get s => S(lang);

  void setLang(AppLang value) {
    if (lang == value) return;
    lang = value;
    _persist();
    notifyListeners();
  }

  AppState(
    this._astro, {
    SettingsRepository? repo,
    Map<String, dynamic>? saved,
  }) : _repo = repo {
    if (saved != null) _applySaved(saved);
    _recomputeMoonTimes();
    _startTicker();
    // La pornire, dacă notificările sunt active, le reîmprospătăm.
    if (notificationsEnabled) {
      Future.microtask(refreshNotifications);
    }
  }

  /// Aplică valorile salvate (dacă lipsesc, păstrează valorile implicite).
  void _applySaved(Map<String, dynamic> s) {
    latitude = (s['latitude'] as num?)?.toDouble() ?? latitude;
    longitude = (s['longitude'] as num?)?.toDouble() ?? longitude;
    locationName = s['location_name'] as String? ?? locationName;
    compassEmergeBand =
        (s['compass_emerge'] as num?)?.toDouble() ?? compassEmergeBand;
    compassFloatStart =
        (s['compass_float_start'] as num?)?.toDouble() ?? compassFloatStart;
    compassFloatGap =
        (s['compass_float_gap'] as num?)?.toDouble() ?? compassFloatGap;
    timeShiftExpanded = s['timeshift_expanded'] as bool? ?? timeShiftExpanded;
    final rawScenes = s['scenes'] as List<dynamic>?;
    if (rawScenes != null) {
      scenes = rawScenes
          .map((e) => Scene.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final rawProfiles = s['profiles'] as List<dynamic>?;
    if (rawProfiles != null) {
      profiles = rawProfiles
          .map((e) => LocationProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    lang = (s['lang'] as String?) == 'en' ? AppLang.en : AppLang.ro;
    notificationsEnabled = s['notifications'] as bool? ?? false;
  }

  /// Salvează setările curente (fire-and-forget). NU salvăm momentul simulat.
  void _persist() {
    _repo?.save({
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'compass_emerge': compassEmergeBand,
      'compass_float_start': compassFloatStart,
      'compass_float_gap': compassFloatGap,
      'timeshift_expanded': timeShiftExpanded,
      'scenes': scenes.map((s) => s.toJson()).toList(),
      'profiles': profiles.map((p) => p.toJson()).toList(),
      'lang': lang == AppLang.en ? 'en' : 'ro',
      'notifications': notificationsEnabled,
    });
  }

  bool get isTimeshifted => _timeshift != null;

  /// Momentul pentru care se fac toate calculele.
  DateTime get referenceTime => _timeshift ?? DateTime.now();

  /// Direcția față de timpul real (pentru tema sepia/mov).
  TimeDirection get timeDirection {
    if (_timeshift == null) return TimeDirection.real;
    return _timeshift!.isBefore(DateTime.now())
        ? TimeDirection.past
        : TimeDirection.future;
  }

  /// Datele Lunii (poziție, distanță, fază) pentru momentul și locația curente.
  MoonSnapshot get snapshot =>
      _astro.snapshot(referenceTime, latitude, longitude);

  /// Orele de răsărit/apus (din cache).
  MoonTimes get moonTimes => _moonTimes;

  /// Azimutul la care răsare Luna (pentru punctul de pe busolă), sau null.
  double? get riseAzimuth {
    final rise = _moonTimes.nextRise;
    if (rise == null) return null;
    return _astro.moonPosition(rise, latitude, longitude).azimuth;
  }

  /// Setează manual o locație (lat/lon în grade zecimale).
  void setLocation(double lat, double lon, {String? name}) {
    latitude = lat;
    longitude = lon;
    if (name != null) locationName = name;
    _recomputeMoonTimes();
    _persist();
    notifyListeners();
  }

  /// Setează locația dintr-un text copiat din Google Maps, ex: "46.9279, 26.3708".
  bool setLocationFromText(String text, {String? name}) {
    final coords = parseLatLon(text);
    if (coords == null) return false;
    setLocation(coords.$1, coords.$2, name: name);
    return true;
  }

  /// Activează simularea unui anumit moment.
  void setTimeshift(DateTime dt) {
    _timeshift = dt;
    _recomputeMoonTimes();
    notifyListeners();
  }

  /// Revine la timpul real.
  void resetTime() {
    _timeshift = null;
    _recomputeMoonTimes();
    notifyListeners();
  }

  /// Mută momentul simulat cu [d] (pornind de la "acum" dacă nu eram deja în
  /// Time Shift). Pozitiv = înainte, negativ = înapoi.
  void shiftBy(Duration d) {
    final base = _timeshift ?? DateTime.now();
    _timeshift = base.add(d);
    _recomputeMoonTimes();
    notifyListeners();
  }

  /// Actualizează unul sau mai multe praguri ale busolei.
  void setCompassTuning({
    double? emergeBand,
    double? floatStart,
    double? floatGap,
  }) {
    if (emergeBand != null) compassEmergeBand = emergeBand;
    if (floatStart != null) compassFloatStart = floatStart;
    if (floatGap != null) compassFloatGap = floatGap;
    _persist();
    notifyListeners();
  }

  void toggleTimeShift() {
    timeShiftExpanded = !timeShiftExpanded;
    _persist();
    notifyListeners();
  }

  // --- Scene ---

  /// Creează o scenă nouă la locația curentă și o adaugă în listă.
  Scene addScene(String name) {
    final scene = Scene(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.isEmpty ? 'Scenă nouă' : name,
      latitude: latitude,
      longitude: longitude,
    );
    scenes.add(scene);
    _persist();
    notifyListeners();
    return scene;
  }

  /// Notifică și salvează după ce o scenă a fost modificată (din editor).
  void updateScene() {
    _persist();
    notifyListeners();
    if (notificationsEnabled) refreshNotifications();
  }

  void deleteScene(Scene scene) {
    scenes.removeWhere((s) => s.id == scene.id);
    _persist();
    notifyListeners();
    if (notificationsEnabled) refreshNotifications();
  }

  /// Caută oportunitățile pentru o scenă pe [days] zile înainte.
  Future<List<Opportunity>> findOpportunities(
    Scene scene, {
    int days = 365,
    void Function(double progress)? onProgress,
  }) {
    return OpportunityService(_astro)
        .find(scene, days: days, onProgress: onProgress);
  }

  // --- Profiluri de locație ---

  /// Salvează locația curentă ca profil cu numele dat (suprascrie dacă există).
  void saveProfile(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    profiles.removeWhere((p) => p.name == trimmed);
    profiles.add(LocationProfile(
      name: trimmed,
      latitude: latitude,
      longitude: longitude,
    ));
    _persist();
    notifyListeners();
  }

  /// Încarcă un profil ca locație curentă.
  void loadProfile(LocationProfile p) {
    setLocation(p.latitude, p.longitude, name: p.name);
  }

  void deleteProfile(LocationProfile p) {
    profiles.removeWhere((x) => x.name == p.name);
    _persist();
    notifyListeners();
  }

  void _recomputeMoonTimes() {
    _moonTimes = _astro.nextMoonTimes(referenceTime, latitude, longitude);
  }

  /// Rating-ul următoarelor [count] luni pline (dată + distanță/rating).
  List<FullMoonRating> fullMoonRatings({int count = 12}) {
    final dates = _astro.nextFullMoons(referenceTime, count);
    return dates
        .map((d) => FullMoonRating(date: d, distance: _astro.moonDistance(d)))
        .toList();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isTimeshifted) return; // momentul e fix, nu reîmprospătăm
      _tickCount++;
      if (_tickCount % 300 == 0) {
        _recomputeMoonTimes();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Interpretează un text "lat, lon" (cu virgulă sau spațiu) -> (lat, lon).
  static (double, double)? parseLatLon(String text) {
    final cleaned = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final parts = cleaned.split(RegExp(r'[,\s]+'));
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0]);
    final lon = double.tryParse(parts[1]);
    if (lat == null || lon == null) return null;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
    return (lat, lon);
  }
}
