import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuestionnaireFormScreen extends StatefulWidget {
  const QuestionnaireFormScreen({Key? key}) : super(key: key);

  @override
  State<QuestionnaireFormScreen> createState() => _QuestionnaireFormScreenState();
}

class _QuestionnaireFormScreenState extends State<QuestionnaireFormScreen> {
  final TextEditingController damageController = TextEditingController();
  final TextEditingController causeController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  // 🔥 Replace with your actual API endpoint
  final String _apiUrl = 'https://jsonplaceholder.typicode.com/posts';

  @override
  void dispose() {
    damageController.dispose();
    causeController.dispose();
    super.dispose();
  }

  // ✅ Function to send data to backend
  Future<void> _submitForm() async {
    if (damageController.text.isEmpty || causeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vul beide velden in. / Please fill in both fields.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'damage': damageController.text.trim(),
          'cause': causeController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ Success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Succesvol verzonden! / Sent successfully!")),
        );
        Navigator.pushReplacementNamed(context, '/bedankt');
      } else {
        // ❌ Backend error
        setState(() {
          _errorMessage = 'Fout: ${response.statusCode}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fout bij verzenden (${response.statusCode}) / Error sending data.")),
        );
      }
    } catch (e) {
      // ❌ Network or server error
      setState(() {
        _errorMessage = 'Netwerkfout / Network error';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kan geen verbinding maken met de server. / Cannot connect to the server.")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                      if (_errorMessage.isNotEmpty)
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF234F1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        onPressed: _isLoading ? null : _submitForm,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Indienen / Submit",
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
