import 'package:flutter/material.dart';

class QuestionnaireFormScreen extends StatefulWidget {
  const QuestionnaireFormScreen({Key? key}) : super(key: key);

  @override
  State<QuestionnaireFormScreen> createState() => _QuestionnaireFormScreenState();
}

class _QuestionnaireFormScreenState extends State<QuestionnaireFormScreen> {
  final TextEditingController damageController = TextEditingController();
  final TextEditingController causeController = TextEditingController();

  @override
  void dispose() {
    damageController.dispose();
    causeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vragenlijst'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFF7FAF7),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "1. Hoeveel schade is er aangericht?",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: damageController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Typ hier",
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "2. Wat was de oorzaak van de schade?",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: causeController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Typ hier",
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const Flexible(child: SizedBox(height: 24)),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF234F1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        onPressed: () => Navigator.pushReplacementNamed(context, '/bedankt'),
                        child: const Text(
                          "Indienen",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
