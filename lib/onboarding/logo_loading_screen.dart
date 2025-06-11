import 'dart:async';
import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

class LogoLoadingScreen extends StatefulWidget {
  const LogoLoadingScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LogoLoadingScreenState createState() => _LogoLoadingScreenState();
}

class _LogoLoadingScreenState extends State<LogoLoadingScreen> {
  int _currentIndex = 0;
  final List<String> _logoPaths = [
    'images/logo1.png', // First logo state
    'images/logo2.png', // Second logo state
    'images/logo.png',  // Final logo state
  ];
  
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startLoadingAnimation();
  }

  void _startLoadingAnimation() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentIndex < _logoPaths.length - 1) {
        setState(() {
          _currentIndex++;
        });
      } else {
        timer.cancel();
        _navigateToOnboarding();
      }
    });
  }

  void _navigateToOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Image.asset(
            _logoPaths[_currentIndex], 
            key: ValueKey<int>(_currentIndex), 
            width: 200, 
            height: 200,
          ),
        ),
      ),
    );
  }
}
