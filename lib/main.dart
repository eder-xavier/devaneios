import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeNotifications();
  tz.initializeTimeZones();
  runApp(const DevaneiosApp());
}

// Inicializar notificações
Future<void> initializeNotifications() async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidInitSettings = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );
  const initializationSettings = InitializationSettings(
    android: androidInitSettings,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Solicitar permissão para notificações (Android 13+)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();
}

class DevaneiosApp extends StatelessWidget {
  const DevaneiosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Devaneios',
      theme: ThemeData(
        primaryColor: const Color(0xFF19333A),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: createMaterialColor(const Color(0xFF19333A)),
          accentColor: const Color(0xFF4686A6),
          backgroundColor: const Color(0xFFB7CED5),
          cardColor: const Color(0xFF386374),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF19333A)),
          bodyMedium: TextStyle(color: Color(0xFF19333A)),
        ),
        scaffoldBackgroundColor: const Color(0xFFB7CED5),
      ),
      home: const AuthCheck(),
    );
  }
}

// Função para criar MaterialColor a partir de uma cor
MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

// Verifica se o usuário já está cadastrado
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isRegistered = prefs.getString('user_name') != null;
    });
    if (_isRegistered) {
      _scheduleDailyNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isRegistered ? const HomePage() : const RegisterPage();
  }
}

// Tela de Cadastro
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text);
    await prefs.setString('user_email', _emailController.text);
    await prefs.setInt('user_age', int.parse(_ageController.text));
    await _scheduleDailyNotifications();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro'),
        backgroundColor: const Color(0xFF19333A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu nome';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Por favor, insira um e-mail válido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Idade'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || int.tryParse(value) == null) {
                    return 'Por favor, insira uma idade válida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4686A6),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _saveUserData();
                  }
                },
                child: const Text('Cadastrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tela Principal
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devaneios'),
        backgroundColor: const Color(0xFF19333A),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4686A6),
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
                backgroundColor: const Color(0xFF4686A6),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              child: const Text('Perfil'),
            ),
          ],
        ),
      ),
    );
  }
}

// Tela de Perfil
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? '';
      _emailController.text = prefs.getString('user_email') ?? '';
      _ageController.text = (prefs.getInt('user_age') ?? '').toString();
    });
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text);
    await prefs.setString('user_email', _emailController.text);
    await prefs.setInt('user_age', int.parse(_ageController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dados atualizados com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: const Color(0xFF19333A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu nome';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Por favor, insira um e-mail válido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Idade'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || int.tryParse(value) == null) {
                    return 'Por favor, insira uma idade válida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4686A6),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _saveUserData();
                  }
                },
                child: const Text('Salvar Alterações'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tela do Questionário
class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({super.key});

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  final _formKey = GlobalKey<FormState>();
  final List<int?> _answers = List.filled(8, null);

  final List<String> _questions = [
    'Sentir-se desanimado(a), deprimido(a) ou sem esperança',
    'Dificuldade para dormir ou dormir em excesso',
    'Sentir-se cansado(a) ou ter pouca energia',
    'Falta de apetite ou comer em excesso',
    'Sentir-se mal consigo mesmo(a), sentir-se um(a) fracassado(a) ou achar que decepciona as pessoas próximas',
    'Dificuldade para se concentrar em coisas, como leitura ou assistir televisão',
    'Mover-se ou falar devagar, ou o contrário, ficar inquieto(a) e incapaz de ficar parado(a)',
    'Pensamentos de que seria melhor estar morto(a) ou de se machucar de alguma forma',
  ];

  Future<void> _saveAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().toIso8601String();
    final answersJson = _answers.join(',');
    await prefs.setString('questionnaire_$timestamp', answersJson);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Respostas salvas com sucesso!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questionário de Devaneios'),
        backgroundColor: const Color(0xFF19333A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              for (int i = 0; i < _questions.length; i++)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _questions[i],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Selecione uma opção',
                      ),
                      value: _answers[i],
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Não ocorre')),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Ocorre vários dias'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('Ocorre mais da metade dos dias'),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text('Ocorre todos os dias'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _answers[i] = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor, selecione uma opção';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4686A6),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _saveAnswers();
                  }
                },
                child: const Text('Enviar Respostas'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Função para agendar notificações diárias
Future<void> _scheduleDailyNotifications() async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final random = Random();
  const androidDetails = AndroidNotificationDetails(
    'daily_questionnaire',
    'Questionário Diário',
    channelDescription: 'Notificações para o questionário de devaneios',
    importance: Importance.high,
    priority: Priority.high,
  );
  const notificationDetails = NotificationDetails(android: androidDetails);

  // Limpar notificações anteriores
  await flutterLocalNotificationsPlugin.cancelAll();

  // Agendar 8 notificações entre 9:00 e 21:00
  final now = DateTime.now();
  final times = <int>[];
  while (times.length < 8) {
    final hour = 9 + random.nextInt(12); // Entre 9h e 21h
    final minute = random.nextInt(60);
    final timeInMinutes = hour * 60 + minute;
    if (times.every((t) => (t - timeInMinutes).abs() >= 17)) {
      times.add(timeInMinutes);
    }
  }
  times.sort();

  for (int i = 0; i < times.length; i++) {
    final hour = times[i] ~/ 60;
    final minute = times[i] % 60;
    final scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledTime.isAfter(now)) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        i,
        'Hora de preencher o questionário!',
        'Abra o app Devaneios para responder ao questionário.',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
}
