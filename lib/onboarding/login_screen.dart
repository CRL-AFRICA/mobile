import 'dart:async';
import 'dart:convert';
import 'package:crs_revamp/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
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
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();

  String? userEmail;
  String? firstName;
  bool useBiometrics = false;
  bool isLoading = false;
  int timerSeconds = 240;
  Timer? _timer;

  final String baseUrl = "https://demoapi.crlafrica.com/api/";

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
    _startTimer();
  }

  Future<void> _loadUserSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final savedEmail = prefs.getString('userEmail');
    final savedFirstName = prefs.getString('firstName');
    final biometricsEnabled = prefs.getBool('biometricsEnabled') ?? false;

    if (!mounted) return;
    setState(() {
      userEmail = savedEmail;
      firstName = savedFirstName ?? "";
      useBiometrics = biometricsEnabled;

      if (userEmail != null && userEmail!.isNotEmpty) {
        emailController.text = userEmail!;
      }
    });

    print("Biometrics enabled: $biometricsEnabled");
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

  Future<void> loginUser({
  String? overrideEmail,
  String? overridePassword,
  bool redirect = true, // ✅ new flag
}) async {
  if (mounted) setState(() => isLoading = true);

  final emailToUse = overrideEmail ?? emailController.text.trim();
  final passwordToUse = overridePassword ?? passwordController.text.trim();

  final url = Uri.parse("${baseUrl}customer/User/SignIn");
  final Map<String, dynamic> requestBody = {
    "emailAddress": emailToUse,
    "password": passwordToUse,
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
      final String fetchedPhoneNumber = data["phoneNumber"];
      final String fetchedUserId = data["userId"];

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("accessToken", accessToken);
      await prefs.setString("firstName", fetchedFirstName);
      await prefs.setString("phoneNumber", fetchedPhoneNumber);
      await prefs.setString("userId", fetchedUserId);
      await prefs.setString("userEmail", emailToUse);

      if (useBiometrics && passwordToUse.isNotEmpty) {
        await prefs.setString("biometricPassword", passwordToUse);
      }

      if (fetchedUserId.isNotEmpty) {
        await OneSignal.login(fetchedUserId);
      }

      showToast("Login successful!");

      if (redirect && mounted) {
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
      showToast("An unexpected error occurred. Please try again.", isError: true);
    }
  }

  if (mounted) setState(() => isLoading = false);
}


  Future<void> _authenticateWithBiometrics() async {
  final isAvailable = await auth.canCheckBiometrics;
  final isDeviceSupported = await auth.isDeviceSupported();

  if (!isAvailable || !isDeviceSupported || !useBiometrics) {
    showToast("Biometric authentication not available.", isError: true);
    return;
  }

  try {
    final authenticated = await auth.authenticate(
      localizedReason: "Authenticate with fingerprint",
      options: const AuthenticationOptions(biometricOnly: true),
    );

    if (authenticated) {
      final prefs = await SharedPreferences.getInstance();
      final savedPassword = prefs.getString("biometricPassword");

      if (userEmail != null && userEmail!.isNotEmpty && savedPassword != null) {
        await loginUser(
          overrideEmail: userEmail,
          overridePassword: savedPassword,
          redirect: true, // ✅ force redirect to dashboard after biometric login
        );
      } else {
        showToast("Stored credentials not found.", isError: true);
      }
    } else {
      showToast("Biometric authentication failed.", isError: true);
    }
  } catch (e) {
    print("Biometric error: $e");
    showToast("Authentication error. Try again.", isError: true);
  }
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
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
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
                const SizedBox(height: 60),
                CustomTextField(
                  controller: emailController,
                  hintText: "Enter your Email address",
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                CustomPasswordTextField(
                  controller: passwordController,
                  labelText: "Enter password",
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen()),
                      );
                    },
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
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
                const SizedBox(height: 20),
                if (useBiometrics)
                  Center(
                    child: GestureDetector(
                      onTap: _authenticateWithBiometrics,
                      child: Column(
                        children: [
                          Image.asset(
                            "images/fingerprint.png",
                            height: 50,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Login with Fingerprint",
                            style: TextStyle(
                              fontSize: 14,
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
          ),
        ),
      ),
    );
  }
}
