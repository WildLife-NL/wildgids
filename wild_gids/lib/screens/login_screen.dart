import 'package:flutter/material.dart';
import 'package:email_otp_auth/email_otp_auth.dart';

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

  Future<void> sendOtp() async {
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
            if (!otpSent)
              ElevatedButton(
                onPressed: loggingIn ? null : sendOtp,
                child: const Text('Send code'),
              ),
            if (otpSent) ...[
              TextFormField(
                controller: otpController,
                decoration: const InputDecoration(
                  hintText: "OTP",
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
