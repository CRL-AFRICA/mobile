import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding/logo_loading_screen.dart';
import 'onboarding/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget? _initialScreen;

  @override
  void initState() {
    super.initState();
    _checkUserEmail();
  }

  Future<void> _checkUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('userEmail');

    setState(() {
      _initialScreen = (userEmail!.isNotEmpty)
          ? const LoginScreen()
          : const LogoLoadingScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _initialScreen ?? const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
