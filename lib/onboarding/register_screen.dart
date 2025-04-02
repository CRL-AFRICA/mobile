// ignore_for_file: avoid_print

import 'dart:io';
import 'package:dio/dio.dart'; // Import Dio directly
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String? profileImagePath;
  bool isLoading = false;

  final Dio dio = Dio(BaseOptions(
    baseUrl: 'http://20.160.237.234:9080/api/', // Directly set baseUrl
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

Future<String?> uploadProfilePicture(File imageFile) async {
  const String uploadUrl = "customer/User/UploadProfilePicture";

  try {
    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(imageFile.path, filename: "profile.jpg"),
    });

    final response = await dio.post(uploadUrl, data: formData);

    if (response.statusCode == 200 && response.data != null) {
      return response.data["imageUrl"]; // Assuming API returns { "imageUrl": "https://example.com/image.jpg" }
    } else {
      showToast("Failed to upload profile picture.", isError: true);
      return null;
    }
  } on DioException catch (e) {
    if (e.response?.statusCode == 400 && e.response?.data is Map<String, dynamic>) {
      final errorResponse = e.response?.data;
      if (errorResponse != null && errorResponse.containsKey("errors")) {
        final fileErrors = errorResponse["errors"]["File"];
        if (fileErrors is List && fileErrors.isNotEmpty) {
          showToast(fileErrors.join("\n"), isError: true);
        } else {
          showToast("Error uploading image: ${e.message}", isError: true);
        }
      } else {
        showToast("Error uploading image: ${e.message}", isError: true);
      }
    } else {
      showToast("Network error. Please check your connection.", isError: true);
    }
    return null;
  }
}


Future<void> onboardUser() async {
  if (mounted) setState(() => isLoading = true);

  String? uploadedImageUrl;

  if (profileImagePath != null) {
    uploadedImageUrl = await uploadProfilePicture(File(profileImagePath!));
    if (uploadedImageUrl == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }
  }

  const String apiUrl = "customer/User/Onboard";
  final Map<String, dynamic> requestBody = {
    "emailAddress": emailController.text.trim(),
    "bvn": bvnController.text.trim(),
    "nin": ninController.text.trim(),
    "phoneNumber": phoneController.text.trim(),
    "firstName": firstNameController.text.trim(),
    "lastName": lastNameController.text.trim(),
    "profilePictureUrl": uploadedImageUrl ?? "",
  };

  try {
    final response = await dio.post(apiUrl, data: requestBody);

    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userEmail', emailController.text.trim());
      await prefs.setString('phoneNumber', phoneController.text.trim());
      await prefs.setString('lastName', lastNameController.text.trim());
      await prefs.setString('firstName', firstNameController.text.trim());
      await prefs.setString('profilePictureUrl', uploadedImageUrl ?? "");

      showToast("Account created successfully!");

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OtpVerificationScreen()),
        );
      }
    } else {
      showToast("Failed to onboard user. Please try again.", isError: true);
    }
  } catch (e) {
    showToast("An unexpected error occurred. Please try again.", isError: true);
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
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
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
            
            CustomTextField(controller: firstNameController, hintText: "Enter your first name"),
            const SizedBox(height: 10),
            
            CustomTextField(controller: lastNameController, hintText: "Enter your surname"),
            const SizedBox(height: 10),
            
            CustomTextField(controller: emailController, hintText: "Enter your email"),
            const SizedBox(height: 10),
            CustomTextField(controller: bvnController, hintText: "Enter your BVN"),
            const SizedBox(height: 10),
            CustomTextField(controller: ninController, hintText: "Enter your NIN"),
            const SizedBox(height: 10),
            
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Image.asset("images/9ja-flag 1.png", height: 30, width: 24),
                      const SizedBox(width: 5),
                      const Text("(+234)", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextField(controller: phoneController, hintText: "Enter your phone number", keyboardType: TextInputType.phone),
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
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Continue", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(height: 20),
            
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Already on CRL? Log in", style: TextStyle(color: Colors.blue)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
