// change_pin_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'change_pin_success_screen.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _otpController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  int step = 1; // 1: OTP, 2: new pin

  bool isLoading = false;

  void nextStep() {
    if (step == 1) {
      if (_otpController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter OTP')));
        return;
      }
      setState(() => step = 2);
    } else {
      submitChangePin();
    }
  }

  Future<void> submitChangePin() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();
    final otp = _otpController.text.trim();

    if (pin.isEmpty || confirmPin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter and confirm new PIN')));
      return;
    }
    if (pin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PINs do not match')));
      return;
    }

    setState(() => isLoading = true);

    final body = {
      "otp": otp,
      "pin": pin,
      "confirmPin": confirmPin,
    };

    try {
      final res = await http.post(
        Uri.parse('https://demoapi.crlafrica.com/api/customer/User/ResetPin'),
        headers: {
          'Content-Type': 'application/json;odata.metadata=minimal;odata.streaming=true',
          'accept': '*/*',
        },
        body: json.encode(body),
      );

      if (res.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChangePinSuccessScreen()),
        );
      } else {
        final msg = 'Failed to change PIN. Code: ${res.statusCode}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error changing PIN: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change PIN')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: step == 1
            ? Column(
                children: [
                  const SizedBox(height: 30),
              Center(child: Image.asset("images/logo.png", height: 100)), // Logo
              const SizedBox(height: 24),
                  TextFormField(
                    controller: _otpController,
                    decoration: const InputDecoration(labelText: 'Enter OTP'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : nextStep,
                      child: const Text('Next'),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  const SizedBox(height: 30),
              Center(child: Image.asset("images/logo.png", height: 100)), // Logo
              const SizedBox(height: 24),
                  TextFormField(
                    controller: _pinController,
                    decoration: const InputDecoration(labelText: 'New PIN'),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _confirmPinController,
                    decoration: const InputDecoration(labelText: 'Confirm New PIN'),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : submitChangePin,
                      child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
