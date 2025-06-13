import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../widgets/custom_password_text_field.dart';
import 'pin_success_screen.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final currentPinController = TextEditingController();
  final newPinController = TextEditingController();
  final confirmPinController = TextEditingController();

  bool _isLoading = false;

  Future<void> _changePin() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    final url = Uri.parse('https://demoapi.crlafrica.com/api/customer/User/ChangePin');

    final response = await http.post(
      url,
      headers: {
        'accept': '*/*',
        'Content-Type': 'application/json;odata.metadata=minimal;odata.streaming=true',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        "currentPin": currentPinController.text.trim(),
        "newPin": newPinController.text.trim(),
        "confirmNewPin": confirmPinController.text.trim(),
      }),
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PinSuccessScreen()),
      );
    } else {
      final message = json.decode(response.body)["message"] ?? "Failed to change PIN.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change PIN"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.asset("images/logo.png", height: 100), // Replace with your actual logo path
            const SizedBox(height: 20),
            CustomPasswordTextField(
              controller: currentPinController,
              labelText: "Enter current PIN",
            ),
            const SizedBox(height: 16),
            CustomPasswordTextField(
              controller: newPinController,
              labelText: "Enter new PIN",
            ),
            const SizedBox(height: 16),
            CustomPasswordTextField(
              controller: confirmPinController,
              labelText: "Confirm new PIN",
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _changePin,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text("Change PIN"),
                  ),
          ],
        ),
      ),
    );
  }
}
