import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../widgets/custom_password_text_field.dart';
import 'dart:convert';

import 'password_success_screen copy.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;

  Future<void> _changePassword() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Access token not found.")),
      );
      return;
    }

    final body = jsonEncode({
      "currentPassword": currentPasswordController.text.trim(),
      "newPassword": newPasswordController.text.trim(),
      "confirmNewPassword": confirmPasswordController.text.trim()
    });

    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse(
          "https://demoapi.crlafrica.com/api/customer/User/ChangePassword"),
      headers: {
        "accept": "*/*",
        "Authorization": "Bearer $accessToken",
        "Content-Type":
            "application/json;odata.metadata=minimal;odata.streaming=true"
      },
      body: body,
    );

    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SuccessScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${response.reasonPhrase}")),
      );
    }
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              children: [
                Image.asset("images/logo.png",
                    height: 100), // Replace with your actual logo path
                const SizedBox(height: 20),
                CustomPasswordTextField(
                  controller: currentPasswordController,
                  labelText: "Enter current password",
                ),
                const SizedBox(height: 12),
                CustomPasswordTextField(
                  controller: newPasswordController,
                  labelText: "Enter new password",
                ),
                const SizedBox(height: 12),
                CustomPasswordTextField(
                  controller: confirmPasswordController,
                  labelText: "Confirm new password",
                ),
                const SizedBox(height: 24),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _changePassword,
                        child: const Text("Submit"),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
