import 'dart:async';

import 'package:flutter/material.dart';
import 'package:devaneios/utils/notification_service.dart';
import 'package:devaneios/screens/profile_page.dart';
import 'package:devaneios/screens/questionnaire_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showQuestionnaireButton = false;
  bool _isImageLoaded = false;
  int _dailyCount = 0;
  static const int maxDailyQuestionnaires = 8;
  StreamSubscription<String>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _checkDailyCount();
    _setupNotificationListener();
    _checkPendingNotifications(); // Verificar notificações pendentes ao iniciar
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isImageLoaded) {
      _preloadImage();
    }
  }

  Future<void> _preloadImage() async {
    final imageProvider = const AssetImage('assets/forest_background.png');
    await precacheImage(imageProvider, context);
    if (mounted) {
      setState(() {
        _isImageLoaded = true;
      });
    }
  }

  Future<void> _checkDailyCount() async {
    final count = await NotificationService().getDailyQuestionnaireCount();
    print('Contagem diária obtida: $count');
    if (mounted) {
      setState(() {
        _dailyCount = count;
      });
    }
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
              _checkDailyCount();
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isImageLoaded
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFA7C5D2).withOpacity(0.9),
                    const Color(0xFF6E8290).withOpacity(0.9),
                  ],
                ),
                image: const DecorationImage(
                  image: AssetImage('assets/forest_background.png'),
                  fit: BoxFit.cover,
                  opacity: 0.8,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 20.0,
                      ),
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
                                  color: Colors.black26,
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            ),
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
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_showQuestionnaireButton &&
                                _dailyCount < maxDailyQuestionnaires)
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 32.0,
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4A6A7A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 5,
                                    shadowColor: Colors.black38,
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
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'Questionários preenchidos hoje: $_dailyCount',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
