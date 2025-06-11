import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Transaction {
  final String id;
  final String accountNumber;
  final String transactionRef;
  final String beneficiaryAccountName;
  final String beneficiaryAccountNumber;
  final String sourceBankName;
  final String beneficiaryBankName;
  final String beneficiaryBankCode;
  final double amount;
  final double feeAmount;
  final double vatAmount;
  final double creditAmount;
  final double debitAmount;
  final bool isCredit;
  final DateTime date;
  final String remarks;

  Transaction({
    required this.id,
    required this.accountNumber,
    required this.transactionRef,
    required this.beneficiaryAccountName,
    required this.beneficiaryAccountNumber,
    required this.sourceBankName,
    required this.beneficiaryBankName,
    required this.beneficiaryBankCode,
    required this.amount,
    required this.feeAmount,
    required this.vatAmount,
    required this.creditAmount,
    required this.debitAmount,
    required this.isCredit,
    required this.date,
    required this.remarks,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final double debit = (json['DebitAmount'] ?? 0.0).toDouble();
    final double credit = (json['CreditAmount'] ?? 0.0).toDouble();

    return Transaction(
      id: json['TransactionHistoryId'].toString(),
      accountNumber: json['AccountNumber'] ?? '',
      transactionRef: json['InitiationTranRef'] ?? '',
      beneficiaryAccountName: json['BeneficiaryAccountName'] ?? '',
      beneficiaryAccountNumber: json['BeneficiaryAccountNumber'] ?? '',
      sourceBankName: json['SourceBankName'] ?? '',
      beneficiaryBankName: json['BeneficiaryBankName'] ?? '',
      beneficiaryBankCode: json['BeneficiaryBankCode'] ?? '',
      amount: (json['TransactionAmount'] ?? 0.0).toDouble(),
      feeAmount: (json['FeeAmount'] ?? 0.0).toDouble(),
      vatAmount: (json['VatAmount'] ?? 0.0).toDouble(),
      creditAmount: credit,
      debitAmount: debit,
      isCredit: credit > 0,
      date: DateTime.now(), // Replace with actual date field if available
      remarks: json['Remarks'] ?? '',
    );
  }
}

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<Transaction> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      print('No access token found in local storage');
      return;
    }

    final url = Uri.parse('https://demoapi.crlafrica.com/odata/customer/TransactionHistory');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> values = decoded['value'];

        setState(() {
          transactions = values.map((e) => Transaction.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        print("Failed to load transactions. Status code: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching transaction history: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Transaction History")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactions.isEmpty
              ? const Center(child: Text("No transactions found"))
              : ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return ListTile(
                      title: Text(transaction.beneficiaryAccountName),
                      subtitle: Text(transaction.transactionRef),
                      trailing: Text("₦${transaction.amount.toStringAsFixed(2)}"),
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

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _shareReceipt() {
    final receipt = '''
Transaction Receipt

Transaction ID: ${transaction.id}
Reference: ${transaction.transactionRef}
Beneficiary: ${transaction.beneficiaryAccountName} (${transaction.beneficiaryAccountNumber})
Source Bank: ${transaction.sourceBankName}
Beneficiary Bank: ${transaction.beneficiaryBankName} (${transaction.beneficiaryBankCode})
Amount: ₦${transaction.amount.toStringAsFixed(2)}
Fee: ₦${transaction.feeAmount.toStringAsFixed(2)}
VAT: ₦${transaction.vatAmount.toStringAsFixed(2)}
Remarks: ${transaction.remarks}
''';
    Share.share(receipt, subject: 'Transaction Receipt');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Transaction Receipt")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _receiptRow("Transaction ID", transaction.id),
            _receiptRow("Reference", transaction.transactionRef),
            _receiptRow("Beneficiary Name", transaction.beneficiaryAccountName),
            _receiptRow("Beneficiary Account", transaction.beneficiaryAccountNumber),
            _receiptRow("Source Bank", transaction.sourceBankName),
            _receiptRow("Beneficiary Bank", transaction.beneficiaryBankName),
            _receiptRow("Bank Code", transaction.beneficiaryBankCode),
            _receiptRow("Amount", "₦${transaction.amount.toStringAsFixed(2)}"),
            _receiptRow("Fee", "₦${transaction.feeAmount.toStringAsFixed(2)}"),
            _receiptRow("VAT", "₦${transaction.vatAmount.toStringAsFixed(2)}"),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _shareReceipt,
              icon: const Icon(Icons.share),
              label: const Text("Share Receipt"),
            ),
          ],
        ),
      ),
    );
  }
}
