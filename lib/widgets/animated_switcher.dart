import 'package:flutter/material.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  bool _showCheck = false;

  @override
  void initState() {
    super.initState();
    // Simulate a loading delay before showing the check icon
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showCheck = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: _showCheck
              ? const Icon(
                  Icons.check_circle,
                  key: ValueKey('check'),
                  size: 80,
                  color: Colors.green,
                )
              : const SizedBox(
                  key: ValueKey('spinner'),
                  height: 80,
                  width: 80,
                  child: CircularProgressIndicator(strokeWidth: 6),
                ),
        ),
      ),
    );
  }
}
