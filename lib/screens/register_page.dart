import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devaneios/utils/notification_service.dart';
import 'package:devaneios/utils/theme_manager.dart';
import 'package:devaneios/screens/home_page.dart';

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
    print('Iniciando _saveUserData...');
    try {
      print('Salvando dados no SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _nameController.text);
      await prefs.setString('user_email', _emailController.text);
      final age = int.tryParse(_ageController.text);
      if (age == null) {
        print('Erro: Idade inválida. Usando valor padrão 0.');
        await prefs.setInt('user_age', 0);
      } else {
        await prefs.setInt('user_age', age);
      }
      await prefs.setBool('is_registered', true); // Marcar como registrado
      print('Dados salvos com sucesso.');

      print('Agendando notificações após cadastro...');
      await NotificationService().scheduleNotificationsAfterRegistration();
      print('Notificações agendadas com sucesso.');

      print('Navegando para HomePage...');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      print('Erro ao salvar dados do usuário: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar dados. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = ThemeManager.of(context);

    return ValueListenableBuilder<String>(
      valueListenable: themeManager.backgroundImage,
      builder: (context, backgroundImage, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Cadastro'),
            elevation: 0,
            backgroundColor: const Color.fromARGB(0, 255, 255, 255),
          ),
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/$backgroundImage.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Bem-vindo ao Devaneios',
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
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nome',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira seu nome';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _emailController,
                        label: 'E-mail',
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return 'Por favor, insira um e-mail válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _ageController,
                        label: 'Idade',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || int.tryParse(value) == null) {
                            return 'Por favor, insira uma idade válida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () {
                          print('Botão Cadastrar pressionado.');
                          if (_formKey.currentState!.validate()) {
                            print(
                              'Formulário validado. Chamando _saveUserData...',
                            );
                            _saveUserData();
                          } else {
                            print('Formulário não validado.');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A6A7A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                          shadowColor: Colors.black54,
                        ),
                        child: const Text(
                          'Cadastrar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF1C2526)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        validator: validator,
      ),
    );
  }
}
