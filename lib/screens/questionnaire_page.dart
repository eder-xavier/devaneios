import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/notification_service.dart';

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
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        final prefs = await SharedPreferences.getInstance();
        final timestamp = DateTime.now().toIso8601String();
        final answersJson = _answers.join(',');
        await prefs.setString('questionnaire_$timestamp', answersJson);

        // Chama o método do NotificationService para atualizar a contagem e agendar a próxima notificação
        await NotificationService().markQuestionnaireAnswered();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Respostas salvas com sucesso!')),
        );
        Navigator.pop(context);
      } catch (e) {
        print('Erro ao salvar respostas: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar respostas. Tente novamente.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questionário de Devaneios'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/forest_background.png'),
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
                    'Questionário de Bem-Estar',
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
                  const SizedBox(height: 20),
                  for (int i = 0; i < _questions.length; i++)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            _questions[i],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C2526),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Selecione uma opção',
                              labelStyle: TextStyle(color: Color(0xFF1C2526)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            value: _answers[i],
                            items: const [
                              DropdownMenuItem(
                                value: 0,
                                child: Text('Não ocorre'),
                              ),
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
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              color: Color(0xFF1C2526),
                              fontSize: 16,
                            ),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF4A6A7A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveAnswers,
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
                      'Enviar Respostas',
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
  }
}
