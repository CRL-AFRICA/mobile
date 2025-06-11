import 'package:flutter/material.dart';

import '../components/send_money_screen.dart';
import '../components/send_to_crs_screen.dart' show SendToCRSScreen;

class SendMoneyApp extends StatelessWidget {
  const SendMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Return the screen directly instead of wrapping with MaterialApp
    return const TransferSelectionScreen();
  }
}

class TransferSelectionScreen extends StatelessWidget {
  const TransferSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.black,
                  onPressed: () {
                    Navigator.pop(context); // Will now work correctly
                  },
                ),
                const SizedBox(width: 10),
                const Text(
                  "Select Transfer Method",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // To Bank Button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SendMoneyScreen(),
                  ),
                );
              },
              child: _buildTransferOption(
                icon: Icons.account_balance,
                title: "To Other Bank",
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),

            // To CRS Button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SendToCRSScreen(),
                  ),
                );
              },
              child: _buildTransferOption(
                icon: Icons.credit_card,
                title: "To CRL",
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferOption({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: ListTile(
          leading: Icon(icon, size: 40, color: color),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
