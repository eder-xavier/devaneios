import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

// Função estática para lidar com notificações em background
@pragma('vm:entry-point')
void backgroundNotificationHandler(NotificationResponse details) {
  print('Notificação clicada em background: $details');
  NotificationService()._onNotificationReceived.add('notification_clicked');
}

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
      showBadge: true,
      enableLights: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        _onNotificationReceived.add('notification_clicked');
        print('Notificação clicada: $details');
      },
      onDidReceiveBackgroundNotificationResponse: backgroundNotificationHandler,
    );
    print('NotificationService inicializado com sucesso.');
  }

  Future<void> sendImmediateNotification() async {
    print('Tentando enviar notificação imediata...');
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Notificações imediatas para o app Devaneios',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showWhen: false,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notificationsPlugin.show(
        0,
        'Bem-vindo ao Devaneios!',
        'Clique para preencher seu primeiro questionário.',
        details,
        payload: 'first_questionnaire',
      );
      print('Notificação imediata enviada com sucesso.');
    } catch (e) {
      print('Erro ao enviar notificação imediata: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final dailyCount = prefs.getInt(_countKey) ?? 0;
    await prefs.setInt(_countKey, dailyCount + 1);
    print('Contagem diária atualizada para: ${dailyCount + 1}');

    _onNotificationReceived.add('notification_clicked');
  }

  Future<void> scheduleNotificationsAfterRegistration() async {
    print('Iniciando agendamento de notificações após cadastro...');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfDay = today.add(const Duration(hours: 9));
    final endOfDay = today.add(const Duration(hours: 21));

    final isWithinWindow = now.isAfter(startOfDay) && now.isBefore(endOfDay);
    print('Horário atual: $now. Dentro do intervalo (9h-21h): $isWithinWindow');

    await sendImmediateNotification();

    if (isWithinWindow) {
      print('Agendando 7 notificações restantes para hoje...');
      await _scheduleRemainingDailyNotifications(now, 7);
    } else {
      print('Fora do intervalo. Verificando se é antes das 9h...');
      if (now.isBefore(startOfDay)) {
        print(
          'Horário antes das 9h. Agendando 8 notificações para hoje a partir das 9h...',
        );
        await _scheduleRemainingDailyNotifications(startOfDay, 8);
      } else {
        print('Após as 21h. Agendando 8 notificações para o dia seguinte...');
        final tomorrow = today.add(const Duration(days: 1));
        final startTime = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          9,
        );
        final endTime = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          21,
        );

        final times = _generateRandomTimes(startTime, endTime, 8, 17);
        print(
          'Horários gerados para o dia seguinte: ${times.map((t) => t.toIso8601String())}',
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          'notification_times',
          times.map((time) => time.toIso8601String()).toList(),
        );
        await prefs.setInt('current_notification_index', 0);

        await _scheduleNextNotification();
      }
    }
    print('Agendamento após cadastro concluído.');
  }

  Future<void> scheduleDailyNotifications() async {
    print('Agendando notificações diárias...');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final startTime = DateTime(today.year, today.month, today.day, 9);
    final endTime = DateTime(today.year, today.month, today.day, 21);

    await _scheduleRemainingDailyNotifications(now, 8);
  }

  Future<void> _scheduleRemainingDailyNotifications(
    DateTime startFrom,
    int count,
  ) async {
    print('Agendando $count notificações restantes a partir de $startFrom...');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfDay = today.add(const Duration(hours: 21));

    final effectiveStart = startFrom.isBefore(now) ? now : startFrom;

    final times = _generateRandomTimes(effectiveStart, endOfDay, count, 17);
    print('Horários gerados: ${times.map((t) => t.toIso8601String())}');

    await _notificationsPlugin.cancelAll();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'notification_times',
      times.map((time) => time.toIso8601String()).toList(),
    );
    await prefs.setInt('current_notification_index', 0);
    await prefs.setInt(_countKey, prefs.getInt(_countKey) ?? 0);

    await _scheduleNextNotification();
  }

  Future<void> _scheduleNextNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final timesStr = prefs.getStringList('notification_times') ?? [];
    final currentIndex = prefs.getInt('current_notification_index') ?? 0;
    final now = DateTime.now();

    if (currentIndex >= timesStr.length) {
      print('Todas as notificações do dia foram agendadas.');
      final tomorrow = now.add(const Duration(days: 1));
      final startTime = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        9,
      );
      final endTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 21);

      final times = _generateRandomTimes(startTime, endTime, 8, 17);
      print(
        'Horários gerados para o dia seguinte: ${times.map((t) => t.toIso8601String())}',
      );

      await prefs.setStringList(
        'notification_times',
        times.map((time) => time.toIso8601String()).toList(),
      );
      await prefs.setInt('current_notification_index', 0);
      await prefs.setInt(_countKey, 0);

      await _scheduleNextNotification();
      return;
    }

    final times = timesStr.map((str) => DateTime.parse(str)).toList();
    final nextTime = times[currentIndex];

    if (nextTime.isBefore(now)) {
      print('Horário $nextTime já passou. Avançando para o próximo.');
      await prefs.setInt('current_notification_index', currentIndex + 1);
      await _scheduleNextNotification();
      return;
    }

    print('Agendando notificação para $nextTime (ID: $currentIndex)');
    await _scheduleNotification(
      id: currentIndex,
      title: 'Hora de preencher o questionário! (${currentIndex + 1}/8)',
      body: 'Clique para responder ao questionário de devaneios.',
      scheduledTime: nextTime,
    );

    await prefs.setString(_prefsKey, now.toIso8601String());
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
          channelDescription: 'Notificações agendadas para o app Devaneios',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showWhen: false,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('Notificação agendada com sucesso para $tzTime');
    } catch (e) {
      print('Erro ao agendar notificação: $e');
    }
  }

  Future<void> checkPendingNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final timesStr = prefs.getStringList('notification_times') ?? [];
    final currentIndex = prefs.getInt('current_notification_index') ?? 0;
    final now = DateTime.now();

    if (currentIndex >= timesStr.length) {
      print('Nenhuma notificação pendente. Reagendando para o dia atual...');
      await scheduleDailyNotifications();
      return;
    }

    final times = timesStr.map((str) => DateTime.parse(str)).toList();
    final nextTime = times[currentIndex];

    if (nextTime.isBefore(now)) {
      print(
        'Notificação pendente encontrada para $nextTime. Exibindo agora...',
      );
      await _scheduleNotification(
        id: currentIndex,
        title: 'Hora de preencher o questionário! (${currentIndex + 1}/8)',
        body: 'Clique para responder ao questionário de devaneios.',
        scheduledTime: now,
      );
      await prefs.setInt('current_notification_index', currentIndex + 1);
      await _scheduleNextNotification();
    } else {
      print('Próxima notificação agendada para $nextTime. Aguardando...');
    }
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
      print(
        'Não há tempo suficiente para agendar $count notificações com intervalo de $minIntervalMinutes minutos. Ajustando para o tempo disponível.',
      );
      count = (totalMinutes / minIntervalMinutes).floor() + 1;
    }

    final availableMinutes = totalMinutes - ((count - 1) * minIntervalMinutes);
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

  Future<void> markQuestionnaireAnswered() async {
    final prefs = await SharedPreferences.getInstance();
    final currentIndex = prefs.getInt('current_notification_index') ?? 0;
    final dailyCount = prefs.getInt(_countKey) ?? 0;

    await prefs.setInt(_countKey, dailyCount + 1);

    await prefs.setInt('current_notification_index', currentIndex + 1);
    await prefs.remove(_prefsKey);
    _onNotificationReceived.add('questionnaire_answered');
    print('Questionário respondido. Contagem diária: ${dailyCount + 1}');

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
