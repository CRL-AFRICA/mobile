import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import '../utils/toast.dart';
import 'login_screen.dart'; // Replace with your actual login screen import

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final PageController _pageController = PageController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  List<dynamic> allQuestions = [];
  final List<int?> selectedQuestionIds = [null, null, null];
  final List<TextEditingController> answerControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchSecurityQuestions();
  }

  Future<void> fetchSecurityQuestions() async {
    final url = Uri.parse("https://demoapi.crlafrica.com/odata/customer/SecurityQuestion");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          allQuestions = data["value"];
        });
      } else {
        showToast("Failed to load questions", isError: true);
      }
    } catch (_) {
      showToast("Error fetching questions", isError: true);
    }
  }

  void goToNextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> resetPassword() async {
    final code = otpController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (code.isEmpty || password.isEmpty || confirm.isEmpty || selectedQuestionIds.contains(null) || answerControllers.any((c) => c.text.isEmpty)) {
      showToast("All fields are required", isError: true);
      return;
    }

    final payload = {
      "emailAddress": widget.email,
      "code": code,
      "password": password,
      "confirmPassword": confirm,
      "securityQuestionsAndAnswers": List.generate(3, (i) => {
        "questionId": selectedQuestionIds[i],
        "answer": answerControllers[i].text.trim(),
      }),
    };

    setState(() => isLoading = true);
    final url = Uri.parse("https://demoapi.crlafrica.com/api/customer/User/ResetPassword");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        showToast("Password reset successful");

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ResetSuccessScreen()),
          (route) => false,
        );
      } else {
        showToast("Reset failed", isError: true);
      }
    } catch (_) {
      showToast("Error during reset", isError: true);
    }

    setState(() => isLoading = false);
  }

  Widget _buildLogo() {
  return Column(
    children: [
      const SizedBox(height: 80),
      Image.asset('images/logo.png', height: 100), // Adjust path/size as needed
      const SizedBox(height: 32),
    ],
  );
}


Widget otpStep() {
  return Column(
    children: [
      _buildLogo(),
      const Text("Enter OTP", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      TextField(
        controller: otpController,
        decoration: InputDecoration(
          labelText: "OTP",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 30),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            if (otpController.text.trim().isEmpty) {
              showToast("Please enter OTP", isError: true);
              return;
            }
            goToNextPage();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6197BC),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Next", style: TextStyle(fontSize: 16)),
        ),
      )
    ],
  );
}

Widget securityQuestionStep() {
  return Column(
    children: [
      _buildLogo(),
      const Text("Security Questions", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      for (int i = 0; i < 3; i++)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              value: selectedQuestionIds[i],
              items: allQuestions.map<DropdownMenuItem<int>>((q) {
                return DropdownMenuItem<int>(
                  value: q['SecurityQuestionId'],
                  child: Text(q['Question']),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => selectedQuestionIds[i] = val);
              },
              decoration: InputDecoration(
                labelText: "Select Question ${i + 1}",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: answerControllers[i],
              decoration: InputDecoration(
                hintText: "Your answer",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            if (selectedQuestionIds.contains(null) || answerControllers.any((c) => c.text.isEmpty)) {
              showToast("Please select and answer all questions", isError: true);
              return;
            }
            goToNextPage();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6197BC),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Next", style: TextStyle(fontSize: 16)),
        ),
      )
    ],
  );
}

Widget passwordStep() {
  return Column(
    children: [
      _buildLogo(),
      const Text("Set New Password", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      TextField(
        controller: passwordController,
        obscureText: true,
        decoration: InputDecoration(
          labelText: "New Password",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: confirmPasswordController,
        obscureText: true,
        decoration: InputDecoration(
          labelText: "Confirm Password",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 30),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : resetPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6197BC),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Reset Password", style: TextStyle(fontSize: 16)),
        ),
      )
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Padding(padding: const EdgeInsets.all(24), child: otpStep()),
          Padding(padding: const EdgeInsets.all(24), child: securityQuestionStep()),
          Padding(padding: const EdgeInsets.all(24), child: passwordStep()),
        ],
      ),
    );
  }
}

// ------------------
// ✅ SUCCESS SCREEN
// ------------------
class ResetSuccessScreen extends StatelessWidget {
  const ResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset('images/success.json', height: 140, repeat: false),
              const SizedBox(height: 20),
              const Text("Password Reset Successful", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("You can now log in with your new password.", textAlign: TextAlign.center),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()), // Replace with your actual login screen
                    (route) => false,
                  );
                },
                child: const Text("Go to Login"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
