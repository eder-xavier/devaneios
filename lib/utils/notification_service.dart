import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    _onNotificationReceived = BehaviorSubject<String>();
  }

  late final BehaviorSubject<String> _onNotificationReceived;
  Stream<String> get onNotificationReceived => _onNotificationReceived.stream;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'devaneios_channel';
  static const String _channelName = 'Devaneios Notifications';
  static const String _prefsKey = 'last_notification_time';

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notificações para o questionário de Devaneios',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      ledColor: Colors.blue,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        _onNotificationReceived.add('notification_clicked');
      },
    );
  }

  Future<void> scheduleDailyNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);

    // Primeira notificação imediata
    await _showNotification(
      title: 'Hora de preencher o questionário!',
      body: 'Clique para responder ao questionário de devaneios.',
    );

    // Agendar as próximas 7 notificações
    final times = _generateRandomTimes(
      start: _setTime(9, 0),
      end: _setTime(21, 0),
      count: 7,
      minIntervalMinutes: 17,
    );

    for (int i = 0; i < times.length; i++) {
      await _scheduleNotification(
        id: i + 1,
        title: 'Hora do questionário (${i + 2}/8)',
        body: 'Por favor, responda ao questionário de devaneios.',
        scheduledTime: times[i],
      );
    }
  }

  Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          color: Colors.blue,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(0, title, body, details);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, DateTime.now().toString());
    _onNotificationReceived.add('notification_shown');
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      details,
      // ignore: deprecated_member_use
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  List<DateTime> _generateRandomTimes({
    required DateTime start,
    required DateTime end,
    required int count,
    required int minIntervalMinutes,
  }) {
    final random = Random();
    final times = <DateTime>[];

    final totalSlots =
        (end.difference(start).inMinutes ~/ minIntervalMinutes) - 1;
    final slots = List<int>.generate(totalSlots, (i) => i + 1)..shuffle(random);

    for (int i = 0; i < count && i < slots.length; i++) {
      final minutesToAdd = slots[i] * minIntervalMinutes;
      times.add(start.add(Duration(minutes: minutesToAdd)));
    }

    return times;
  }

  tz.TZDateTime _setTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    return tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  }

  Future<bool> canShowNextNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTimeStr = prefs.getString(_prefsKey);
    if (lastTimeStr == null) return false;

    final lastTime = DateTime.parse(lastTimeStr);
    return DateTime.now().difference(lastTime).inMinutes < 17;
  }

  Future<void> markQuestionnaireAnswered() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    _onNotificationReceived.add('questionnaire_answered');
  }

  Future<void> testNotification() async {
    await _showNotification(
      title: 'Teste de Questionário',
      body: 'Clique para testar o questionário',
    );
  }
}
