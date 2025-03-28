import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../pages/dashboard.dart';
import '../utils/toast.dart';
import '../widgets/custom_password_text_field.dart';
import 'register_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:local_auth/local_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController passwordController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication(); // Biometrics auth

  String? userEmail;
  String? firstName;
  int timerSeconds = 240;
  Timer? _timer;
  bool isLoading = false;
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://20.160.237.234:9080/api/"));

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    _startTimer();
    _checkBiometricsSupport(); 
  }
// Check if biometric authentication is available and device supports it
  Future<void> _checkBiometricsSupport() async {
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

    if (canAuthenticate) {
      // If biometrics are supported, show the fingerprint icon
      showToast("Biometric authentication is available.");
    } else {
      showToast("Biometric authentication is not available.");
    }
  }

  // Perform biometric authentication
  Future<void> _authenticateWithBiometrics() async {
    try {
      final isAuthenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to log in',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (isAuthenticated) {
        // Perform your login actions here, assuming authentication succeeded
        loginUser();
      } else {
        showToast("Authentication failed.", isError: true);
      }
    } catch (e) {
      showToast("Error occurred during biometric authentication.", isError: true);
    }
  }
    Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail') ?? "";
      firstName = prefs.getString('firstName') ?? "";
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerSeconds > 0) {
        setState(() {
          timerSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }


  Future<void> loginUser() async {
  if (mounted) setState(() => isLoading = true);

  const String apiUrl = "customer/User/SignIn";
  final Map<String, dynamic> requestBody = {
    "emailAddress": userEmail,
    "password": passwordController.text.trim(),
  };

  try {
    final response = await _dio.post(apiUrl, data: requestBody);

    if (response.statusCode == 200) {
      final responseData = response.data;
      final String accessToken = responseData["accessToken"];
      final String firstName = responseData["firstName"];

      // Save token and user info to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("accessToken", accessToken);
      await prefs.setString("firstName", firstName);

      showToast("Login successful!");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      }
    } else {
      showToast("Failed to login. Please try again.", isError: true);
    }
  } on DioException catch (e) {
    final errorResponse = e.response?.data;
    if (errorResponse is Map<String, dynamic> && errorResponse.containsKey("errors")) {
      final errors = errorResponse["errors"] as Map<String, dynamic>;
      final errorMessage = errors.values
          .map((e) => e is List ? e.join("\n") : e.toString())
          .join("\n");
      showToast(errorMessage, isError: true);
    } else {
      showToast("Network error. Please check your connection.", isError: true);
    }
  } catch (e) {
    showToast("An unexpected error occurred. Please try again.", isError: true);
  }

  if (mounted) setState(() => isLoading = false);
}



  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6197BC);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Logo & Greeting (Left-Aligned)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset("images/logo.png", height: 50),
                const SizedBox(height: 10),

                // "Hello Idris" in One Line
                Row(
                  children: [
                    const Text(
                      "Hello ",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                       firstName ?? "",
                      style: TextStyle(
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

          const SizedBox(height: 20),

           // 🔹 Fingerprint Image with Biometric Authentication
          Center(
            child: GestureDetector(
              onTap: _authenticateWithBiometrics, // Tap to authenticate with biometrics
              child: Image.asset("images/fingerprint.png", height: 180),
            ),
          ),
          const SizedBox(height: 70),

          // 🔹 Password Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: CustomPasswordTextField(
                controller: passwordController,
                labelText: "Enter new password",
              ),
          ),
          
          const SizedBox(height: 10),

          // 🔹 Forgot Password
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  "Forgot password?",
                  style: TextStyle(color: primaryColor, fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // 🔹 Login Button
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
                    ? const SpinKitThreeBounce(color: Colors.white, size: 18)
                    : const Text("Login  →", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 🔹 Sign Up - Navigate to DetailsFormScreen
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailsFormScreen(),
                  ), // Navigate to sign-up screen
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
