import 'dart:math';
import 'dart:ui';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Importe o main.dart para acessar o NotificationActionHandler

class NotificationService {
  Future<void> initialize() async {
    try {
      await AwesomeNotifications().initialize(
        'resource://drawable/ic_launcher', // Ícone para notificações
        [
          NotificationChannel(
            channelKey: 'devaneios_channel',
            channelName: 'Devaneios Notifications',
            channelDescription: 'Notificações para o questionário de Devaneios',
            importance: NotificationImportance.Max,
            playSound: true,
            enableLights: true,
            enableVibration: true,
            defaultColor: const Color(0xFF4A6A7A), // Cor padrão do canal
            ledColor: const Color(0xFF4A6A7A), // Cor do LED
          ),
        ],
        debug: true,
      );
      print('Notificações inicializadas com sucesso (Awesome Notifications).');

      // Solicitar permissão para notificações
      final granted = await AwesomeNotifications()
          .requestPermissionToSendNotifications();
      if (granted) {
        print('Permissão de notificação concedida.');
      } else {
        print('Permissão de notificação negada.');
      }

      // Registrar o método para ações de notificação
      AwesomeNotifications().setListeners(
        onActionReceivedMethod:
            NotificationActionHandler.onActionReceivedMethod,
      );
    } catch (e) {
      print('Erro ao inicializar notificações: $e');
    }
  }

  Future<String> scheduleDailyNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Disparar notificação imediatamente
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 0,
          channelKey: 'devaneios_channel',
          title: 'Hora de preencher o questionário!',
          body: 'Clique para responder ao questionário de devaneios.',
          payload: {'action': 'open_questionnaire'},
          notificationLayout: NotificationLayout.Default,
        ),
      );
      print('Notificação disparada imediatamente.');

      await prefs.setBool('notification_triggered', true);
      return 'Notificação disparada imediatamente.';
    } catch (e) {
      print('Erro ao disparar notificação: $e');
      return 'Erro ao disparar notificação: $e';
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

    // Total de minutos entre start e end
    final totalMinutes = end.difference(start).inMinutes;
    final minTotalInterval = (count - 1) * minIntervalMinutes;

    if (totalMinutes < minTotalInterval) {
      throw Exception(
        'Não há tempo suficiente para agendar com o intervalo mínimo.',
      );
    }

    // Gerar horários aleatórios
    final availableMinutes = totalMinutes - minTotalInterval;
    final List<int> intervals = List.generate(
      count - 1,
      (_) => minIntervalMinutes,
    );

    // Distribuir o tempo restante aleatoriamente
    int remainingMinutes = availableMinutes;
    for (int i = 0; i < count - 1; i++) {
      if (remainingMinutes > 0) {
        final additionalInterval = random.nextInt(remainingMinutes + 1);
        intervals[i] += additionalInterval;
        remainingMinutes -= additionalInterval;
      }
    }

    // Converter os intervalos em horários
    int currentMinutes = 0;
    for (int i = 0; i < count; i++) {
      if (i > 0) {
        currentMinutes += intervals[i - 1];
      }
      final notificationTime = start.add(Duration(minutes: currentMinutes));
      times.add(notificationTime);
    }

    return times;
  }
}
