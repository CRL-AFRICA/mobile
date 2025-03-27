import 'package:flutter/material.dart';
import 'dart:math';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';


class Transaction {
  final String id;
  final String name;
  final String type;
  final double amount;
   final String recipient;
  final DateTime date;
  final bool isCredit;

  Transaction({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,

    required this.recipient,
    required this.date,
    required this.isCredit,
  });
}

final List<Transaction> mockTransactions = List.generate(
  6,
  (index) => Transaction(
    id: Random().nextInt(999999).toString(),
    name: index % 2 == 0 ? "IKEDC Bill" : "Chioma Francis",
    type: index % 2 == 0 ? "Debit" : "Credit",
    amount: 50000,
    recipient: index % 2 == 0 ? "IKEDC Company" : "Chioma Francis",
    date: DateTime.now().subtract(Duration(days: index)),
    isCredit: index % 2 != 0,
  ),
);

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
      ),
      body: mockTransactions.isEmpty
          ? const Center(
              child: Text("No transactions available"),
            )
          : ListView.builder(
              itemCount: mockTransactions.length,
              itemBuilder: (context, index) {
                final transaction = mockTransactions[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(transaction.isCredit ? Icons.add : Icons.remove),
                  ),
                  title: Text(transaction.name),
                  subtitle: Text("${transaction.type} - ${transaction.date}"),
                  trailing: Text(
                    "${transaction.isCredit ? '+' : '-'}₦${transaction.amount}",
                    style: TextStyle(
                      color: transaction.isCredit ? Colors.green : Colors.red,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionReceiptScreen(transaction: transaction),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class TransactionReceiptScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionReceiptScreen({super.key, required this.transaction});

  Future<File> _generateReceiptPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Transaction Receipt", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text("Transaction ID: ${transaction.id}"),
              pw.Text("Transaction Type: ${transaction.type}"),
              pw.Text("Recipient: ${transaction.recipient}"),
              pw.Text("Amount: ₦${transaction.amount}"),
              pw.Text("Date: ${transaction.date}"),
            ],
          ),
        ),
      ),
    );
    final tempDir = await getTemporaryDirectory();
    final file = File("${tempDir.path}/receipt.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> _shareReceipt() async {
    try {
      final file = await _generateReceiptPdf();
      await Share.shareXFiles([XFile(file.path)], text: "Here is your transaction receipt.");
    } catch (e) {
      print("Error sharing receipt: $e");
    }
  }

  Future<void> _downloadReceipt(BuildContext context) async {
    try {
      if (await Permission.storage.request().isGranted) {
        final file = await _generateReceiptPdf();
        final downloadsDir = Directory("/storage/emulated/0/Download");
        final newFile = File("${downloadsDir.path}/Transaction_Receipt_${transaction.id}.pdf");
        await file.copy(newFile.path);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Receipt saved to Downloads folder")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Permission denied to access storage")));
      }
    } catch (e) {
      print("Error downloading receipt: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to download receipt")));
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("Transaction Receipt")),
    body: SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Aligns content to the left
            children: [
              /// Logo on the left
              Image.asset("images/logo.png", height: 80),

              const SizedBox(height: 20),

              /// Success Icon centered
              Center(child: const Icon(Icons.check_circle, color: Colors.green, size: 80)),

              const SizedBox(height: 40),

              /// Title centered
              const Center(
                child: Text(
                  "Transaction Receipt",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                ),
              ),

              const SizedBox(height: 20),

              /// Transaction Details
              _infoRow("Transaction Date", "${transaction.date.toLocal()}"),
              _infoRow("Transaction ID", transaction.id),
              _infoRow("Transaction Type", transaction.type),
              _infoRow("Recipient", transaction.recipient),
              _infoRow("Payment Type", transaction.isCredit ? "Credit" : "Debit"),

              const SizedBox(height: 20),

              /// Amount Display
              Center(
                child: Text(
                  "₦${transaction.amount}",
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 25),

              /// Action Buttons (Share & Download)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: _shareReceipt,
                  ),
                  ElevatedButton(
                    onPressed: () => _downloadReceipt(context),
                    child: const Text("Download Receipt"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
