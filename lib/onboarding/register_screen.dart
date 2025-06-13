// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/toast.dart';
import '../widgets/profile_image_picker.dart';
import '../widgets/custom_text_field.dart';
import 'otp_verification_screen.dart';

class DetailsFormScreen extends StatefulWidget {
  const DetailsFormScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DetailsFormScreenState createState() => _DetailsFormScreenState();
}

class _DetailsFormScreenState extends State<DetailsFormScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController bvnController = TextEditingController();
  final TextEditingController ninController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController terminalIdController = TextEditingController();
  String? profileImagePath;
  bool isLoading = false;

  static const String baseUrl = "https://demoapi.crlafrica.com/api/";

  Future<String?> uploadProfilePicture(File imageFile) async {
    final uri = Uri.parse("${baseUrl}customer/User/UploadProfilePicture");
    var request = http.MultipartRequest("POST", uri)
      ..files.add(await http.MultipartFile.fromPath("file", imageFile.path));

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Upload Response: ${response.body}");

      if (response.statusCode == 200) {
        return response.body; // it's just the URL, not JSON
      }

      showToast("Failed to upload profile picture.", isError: true);
    } catch (e) {
      print("Upload Error: $e");
      showToast("Image upload failed: $e", isError: true);
    }

    return null;
  }

Future<void> onboardUser() async {
  if (firstNameController.text.isEmpty ||
      lastNameController.text.isEmpty ||
      emailController.text.isEmpty ||
      phoneController.text.isEmpty) {
    showToast("Please fill in all required fields", isError: true);
    return;
  }

  if (mounted) setState(() => isLoading = true);

  String? uploadedImageUrl;

  if (profileImagePath != null) {
    uploadedImageUrl = await uploadProfilePicture(File(profileImagePath!));
    if (uploadedImageUrl == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }
  }

  const String defaultProfileImage =
      "https://img.freepik.com/premium-photo/icon-button-man_665280-69543.jpg?w=826";

  final Map<String, dynamic> requestBody = {
    "emailAddress": emailController.text.trim(),
    "bvn": bvnController.text.trim(),
    "nin": ninController.text.trim(),
    "phoneNumber": phoneController.text.trim(),
    "firstName": firstNameController.text.trim(),
    "lastName": lastNameController.text.trim(),
    "terminalId": terminalIdController.text.trim(),
    "profilePictureUrl": uploadedImageUrl ?? defaultProfileImage,
  };

  try {
    final uri = Uri.parse("${baseUrl}customer/User/Onboard/");
    print("Request Body: ${jsonEncode(requestBody)}");
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    print("Response Status: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userEmail', emailController.text.trim());
      await prefs.setString('phoneNumber', phoneController.text.trim());
      await prefs.setString('lastName', lastNameController.text.trim());
      await prefs.setString('firstName', firstNameController.text.trim());
      await prefs.setString(
        'profilePictureUrl',
        uploadedImageUrl ?? defaultProfileImage,
      );

      showToast("Account created successfully!");

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OtpVerificationScreen(),
          ),
        );
      }
    } else {
      // Handle validation or API errors
      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey("errors")) {
        final errors = body["errors"] as Map<String, dynamic>;
        final errorMessage = errors.values
            .map((e) => e is List ? e.join("\n") : e.toString())
            .join("\n");
        if (mounted) showToast(errorMessage, isError: true);
      } else {
        final fallback = body["message"] ?? "Failed to onboard user.";
        if (mounted) {
          showToast(
            "$fallback (Status code: ${response.statusCode})",
            isError: true,
          );
        }
      }
    }
  } catch (e) {
    print("Unexpected Error: $e");
    if (mounted) {
      showToast("Something went wrong. Please try again.", isError: true);
    }
  }

  if (mounted) setState(() => isLoading = false);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Create a profile",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 5),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Please complete the details below",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            ImagePickerWidget(
              onImageSelected: (File imageFile) {
                setState(() {
                  profileImagePath = imageFile.path;
                });
              },
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: firstNameController,
              hintText: "Enter your first name",
            ),
            const SizedBox(height: 15),
            CustomTextField(
              controller: lastNameController,
              hintText: "Enter your surname",
            ),
            const SizedBox(height: 15),
            CustomTextField(
              controller: emailController,
              hintText: "Enter your email",
            ),
            const SizedBox(height: 15),
            CustomTextField(
              controller: bvnController,
              hintText: "Enter your BVN",
              keyboardType: TextInputType.number,
              maxLength: 11,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 15),
            CustomTextField(
              controller: ninController,
              hintText: "Enter your NIN",
              keyboardType: TextInputType.number,
              maxLength: 11,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 15),
            CustomTextField(
              controller: terminalIdController,
              hintText: "Enter your Terminal ID",
              maxLength: 8,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Image.asset(
                        "images/9ja-flag 1.png",
                        height: 30,
                        width: 24,
                      ),
                      const SizedBox(width: 5),
                      const Text("(+234)", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: phoneController,
                        hintText: "Enter your phone number",
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 4),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Phone number should start with 080 or 081",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 70),
            const Text(
              "By submitting this form you agree to our Terms for use, Privacy Policy, and to receiving marketing communication from CRL.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isLoading ? null : onboardUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6197BC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 50),
              ),
              child:
                  isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        "Continue",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Already on CRL? Log in",
                style: TextStyle(color: Colors.blue),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
