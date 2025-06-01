import 'dart:async';
import 'package:flutter/material.dart';
import 'package:devaneios/utils/notification_service.dart';
import 'package:devaneios/utils/theme_manager.dart';
import 'package:devaneios/screens/profile_page.dart';
import 'package:devaneios/screens/questionnaire_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showQuestionnaireButton = false;
  StreamSubscription<String>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
    _checkPendingNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkPendingNotifications() async {
    await NotificationService().checkPendingNotifications();
  }

  void _setupNotificationListener() {
    print('Configurando listener de notificações...');
    _notificationSubscription = NotificationService().onNotificationReceived
        .listen((event) {
          print('Evento recebido na HomePage: $event');
          if (event == 'notification_clicked') {
            if (mounted) {
              setState(() {
                _showQuestionnaireButton = true;
                print('Botão de questionário exibido.');
              });
            }
          } else if (event == 'questionnaire_answered') {
            if (mounted) {
              setState(() {
                _showQuestionnaireButton = false;
                print('Botão de questionário ocultado.');
              });
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = ThemeManager.of(context);

    return Scaffold(
      body: ValueListenableBuilder<String>(
        valueListenable: themeManager.backgroundImage,
        builder: (context, backgroundImage, child) {
          final buttonColor = backgroundImage == 'forest_background2'
              ? const Color.fromARGB(255, 0, 86, 12)
              : const Color(0xFF4A6A7A);
          final buttonTextColor = Colors.white;

          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/$backgroundImage.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Devaneios',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.person, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfilePage(),
                              ),
                            );
                          },
                          tooltip: 'Perfil',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Fazendo o uso da ayahuasca',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        ValueListenableBuilder<bool>(
                          valueListenable: themeManager.isAyahuascaEnabled,
                          builder: (context, isEnabled, child) {
                            return Switch(
                              value: isEnabled,
                              onChanged: (value) {
                                themeManager.toggleAyahuasca(value);
                              },
                              activeColor: const Color.fromARGB(
                                255,
                                0,
                                104,
                                31,
                              ),
                              activeTrackColor: const Color.fromARGB(
                                255,
                                0,
                                134,
                                2,
                              ).withOpacity(0.5),
                              inactiveThumbColor: const Color.fromARGB(
                                255,
                                224,
                                242,
                                255,
                              ),
                              inactiveTrackColor: const Color(
                                0xFF6E8290,
                              ).withOpacity(0.3),
                              thumbIcon:
                                  MaterialStateProperty.resolveWith<Icon?>((
                                    states,
                                  ) {
                                    if (states.contains(
                                      MaterialState.selected,
                                    )) {
                                      return const Icon(
                                        Icons.local_florist,
                                        color: Colors.white,
                                        size: 20,
                                      );
                                    }
                                    return null;
                                  }),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: _showQuestionnaireButton
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                foregroundColor: buttonTextColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 32,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                                shadowColor: Colors.black54,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const QuestionnairePage(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Preencher Questionário',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
