import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../onboarding/login_screen.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  bool _showCheckIcon = false;

  @override
  void initState() {
    super.initState();

    // Simulate delay (like waiting for server confirmation)
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showCheckIcon = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Success"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('images/success.json', height: 140, repeat: false),
            const SizedBox(height: 20),
            if (_showCheckIcon)
              Column(
                children: [
                  const Text(
                    "Password changed successfully",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text("Go to Login"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
