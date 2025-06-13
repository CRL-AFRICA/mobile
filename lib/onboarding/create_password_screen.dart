import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../utils/toast.dart';
import 'package:pinput/pinput.dart';
import '../widgets/custom_password_text_field.dart';
import 'login_screen.dart';

class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  _CreatePasswordScreenState createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController pinController = TextEditingController();
  List<Map<String, dynamic>> securityQuestions = [];
  List<int?> selectedQuestions = [null, null, null];
  List<TextEditingController> answerControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  bool isFetchingQuestions = true;

  int currentStep = 0;
  String? userEmail;
  bool isLoading = false;

  final String baseUrl = "https://demoapi.crlafrica.com/";

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    _fetchSecurityQuestions();
  }

  Future<void> _fetchSecurityQuestions() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}odata/customer/SecurityQuestion'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          securityQuestions =
              List<Map<String, dynamic>>.from(data['value'] ?? []);
          isFetchingQuestions = false;
        });
      } else {
        showToast("Failed to fetch security questions", isError: true);
      }
    } catch (e) {
      showToast("Error fetching questions", isError: true);
    }
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail') ?? "";
    });
  }

  void _nextStep() {
    if (currentStep == 0) {
      if (selectedQuestions.contains(null)) {
        showToast("Please select 3 security questions", isError: true);
        return;
      }

      final uniqueQuestions = selectedQuestions.toSet();
      if (uniqueQuestions.length != 3) {
        showToast("Please select 3 *unique* security questions", isError: true);
        return;
      }

      if (answerControllers.any((ctrl) => ctrl.text.trim().isEmpty)) {
        showToast("Please provide answers to all questions", isError: true);
        return;
      }
    } else if (currentStep == 1) {
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
    showToast("User email is missing. Please restart the app.", isError: true);
    return;
  }

  setState(() {
    isLoading = true;
  });

  final String apiUrl = "${baseUrl}api/customer/User/CreatePassword";

  final List<Map<String, dynamic>> securityQA = [];
  final Set<int> uniqueQuestionIds = {};

  for (int i = 0; i < 3; i++) {
    final questionId = selectedQuestions[i];
    final answer = answerControllers[i].text.trim();

    if (questionId != null && answer.isNotEmpty) {
      if (uniqueQuestionIds.add(questionId)) {
        securityQA.add({
          "SecurityQuestionId": questionId,
          "Answer": answer,
        });
      }
    }
  }

  if (securityQA.length != 3) {
    showToast(
        "Please ensure all 3 security questions are unique and answered",
        isError: true);
    return;
  }

  final Map<String, dynamic> requestBody = {
    "EmailAddress": userEmail,
    "Password": passwordController.text.trim(),
    "ConfirmPassword": confirmPasswordController.text.trim(),
    "TransactionPin": pinController.text.trim(),
    "SecurityQuestions": securityQA,
    
  };

  debugPrint("Sending Payload: ${jsonEncode(requestBody)}");

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      showToast("Profile successfully created!");
      setState(() {
        currentStep++;
      });
    } else {
      final body = jsonDecode(response.body);
      final message = body is Map && body.containsKey("errors")
          ? (body["errors"] as Map)
              .values
              .map((e) => e.join("\n"))
              .join("\n")
          : "Failed to create password. Try again.";
      showToast(message, isError: true);
    }
  } catch (e) {
    showToast("An unexpected error occurred. Please try again.",
        isError: true);
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
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
                          "Security Questions",
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (isFetchingQuestions)
                          const Center(child: CircularProgressIndicator())
                        else
                          ...List.generate(3, (i) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                      labelText: 'Select Question ${i + 1}'),
                                  value: selectedQuestions[i],
                                  items: securityQuestions
                                      .map<DropdownMenuItem<int>>((q) {
                                    return DropdownMenuItem<int>(
                                      value: q['SecurityQuestionId'],
                                      child: Text(q['Question'],
                                          overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedQuestions[i] = value;
                                    });
                                  },
                                ),
                                TextFormField(
                                  controller: answerControllers[i],
                                  decoration: const InputDecoration(
                                      labelText: 'Your Answer'),
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          }),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text("Continue →",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ] else if (currentStep == 1) ...[
                        const Text(
                          "Create password",
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 140),
                        CustomPasswordTextField(
                          controller: passwordController,
                          labelText: "Enter new password",
                        ),
                        const SizedBox(height: 16),
                        CustomPasswordTextField(
                          controller: confirmPasswordController,
                          labelText: "Confirm new password",
                        ),
                        const SizedBox(height: 150),
                        ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text("Continue →",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ] else if (currentStep == 2) ...[
                        const Text(
                          "Create PIN",
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Your PIN can be used to authorize all transactions",
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 50),
                        const Text("PIN"),
                        const SizedBox(height: 8),
                        Pinput(
                          controller: pinController,
                          length: 4,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Submit →",
                                  style: TextStyle(color: Colors.white)),
                        ),
                        ] else ...[
                        Expanded(
                          child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            Lottie.asset('images/success.json',
                              height: 140, repeat: false),
                            const SizedBox(height: 30),
                            const Text("Congratulations",
                              style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            const Text(
                              "Your profile has been successfully created."),
                            const SizedBox(height: 40),
                            ElevatedButton(
                              onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen()),
                              );
                              },
                              style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A90E2),
                              minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text("Login →",
                                style: TextStyle(color: Colors.white)),
                            ),
                            ],
                          ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
