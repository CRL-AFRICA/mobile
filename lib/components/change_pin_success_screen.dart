// change_pin_success_screen.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../pages/dashboard.dart';

class ChangePinSuccessScreen extends StatelessWidget {
  const ChangePinSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Success')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('images/success.json', height: 140, repeat: false),
              
              const SizedBox(height: 20),
              const Text('Your PIN has been successfully changed!', style: TextStyle(fontSize: 20), textAlign: TextAlign.center),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                 Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
                },
                child: const Text('Go to Dashboard'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
