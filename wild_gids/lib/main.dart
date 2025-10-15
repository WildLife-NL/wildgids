import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/questionnaire_intro_screen.dart';
import 'screens/questionnaire_form_screen.dart';
import 'screens/thank_you_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/intro': (context) => const QuestionnaireIntroScreen(),
        '/vragenlijst': (context) => const QuestionnaireFormScreen(),
        '/bedankt': (context) => const ThankYouScreen(),
      },
    );
  }
}
