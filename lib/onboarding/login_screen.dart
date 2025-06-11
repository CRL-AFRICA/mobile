import 'dart:async';
import 'dart:convert';
import 'package:crs_revamp/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../pages/dashboard.dart';
import '../utils/toast.dart';
import '../widgets/custom_password_text_field.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:local_auth/local_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();

  String? userEmail;
  String? firstName;
  int timerSeconds = 240;
  Timer? _timer;
  bool isLoading = false;

  final String baseUrl = "https://demoapi.crlafrica.com/api/";

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    _startTimer();
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final savedEmail = prefs.getString('userEmail');
    final savedFirstName = prefs.getString('firstName');

    setState(() {
      userEmail = savedEmail;
      firstName = savedFirstName ?? "";
      if (userEmail != null && userEmail!.isNotEmpty) {
        emailController.text = userEmail!;
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerSeconds > 0) {
        if (mounted) {
          setState(() {
            timerSeconds--;
          });
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> loginUser() async {
    if (mounted) setState(() => isLoading = true);

    final url = Uri.parse("${baseUrl}customer/User/SignIn");
    final Map<String, dynamic> requestBody = {
      "emailAddress": emailController.text.trim(),
      "password": passwordController.text.trim(),
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String accessToken = data["accessToken"];
        final String fetchedFirstName = data["firstName"];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("accessToken", accessToken);
        await prefs.setString("firstName", fetchedFirstName);
        await prefs.setString("userEmail", emailController.text.trim());

        showToast("Login successful!");

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else {
        final body = jsonDecode(response.body);

        if (body is Map && body.containsKey("errors")) {
          final errors = body["errors"];
          final emailErrors = errors["EmailAddress"];

          if (emailErrors is List && emailErrors.isNotEmpty) {
            final errorMessage = emailErrors.join("\n");
            if (mounted) showToast(errorMessage, isError: true);
          } else {
            if (mounted) showToast("Invalid email or password", isError: true);
          }
        } else {
          final message = body['message'] ?? "Login failed. Please try again.";
          if (mounted) showToast(message, isError: true);
        }
      }
    } catch (e, stacktrace) {
      print("Exception during login: $e");
      print("Stacktrace:\n$stacktrace");
      if (mounted) {
        showToast(
          "An unexpected error occurred. Please try again.",
          isError: true,
        );
      }
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    passwordController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6197BC);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset("images/logo.png", height: 50),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("Hello ", style: TextStyle(fontSize: 26)),
                    Text(
                      firstName ?? "",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 70),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: CustomTextField(
              controller: emailController,
              hintText: "Enter your Email address",
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: CustomPasswordTextField(
              controller: passwordController,
              labelText: "Enter new password",
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  );
                },
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : loginUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const SpinKitThreeBounce(
                        color: Colors.white,
                        size: 18,
                      )
                    : const Text(
                        "Login  →",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DetailsFormScreen(),
                  ),
                );
              },
              child: const Text(
                "Create an account? Sign up",
                style: TextStyle(color: primaryColor, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
