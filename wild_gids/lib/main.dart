import 'package:flutter/material.dart';
import 'package:widgets/constants/app_text_theme.dart';
import 'home_widgets.dart';
import 'lib/constants/app_text_theme.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green[800]!),
        primaryColor: Colors.green[800],
        textTheme: AppTextTheme.textTheme,
      ),
      home: const HomeWidgets(),
    );
  }
}
