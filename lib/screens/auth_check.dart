import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'welcome_page.dart';
import 'register_page.dart';

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;
  bool _isFirstTime = true;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name');
      final isFirstTime = prefs.getBool('is_first_time') ?? true;

      setState(() {
        _isFirstTime = isFirstTime;
        _isRegistered = userName != null && userName.isNotEmpty;
        _isLoading = false;
      });

      // Se for a primeira vez, marca como não sendo mais a primeira vez
      if (isFirstTime) {
        await prefs.setBool('is_first_time', false);
      }
    } catch (e) {
      print('Erro ao verificar status do usuário: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isFirstTime) {
      return const WelcomePage(); // Tela inicial com "Começar"
    }

    return _isRegistered ? const HomePage() : const RegisterPage();
  }
}
