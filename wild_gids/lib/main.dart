import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'screens/login/login_screen_new.dart';
import 'screens/questionnaire_intro_screen.dart';
import 'screens/questionnaire_form_screen.dart';
import 'screens/thank_you_screen.dart';
import 'managers/other/login_manager.dart';
import 'interfaces/other/login_interface.dart';
import 'data_managers/auth_api.dart';
import 'data_managers/profile_api.dart';
import 'config/app_config.dart';

Future<void> main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Provider<LoginInterface>(
      create: (_) => LoginManager(
        AuthApi(AppConfig.shared.apiClient),
        ProfileApi(AppConfig.shared.apiClient),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => LoginScreen(),
          '/intro': (context) => const QuestionnaireIntroScreen(),
          '/vragenlijst': (context) => const QuestionnaireFormScreen(),
          '/bedankt': (context) => const ThankYouScreen(),
        },
      ),
    );
  }
}
