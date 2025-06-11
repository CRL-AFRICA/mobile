import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding/logo_loading_screen.dart';
import 'onboarding/login_screen.dart';
import 'pages/dashboard.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = MyHttpOverrides();

  // ✅ Correct OneSignal initialization (returns void, so NO await)
  OneSignal.initialize("eac8ff53-926c-4bc2-8570-57632d8d9082");

  // ✅ Permission request (optional, recommended on iOS)
  await OneSignal.Notifications.requestPermission(true);

  // ✅ Foreground notification handler
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    // ✅ Correct: use `event.notification.display();`
    event.notification.display();
  });

  // ✅ Notification click handler
  OneSignal.Notifications.addClickListener((event) {
    final data = event.notification.additionalData;
    final screen = data?['screen'];

    if (screen != null && navigatorKey.currentState != null) {
      if (screen == 'home') {
        navigatorKey.currentState!.push(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Widget? _initialScreen;
  Timer? _inactivityTimer;

  static const Duration sessionTimeout = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetInactivityTimer();
    _loadInitialScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(sessionTimeout, _handleSessionTimeout);
  }

  void _handleSessionTimeout() {
    if (!mounted) return;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      try {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } catch (e, stackTrace) {
        debugPrint("Navigator error: $e\n$stackTrace");
      }
    });
  }

  Future<void> _loadInitialScreen() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userEmail = prefs.getString('userEmail');

      setState(() {
        _initialScreen = (userEmail!.isNotEmpty)
            ? const LoginScreen()
            : const LogoLoadingScreen();
      });
    } catch (e) {
      setState(() {
        _initialScreen = const LoginScreen();
      });
      debugPrint("Error loading user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetInactivityTimer(),
      behavior: HitTestBehavior.translucent,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        home: _initialScreen ??
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _inactivityTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _resetInactivityTimer();
    }
  }
}
