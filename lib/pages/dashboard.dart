// ... your imports remain unchanged
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'buy_data.dart';
import 'get_help_screen.dart';
import 'pay_bills.dart';
import 'notification_screen.dart';
import 'profile.dart';
import 'send_money.dart';
import 'transaction_history.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? firstName;
  String? accountBalance = "0.00";
  String? accountNumber = "***********";
  bool showBalance = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName') ?? 'User';
      accountBalance = prefs.getString('accountBalance') ?? '0.00';
      accountNumber = prefs.getString('accountNumber') ?? '***********';
      showBalance = prefs.getBool('showBalance') ?? true;
    });
    await _fetchAccountBalance();
  }

  Future<void> _fetchAccountBalance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('https://demoapi.crlafrica.com/api/customer/VirtualAccount/Balance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("Balance API Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        String newBalance = data['availableBalance'].toString();
        String newAccountNumber = data['accountNumber'];
        String newAccountName = data['accountName'] ?? 'My Account';

        setState(() {
          accountBalance = newBalance;
          accountNumber = newAccountNumber;
          firstName = data['firstName'] ?? 'User';
        });

        // Save relevant values to preferences
        await prefs.setString('accountBalance', newBalance);
        await prefs.setString('myAccountNumber', newAccountNumber);
        await prefs.setString('myAccountName', newAccountName);
        await prefs.setString('firstName', data['firstName'] ?? '');
        await prefs.setString('lastName', data['lastName'] ?? '');
        await prefs.setString('emailAddress', data['emailAddress'] ?? '');
        await prefs.setString('bvn', data['bvn'] ?? '');
        await prefs.setString('nin', data['nin'] ?? '');
        await prefs.setString('phoneNumber', data['phoneNumber'] ?? '');
        await prefs.setInt('kycLevel', data['kycLevel'] ?? 0);
      } else {
        print("Failed to fetch balance: ${response.body}");
      }
    } catch (e) {
      print("Error fetching balance: $e");
    }
  }

  Future<void> _toggleBalanceVisibility() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      showBalance = !showBalance;
    });
    await prefs.setBool('showBalance', showBalance);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hey $firstName,", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text("What will you like to do today? 👋",
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.black, size: 28),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade100, Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("Account Balance",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _toggleBalanceVisibility,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            showBalance ? "₦$accountBalance" : "₦******",
                            style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            showBalance ? Icons.visibility : Icons.visibility_off,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      showBalance ? accountNumber ?? '***********' : '***********',
                      style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      ),
                      child: const Text(" +  Fund account"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              const Text("Financials", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFinancialOption(Icons.send, "Send Money", () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SendMoneyApp()));
                  }),
                  _buildFinancialOption(Icons.phone_android, "Buy Airtime", () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SendMoneyApp()));
                  }),
                  _buildFinancialOption(Icons.wifi, "Buy Data", () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const DataInputScreen()));
                  }),
                  _buildFinancialOption(Icons.receipt_long, "Pay Bills", () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PayBillsScreen()));
                  }),
                ],
              ),
              const SizedBox(height: 30),

              const Text("CRL Hub Suggestions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildImageCard('images/ad1.png'),
                    _buildImageCard('images/ad2.png'),
                    _buildImageCard('images/ad3.png'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 8,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()));
          }
          if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const GetHelpScreen()));
          }
          if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: "Get Help"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildFinancialOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black, size: 28),
          ),
          const SizedBox(height: 5),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildImageCard(String imagePath) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
