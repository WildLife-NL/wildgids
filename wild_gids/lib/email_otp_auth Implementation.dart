import 'package:flutter/material.dart';
import 'package:email_otp_auth/email_otp_auth.dart';

class LoginWithEmailOTP extends StatefulWidget {
  @override
  State<LoginWithEmailOTP> createState() => _LoginWithEmailOTPState();
}

class _LoginWithEmailOTPState extends State<LoginWithEmailOTP> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();

  Future<void> sendOtp() async {
    var res = await EmailOtpAuth.sendOTP(email: emailController.text);
    if (res['message'] == 'Email Send') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent!'))
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email'))
      );
    }
  }

  Future<void> verifyOtp() async {
    var res = await EmailOtpAuth.verifyOtp(otp: otpController.text);
    if (res['message'] == 'OTP Verified') {
      // Login successful, navigate to main app
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful!'))
      );
      // TODO: Your app navigation here
    } else if (res['data'] == 'Invalid OTP') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP!'))
      );
    } else if (res['data'] == 'OTP Expired') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP expired!'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email OTP Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: "E-mail",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: sendOtp, child: const Text('Send OTP')),
            const SizedBox(height: 20),
            TextFormField(
              controller: otpController,
              decoration: const InputDecoration(
                hintText: "OTP",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: verifyOtp, child: const Text('Verify OTP')),
          ],
        ),
      ),
    );
  }
}
