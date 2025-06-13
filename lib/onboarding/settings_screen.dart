import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/settings/change_password_screen.dart';
import '../components/settings/change_pin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricsState();
  }

  Future<void> _loadBiometricsState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      biometricsEnabled = prefs.getBool('biometricsEnabled') ?? false;
    });
  }

  Future<void> _toggleBiometrics(bool newValue) async {
    try {
      final canCheckBiometrics = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        _showMessage("Biometric authentication is not supported on this device.");
        return;
      }

      final authenticated = await auth.authenticate(
        localizedReason: newValue
            ? "Authenticate to enable biometrics"
            : "Authenticate to disable biometrics",
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometricsEnabled', newValue);
        setState(() {
          biometricsEnabled = newValue;
        });
        _showMessage(
          newValue ? "Biometrics enabled." : "Biometrics disabled.",
        );
      } else {
        _showMessage("Authentication failed.");
      }
    } catch (e) {
      _showMessage("An error occurred: ${e.toString()}");
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text("Settings", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Center(
            child: Image.asset(
              'images/logo.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: biometricsEnabled,
                  onChanged: (val) => _toggleBiometrics(val),
                  title: const Text("Biometrics"),
                  subtitle: const Text("Enable fingerprint or face unlock"),
                  activeColor: Colors.black,
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                ListTile(
                  title: const Text("Change Password"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _navigateTo(const ChangePasswordScreen()),
                ),
                ListTile(
                  title: const Text("Change PIN"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _navigateTo(const ChangePinScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
