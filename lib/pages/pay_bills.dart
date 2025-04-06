import 'package:flutter/material.dart';
import '../components/electrical_screen.dart';
import '../components/tv_network_screen.dart';



class PayBillsScreen extends StatelessWidget {
  const PayBillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        title: const Text(
          'Pay bills',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            BillCard(
              title: 'Tv Network',
              imagePath: 'images/router.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TvNetworkScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            BillCard(
              title: 'Electricity',
              imagePath: 'images/bulb.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ElectricityScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BillCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const BillCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 100,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F6FC),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            Image.asset(imagePath, height: 50),
          ],
        ),
      ),
    );
  }
}




