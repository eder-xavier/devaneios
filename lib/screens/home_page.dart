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
  bool _isTestingNotification = false;
  StreamSubscription<String>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
    _setupNotificationListener();
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

  Future<void> _checkNotificationStatus() async {
    final canShow = await NotificationService().canShowNextNotification();
    if (mounted) {
      setState(() {
        _showQuestionnaireButton = !canShow;
      });
    }
  }

  void _setupNotificationListener() {
    _notificationSubscription = NotificationService().onNotificationReceived
        .listen((_) => _checkNotificationStatus());
  }

  Future<void> _testNotification() async {
    if (mounted) {
      setState(() {
        _isTestingNotification = true;
      });
    }

    try {
      await NotificationService().testNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificação de teste enviada!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar notificação: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTestingNotification = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devaneios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _testNotification,
            tooltip: 'Testar Notificação',
          ),
        ],
      ),
      body: _isImageLoaded
          ? Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/forest_background.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.3)),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_showQuestionnaireButton)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                          onPressed: () async {
                            await NotificationService()
                                .markQuestionnaireAnswered();
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const QuestionnairePage(),
                                ),
                              );
                            }
                          },
                          child: const Text('Preencher Questionário'),
                        ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfilePage(),
                            ),
                          );
                        },
                        child: const Text('Perfil'),
                      ),
                      if (_isTestingNotification)
                        const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: _testNotification,
        tooltip: 'Testar Notificação',
        child: const Icon(Icons.notification_add),
      ),
    );
  }
}
