import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/toast.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  Future<void> sendResetEmail() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      showToast("Email is required", isError: true);
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse(
      "https://demoapi.crlafrica.com/api/customer/User/ForgetPassword",
    ).replace(queryParameters: {"emailAddress": email});

    try {
      final response = await http.post(
        url,
        headers: {"Accept": "application/json"},
      );

      print("RESPONSE: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {
        showToast("Check your email for OTP");

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ResetPasswordScreen(email: emailController.text.trim()),
          ),
        );
      } else {
        showToast("Failed to send reset email", isError: true);
      }
    } catch (e) {
      print("Exception: $e");
      showToast("Something went wrong", isError: true);
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6197BC);
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Image.asset("images/logo.png", height: 100), // Your app logo
            const SizedBox(height: 32),
            const Text(
              "Forgot Password",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "Enter your email address to receive a one-time password (OTP).",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email Address",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : sendResetEmail,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    isLoading
                        ? const CircularProgressIndicator(color: primaryColor)
                        : const Text(
                          "Continue",
                          style: TextStyle(color: primaryColor, fontSize: 16),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
