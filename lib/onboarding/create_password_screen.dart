import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/toast.dart';
import 'package:pinput/pinput.dart';
import 'package:dio/dio.dart';
import '../widgets/custom_password_text_field.dart';
import 'login_screen.dart';

class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CreatePasswordScreenState createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController pinController = TextEditingController();
  int currentStep = 0;
  String? userEmail;
  bool isLoading = false;

  final Dio _dio = Dio(BaseOptions(baseUrl: "http://20.160.237.234:9080/api/"));

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail') ?? "";
    });
  }

  void _nextStep() {
    if (currentStep == 0) {
      if (passwordController.text.isEmpty ||
          confirmPasswordController.text.isEmpty) {
        showToast("Please fill in all fields", isError: true);
        return;
      }
      if (passwordController.text != confirmPasswordController.text) {
        showToast("Passwords do not match", isError: true);
        return;
      }
    }
    setState(() {
      currentStep++;
    });
  }

  Future<void> _submit() async {
    if (pinController.text.length < 4) {
      showToast("Please enter a valid 4-digit PIN", isError: true);
      return;
    }

    if (userEmail == null || userEmail!.isEmpty) {
      showToast(
        "User email is missing. Please restart the app.",
        isError: true,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final String apiUrl = "customer/User/CreatePassword";
    Map<String, dynamic> requestBody = {
      "emailAddress": userEmail,
      "password": passwordController.text.trim(),
      "confirmPassword": confirmPasswordController.text.trim(),
      "transactionPin": pinController.text.trim(),
    };

    try {
      final response = await _dio.post(apiUrl, data: requestBody);

      if (response.statusCode == 200) {
        showToast("Profile successfully created!");
        setState(() {
          currentStep++;
        });
      } else {
        showToast("Failed to create password. Try again.", isError: true);
      }
    } on DioException catch (e) {
      showToast("Error: ${e.response?.data ?? e.message}", isError: true);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (currentStep > 0) {
                    setState(() {
                      currentStep--;
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            if (currentStep == 0) ...[
              const Text(
                "Create password",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 140),
              CustomPasswordTextField(
                controller: passwordController,
                labelText: "Enter new password",
              ),

              SizedBox(height: 16), // Space between fields

              CustomPasswordTextField(
                controller: confirmPasswordController,
                labelText: "Confirm new password",
              ),
              const SizedBox(height: 150),
              ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  minimumSize: const Size(double.infinity, 70),
                ),
                child: const Text(
                  "Continue →",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ] else if (currentStep == 1) ...[
              const Text(
                "Create PIN",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your PIN can be used to authorize all transactions",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 150),
              const Text("PIN", textAlign: TextAlign.start),

              Pinput(
                controller: pinController,
                length: 4,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 150),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child:
                    isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          "Submit →",
                          style: TextStyle(color: Colors.white),
                        ),
              ),
            ] else ...[
              const SizedBox(height: 50),
              const Icon(Icons.check_circle, color: Colors.green, size: 250),
              const SizedBox(height: 80),
              const Text(
                "Congratulations",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text("Your profile has been successfully created."),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    () => {
                      Navigator.pushReplacement(
                        // ignore: use_build_context_synchronously
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      ),
                    },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  "Login →",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
