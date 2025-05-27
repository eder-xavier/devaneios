import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_page.dart';
import 'questionnaire_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showQuestionnaireButton = false;
  bool _isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
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
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showQuestionnaireButton =
          prefs.getBool('notification_triggered') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devaneios')),
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QuestionnairePage(),
                              ),
                            );
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
                    ],
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
