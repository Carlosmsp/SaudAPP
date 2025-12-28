import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    tz_data.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _notifications.initialize(settings);
  }

  static Future<void> agendarLembreteAgua(bool ligar) async {
    if (!ligar) {
      await _notifications.cancel(100);
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'agua_channel',
        'Lembretes de Água',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await _notifications.periodicallyShowWithDuration(
      100,
      'Hora de beber água! 💧',
      'Mantém o teu corpo hidratado para atingires a meta.',
      const Duration(hours: 2), 
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}