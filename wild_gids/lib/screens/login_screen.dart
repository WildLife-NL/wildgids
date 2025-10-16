import 'package:flutter/material.dart';
import 'package:email_otp_auth/email_otp_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();

  bool otpSent = false;
  bool loggingIn = false;
  bool acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _loadAcceptedTerms();
  }

  Future<void> _loadAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      acceptedTerms = prefs.getBool('acceptedTerms') ?? false;
    });
  }

  Future<void> _setAcceptedTerms(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acceptedTerms', value);
    setState(() {
      acceptedTerms = value;
    });
  }

  Future<void> sendOtp() async {
    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must accept the Terms and Conditions to proceed')),
      );
      return;
    }

    setState(() => loggingIn = true);
    var res = await EmailOtpAuth.sendOTP(email: emailController.text);
    setState(() => loggingIn = false);
    if (res['message'] == 'Email Send') {
      setState(() => otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent to your email')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid email')));
    }
  }

  Future<void> verifyOtp() async {
    var res = await EmailOtpAuth.verifyOtp(otp: otpController.text);
    if (res['message'] == 'OTP Verified') {
      Navigator.pushReplacementNamed(context, '/intro');
    } else if (res['data'] == 'Invalid OTP') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
    } else if (res['data'] == 'OTP Expired') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP expired')));
    }
  }

  void _openTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms and Conditions'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              'Insert your full terms and conditions text here...',
              textAlign: TextAlign.justify,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7FAF7),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: "E-mail",
                border: OutlineInputBorder(),
              ),
              enabled: !otpSent,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: acceptedTerms,
                  onChanged: (bool? value) {
                    if (value != null) {
                      _setAcceptedTerms(value);
                    }
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _openTermsDialog,
                    child: const Text.rich(
                      TextSpan(
                        text: 'I accept the ',
                        children: [
                          TextSpan(
                            text: 'Terms and Conditions',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (!otpSent)
              ElevatedButton(
                onPressed: (loggingIn || !acceptedTerms) ? null : sendOtp,
                child: const Text('Send code'),
              ),
            if (otpSent) ...[
              TextFormField(
                controller: otpController,
                decoration: const InputDecoration(
                  hintText: "Enter code",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: verifyOtp,
                child: const Text('Verify & Login'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
