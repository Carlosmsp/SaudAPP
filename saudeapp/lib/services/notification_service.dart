import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Lisbon'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  Future<bool> _checkPermission() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      final bool? hasPermission = await androidImplementation
          ?.canScheduleExactNotifications();

      if (hasPermission == false) {
        await androidImplementation?.requestExactAlarmsPermission();
        return false;
      }
    }
    return true;
  }

  Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('Erro ao cancelar notificações: $e');
    }
  }

  Future<void> agendarAguaPeriodica(
    int intervaloMinutos,
    String mensagem,
  ) async {
    if (!(await _checkPermission())) return;

    try {
      await _notifications.cancel(1);
    } catch (e) {
      debugPrint('Aviso ao cancelar notificação 1: $e');
    }

    await _notifications.periodicallyShowWithDuration(
      1,
      '💧 Hidratação',
      mensagem,
      Duration(minutes: intervaloMinutos),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'agua_channel',
          'Lembretes de Água',
          channelDescription: 'Notificações periódicas para beber água',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> agendarNotificacao({
    required int id,
    required String titulo,
    required String corpo,
    required TimeOfDay hora,
    required String channelId,
    required String channelName,
  }) async {
    if (!(await _checkPermission())) return;

    try {
      await _notifications.cancel(id);
    } catch (e) {
      debugPrint('Aviso ao cancelar notificação $id: $e');
    }

    final now = DateTime.now();
    var agendamento = DateTime(
      now.year,
      now.month,
      now.day,
      hora.hour,
      hora.minute,
    );

    if (agendamento.isBefore(now)) {
      agendamento = agendamento.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      titulo,
      corpo,
      tz.TZDateTime.from(agendamento, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelarNotificacao(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e) {
      debugPrint('Aviso ao cancelar notificação $id: $e');
    }
  }
}
