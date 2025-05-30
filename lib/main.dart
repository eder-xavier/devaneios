import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'screens/auth_check.dart';
import 'utils/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar timezone e notificações
  tz.initializeTimeZones();
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Verificar se o usuário está registrado e agendar notificações
  final prefs = await SharedPreferences.getInstance();
  final isRegistered = prefs.getBool('is_registered') ?? false;
  if (isRegistered) {
    print('Usuário registrado. Agendando notificações...');
    await notificationService.scheduleDailyNotifications();
  } else {
    print('Usuário não registrado. Agendamento de notificações adiado.');
  }

  runApp(const DevaneiosApp());
}

class DevaneiosApp extends StatefulWidget {
  const DevaneiosApp({super.key});

  @override
  State<DevaneiosApp> createState() => _DevaneiosAppState();
}

class _DevaneiosAppState extends State<DevaneiosApp> {
  @override
  void initState() {
    super.initState();
    print('Iniciando inicialização do app...');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Devaneios',
      theme: ThemeData(
        primaryColor: const Color(0xFF1C2526),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: createMaterialColor(const Color(0xFF1C2526)),
          accentColor: const Color(0xFF4A6A7A),
          backgroundColor: const Color(0xFFA7C5D2),
          cardColor: const Color(0xFF6E8290),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF1C2526)),
          bodyMedium: TextStyle(color: Color(0xFF1C2526)),
          titleLarge: TextStyle(color: Colors.white),
        ),
        scaffoldBackgroundColor: const Color(0xFFA7C5D2),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A6A7A),
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Color(0xFF1C2526)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF4A6A7A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF6E8290)),
          ),
        ),
      ),
      home: const AuthCheck(),
    );
  }
}

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  // ignore: deprecated_member_use
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
