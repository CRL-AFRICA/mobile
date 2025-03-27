import 'package:flutter/material.dart';
import '../widgets/custom_amount_text_field.dart' show AmountField;
import 'otp_screen.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

void main() {
  runApp(const SendMoneyApp());
}

class SendMoneyApp extends StatelessWidget {
  const SendMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SendMoneyScreen(),
    );
  }
}

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  String? selectedBank;
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController narrationController = TextEditingController();
  List<Map<String, String>> banks = [];
  bool isLoading = true;
  bool hasError = false;
  String? accountName;

  @override
  void initState() {
    super.initState();
    fetchBanks();
  }

  Future<void> fetchBanks() async {
    try {
      Dio dio = Dio();
      final response = await dio.get(
        "http://20.160.237.234:9080/customer/api/Nip/Bank",
      ); // Replace with actual API URL

      if (response.statusCode == 200 && response.data["banks"] is List) {
        List<dynamic> bankData = response.data["banks"];

        setState(() {
          banks =
              bankData
                  .map<Map<String, String>>(
                    (bank) => {
                      "bankCode": bank["bankCode"].toString(),
                      "bankName": bank["bankName"].toString(),
                    },
                  )
                  .toList();
          isLoading = false;
          hasError = false;
        });
      } else {
        throw Exception("Invalid response format");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      debugPrint("Error fetching banks: $e");
    }
  }

  Future<void> fetchAccountName() async {
    if (selectedBank == null || accountNumberController.text.isEmpty) return;

    const String apiUrl =
        "http://20.160.237.234:9080/customer/api/Nip/InterBankNameEnquiry";

    try {
      Dio dio = Dio();
      final response = await dio.post(
        apiUrl,
        data: jsonEncode({
          "accountNumber": accountNumberController.text,
          "beneficiaryBank": selectedBank!,
        }),
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      if (response.statusCode == 200) {
        setState(() {
          accountName =
              response.data["accountName"] ?? "Account name not found";
        });
      } else {
        setState(() {
          accountName = "Error fetching account name";
        });
      }
    } catch (e) {
      setState(() {
        accountName = "Network error";
      });
      debugPrint("Error fetching account name: $e");
    }
  }

  bool get isFormFilled {
    return selectedBank != null &&
        accountNumberController.text.isNotEmpty &&
        amountController.text.isNotEmpty &&
        narrationController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Send Money",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              "Enter the receiver’s details to make an instant transfer",
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Beneficiaries",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    "Find Beneficiary",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // Bank Selection Dropdown
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.grey),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "No frequent beneficiaries available",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 25),
            Text(
              "Beneficiary Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : hasError
                ? const Text(
                  "Failed to load banks. Please try again.",
                  style: TextStyle(color: Colors.red),
                )
                : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      hint: const Text("Select bank"),
                      value: selectedBank,
                      isExpanded: true,
                      onChanged: (value) {
                        setState(() {
                          selectedBank = value;
                        });
                      },
                      items:
                          banks.map((bank) {
                            return DropdownMenuItem(
                              value: bank["bankName"],
                              child: Text(bank["bankName"]!),
                            );
                          }).toList(),
                    ),
                  ),
                ),
            const SizedBox(height: 15),

            // Account Number Input
            TextField(
              controller: accountNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Account Number",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value.length >= 10 && selectedBank != null) {
                  fetchAccountName();
                }
              },
            ),
             SizedBox(height: 10),
            accountName != null
                ? Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    " $accountName",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                  ),
                )
                : SizedBox(),
            const SizedBox(height: 15),

            // Amount Input
            AmountField(controller: amountController),
           
            const SizedBox(height: 15),

            // Narration Input
            TextField(
              controller: narrationController,
              decoration: InputDecoration(
                labelText: "Narration",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const Spacer(),

            // Continue Button
            if (isFormFilled)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Review Screen with input values
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ReviewScreen(
                              bankName: selectedBank!,
                              accountNumber: accountNumberController.text,
                              amount: amountController.text,
                              narration: narrationController.text,
                            ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Continue", style: TextStyle(fontSize: 18)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ReviewScreen extends StatelessWidget {
  final String bankName;
  final String accountNumber;
  final String amount;
  final String narration;

  const ReviewScreen({
    super.key,
    required this.bankName,
    required this.accountNumber,
    required this.amount,
    required this.narration,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Review",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Review Details
            _buildInfoRow("Bank", bankName),
            _buildInfoRow("Account Number", accountNumber),
            _buildInfoRow("Amount", "₦ $amount"),
            _buildInfoRow("Narration", narration),
            _buildInfoRow("Commission", "₦10.75"),
            _buildInfoRow("Total", "₦ $amount"),

            const Spacer(),

            // Send Money Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // Navigate to OTP Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OTPScreen()),
                  );
                },
                child: const Text(
                  "Send Money",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
