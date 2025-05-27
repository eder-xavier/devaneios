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
  static const String _countKey = 'daily_questionnaire_count';

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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Definir o início (9h) e fim (21h) do dia atual
    final startOfDay = today.add(const Duration(hours: 9));
    final endOfDay = today.add(const Duration(hours: 21));

    // Se já passou das 21h, agendar para o dia seguinte
    final baseDate = now.isAfter(endOfDay)
        ? today.add(const Duration(days: 1))
        : today;

    final startTime = DateTime(baseDate.year, baseDate.month, baseDate.day, 9);
    final endTime = DateTime(baseDate.year, baseDate.month, baseDate.day, 21);

    // Gerar 8 horários aleatórios entre 9h e 21h
    final times = _generateRandomTimes(startTime, endTime, 8, 17);

    // Cancelar notificações anteriores
    await _notificationsPlugin.cancelAll();

    // Salvar os horários no SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'notification_times',
      times.map((time) => time.toIso8601String()).toList(),
    );
    await prefs.setInt('current_notification_index', 0);
    await prefs.setInt(
      _countKey,
      prefs.getInt(_countKey) ?? 0,
    ); // Manter contagem existente

    // Agendar a primeira notificação
    await _scheduleNextNotification();
  }

  Future<void> _scheduleNextNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final timesStr = prefs.getStringList('notification_times') ?? [];
    final currentIndex = prefs.getInt('current_notification_index') ?? 0;
    final now = DateTime.now();

    if (currentIndex >= timesStr.length) {
      return; // Todas as notificações do dia foram agendadas
    }

    final times = timesStr.map((str) => DateTime.parse(str)).toList();
    final nextTime = times[currentIndex];

    if (nextTime.isBefore(now)) {
      // Se o horário já passou, avance para o próximo
      await prefs.setInt('current_notification_index', currentIndex + 1);
      await _scheduleNextNotification();
      return;
    }

    await _scheduleNotification(
      id: currentIndex,
      title: 'Hora de preencher o questionário! (${currentIndex + 1}/8)',
      body: 'Clique para responder ao questionário de devaneios.',
      scheduledTime: nextTime,
    );

    await prefs.setString(_prefsKey, now.toIso8601String());
    _onNotificationReceived.add('notification_scheduled');
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          color: Colors.blue,
          //smallIcon: '@mipmap/ic_launcher', // Adiciona o ícone do app
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

  List<DateTime> _generateRandomTimes(
    DateTime start,
    DateTime end,
    int count,
    int minIntervalMinutes,
  ) {
    final random = Random();
    final List<DateTime> times = [];

    final totalMinutes = end.difference(start).inMinutes;
    final minTotalInterval = (count - 1) * minIntervalMinutes;

    if (totalMinutes < minTotalInterval) {
      throw Exception(
        'Não há tempo suficiente para agendar com o intervalo mínimo.',
      );
    }

    final availableMinutes = totalMinutes - minTotalInterval;
    final List<int> intervals = List.generate(
      count - 1,
      (_) => minIntervalMinutes,
    );

    int remainingMinutes = availableMinutes;
    for (int i = 0; i < count - 1; i++) {
      if (remainingMinutes > 0) {
        final additionalInterval = random.nextInt(remainingMinutes + 1);
        intervals[i] += additionalInterval;
        remainingMinutes -= additionalInterval;
      }
    }

    int currentMinutes = 0;
    for (int i = 0; i < count; i++) {
      if (i > 0) {
        currentMinutes += intervals[i - 1];
      }
      final notificationTime = start.add(Duration(minutes: currentMinutes));
      times.add(notificationTime);
    }

    return times..sort();
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
    final currentIndex = prefs.getInt('current_notification_index') ?? 0;
    final dailyCount = prefs.getInt(_countKey) ?? 0;

    // Incrementar contagem diária
    await prefs.setInt(_countKey, dailyCount + 1);

    // Avançar para a próxima notificação
    await prefs.setInt('current_notification_index', currentIndex + 1);
    await prefs.remove(_prefsKey);
    _onNotificationReceived.add('questionnaire_answered');

    // Agendar a próxima notificação
    await _scheduleNextNotification();
  }

  Future<bool> isWithinNotificationWindow() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 9);
    final endOfDay = DateTime(now.year, now.month, now.day, 21);
    return now.isAfter(startOfDay) && now.isBefore(endOfDay);
  }

  Future<int> getDailyQuestionnaireCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_countKey) ?? 0;
  }
}
