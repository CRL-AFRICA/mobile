import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../utils/toast.dart';
import 'package:pinput/pinput.dart';
import 'create_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController otpController = TextEditingController();
  String? userEmail;
  int timerSeconds = 240;
  Timer? _timer;
  bool isLoading = false;
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://20.160.237.234:9080/api/"));

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    _startTimer();
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail') ?? "";
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

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "$minutes:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  Future<void> verifyOtp() async {
    if (otpController.text.length < 6) {
      showToast("Please enter a valid OTP", isError: true);
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await _dio.post("customer/User/VerifyEmail", data: {
        "emailAddress": userEmail,
        "otp": otpController.text.trim(),
      });
      
      if (response.statusCode == 200) {
        showToast("OTP verified successfully!");
        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => CreatePasswordScreen()),
        );
      }
    } on DioException catch (e) {
      String errorMessage = "An error occurred. Please try again.";
      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      showToast(errorMessage, isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> resendOtp() async {
    if (userEmail == null || userEmail!.isEmpty) {
      showToast("User email not found", isError: true);
      return;
    }

    setState(() => timerSeconds = 240);
    _startTimer();
    
    try {
      final response = await _dio.post("customer/User/ResendVerifyEmail", data: {
        "emailAddress": userEmail,
      });
      
      if (response.statusCode == 200) {
        showToast("New OTP sent to your email.");
      }
    } on DioException catch (e) {
      showToast(e.response?.data['message'] ?? "Failed to resend OTP", isError: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 10),
            const Text("Enter OTP", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text("Please enter the one-time password sent to your email", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 10),
            Text("This code will expire in ${_formatTime(timerSeconds)}", style: const TextStyle(fontSize: 14, color: Colors.red)),
            const SizedBox(height: 20),
            Pinput(
              length: 6,
              controller: otpController,
              keyboardType: TextInputType.number,
              obscureText: true,
              obscuringWidget: const CircleAvatar(radius: 5, backgroundColor: Colors.black),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Didn't receive an OTP?", style: TextStyle(fontSize: 14)),
                TextButton(
                  onPressed: timerSeconds == 0 ? resendOtp : null,
                  child: Row(
                    children: [
                      Text("Resend", style: TextStyle(color: timerSeconds == 0 ? Colors.blue : Colors.grey, fontSize: 14)),
                      const SizedBox(width: 5),
                      Icon(Icons.refresh, size: 16, color: timerSeconds == 0 ? Colors.blue : Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Continue", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
