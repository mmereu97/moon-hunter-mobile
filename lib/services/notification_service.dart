import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Un element de notificat: momentul + textul.
class NotifItem {
  final DateTime when;
  final String title;
  final String body;
  const NotifItem({required this.when, required this.title, required this.body});
}

/// Învelește `flutter_local_notifications`: inițializare, cerere de permisiune
/// și programarea/anularea notificărilor pentru oportunități.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    tzdata.initializeTimeZones();
    // Fus orar pentru programare. (Aplicație personală, România.)
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Bucharest'));
    } catch (_) {}
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
    );
    _inited = true;
  }

  /// Cere permisiunea de notificări (Android 13+). Întoarce true dacă e permisă.
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  /// Anulează tot și reprogramează lista dată (max 50, doar momente viitoare).
  Future<void> schedule(List<NotifItem> items) async {
    await init();
    await _plugin.cancelAll();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'moon_opportunities',
        'Moon Hunter',
        channelDescription: 'Alerte pentru oportunitățile foto cu Luna',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    final now = tz.TZDateTime.now(tz.local);
    var id = 0;
    for (final it in items) {
      final when = tz.TZDateTime.from(it.when, tz.local);
      if (!when.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id++,
        it.title,
        it.body,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      if (id >= 50) break;
    }
  }
}
