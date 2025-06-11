import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/toast.dart';
import 'dart:convert';

import 'forgot_pin_security_questions_screen.dart' show ForgotPinScreen;



class SendToCRSScreen extends StatefulWidget {
  const SendToCRSScreen({super.key});

  @override
  State<SendToCRSScreen> createState() => _SendToCRSScreenState();
}

class _SendToCRSScreenState extends State<SendToCRSScreen> {
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
  }

Future<void> fetchAccountName() async {
  if (accountNumberController.text.isEmpty) return;

  const String apiUrl =
      "https://demoapi.crlafrica.com/api/customer/Nip/IntraBankNameEnquiry";

  try {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      setState(() {
        accountName = "Access token not found. Please login.";
      });
      return;
    }

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode({
        "accountNumber": accountNumberController.text,
      }),
    );

    print("Name Enquiry Response (${response.statusCode}): ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        accountName = data["accountName"] ?? "Account name not found";
      });
    } else if (response.statusCode == 204) {
      setState(() {
        accountName = "Account name not found";
      });
    } else {
      setState(() {
        accountName = "Error fetching account name: ${response.statusCode}";
      });
    }
  } catch (e) {
    setState(() {
      accountName = "Network error: $e";
    });
  }
}

  bool get isFormFilled {
    return accountNumberController.text.isNotEmpty &&
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
                const Text(
                  "Recent Beneficiaries",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
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
            const SizedBox(height: 12),
            // Bank Selection Dropdown
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
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
            const SizedBox(height: 25),
            const Text(
              "Beneficiary Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Account Number Input
            TextField(
              controller: accountNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Account Number",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value.length >= 10 ) {
                  fetchAccountName();
                }
              },
            ),
             const SizedBox(height: 10),
            accountName != null
                ? Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    " $accountName",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                  ),
                )
                : const SizedBox(),
            const SizedBox(height: 15),

            // Amount Input
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
                border: OutlineInputBorder(),
              ),
            ),
           
            const SizedBox(height: 15),

            // Narration Input
            TextField(
              controller: narrationController,
              decoration: const InputDecoration(
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
                              
                              accountNumber: accountNumberController.text,
                              amount: amountController.text,
                              narration: narrationController.text,
                               accountName: accountName ?? "Unknown",
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
  final String accountNumber;
  final String amount;
  final String narration;
   final String accountName;

  const ReviewScreen({
    super.key,
    required this.accountNumber,
    required this.amount,
    required this.narration,
    required this.accountName,
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
            _buildInfoRow("Account Number", accountNumber),
            _buildInfoRow("Account Name", accountName),
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
                    MaterialPageRoute(
                      builder: (context) => OtpScreen(
                        accountName: accountName,
                        accountNumber: accountNumber,
                        amount: amount,
                        narration: narration,
                      ),
                    ),
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


class OtpScreen extends StatefulWidget {
  final String accountName;
  final String accountNumber;
  final String amount;
  final String narration;

  const OtpScreen({
    super.key,
    required this.accountName,
    required this.accountNumber,
    required this.amount,
    required this.narration,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String pin = '';
  String? debitAccount;

  @override
  void initState() {
    super.initState();
    _loadSourceAccountData();
  }

  Future<void> _loadSourceAccountData() async {
    final prefs = await SharedPreferences.getInstance();
      final accountNames = prefs.getString('myAccountName') ?? '';
  final accountNumber = prefs.getString('myAccountNumber') ?? '';

  print("Loaded Account Name: $accountNames");
  print("Loaded Account Number: $accountNumber");

    setState(() {
      debitAccount = accountNumber;
    });
  }

  void _addDigit(String digit) {
    if (pin.length < 4) {
      setState(() {
        pin += digit;
      });
    }
  }

  void _deleteDigit() {
    if (pin.isNotEmpty) {
      setState(() {
        pin = pin.substring(0, pin.length - 1);
      });
    }
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < pin.length ? Colors.black : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  Widget _buildKeypadButton(String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => _addDigit(label),
      child: Container(
        alignment: Alignment.center,
        height: 75,
        child: Text(
          label,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  String _generateTransactionReference() {
    final randomDigits = List.generate(16, (index) => (index * 7 + 3) % 10).join();
    return randomDigits;
  }

void _submitPin() async {
  if (pin.length != 4) return;

  if (debitAccount == null || debitAccount!.isEmpty) {
    showToast("Loading your account info, please wait...");
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('accessToken') ?? '';

  if (accessToken.isEmpty) {
    showToast("Authentication failed. Please login again.");
    return;
  }

  final transactionReference = _generateTransactionReference();

  final requestBody = {
    "beneficiaryAccountName": widget.accountName,
    "transactionAmount": double.tryParse(widget.amount) ?? 0,
    "narration": widget.narration,
    "debitAccount": debitAccount!,
    "beneficiaryAccountNumber": widget.accountNumber,
    "beneficiaryBankCode": "CRL Africa",
    "beneficiaryBankName": "CRL Africa",
    "transactionReference": transactionReference,
     "saveBeneficiary": true,
  "beneficiaryAlias": "string",
    "transactionPin": pin,
  };

  try {
    final response = await http.post(
      Uri.parse("https://demoapi.crlafrica.com/api/customer/Nip/IntraBankTransfer"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
     Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => SuccessScreen(
      transactionReference: transactionReference,
      amount: widget.amount,
      accountName: widget.accountName,
      accountNumber: widget.accountNumber,
      bankName: "CRL Africa",
      narration: widget.narration,
    ),
  ),
);
    } else {
      final responseJson = jsonDecode(response.body);

      String errorMessage = "Transaction failed";

      if (responseJson is Map && responseJson.containsKey('errors')) {
        final errors = responseJson['errors'] as Map<String, dynamic>;
        List<String> allErrors = [];
        errors.forEach((key, value) {
          if (value is List) {
            allErrors.addAll(value.map((e) => e.toString()));
          } else {
            allErrors.add(value.toString());
          }
        });
        errorMessage = allErrors.join('\n');
      } else if (responseJson.containsKey('detail')) {
        errorMessage = responseJson['detail'];
      } else {
        errorMessage = response.body;
      }

      showToast(errorMessage);
    }
  } catch (e) {
    showToast("Error: ${e.toString()}");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Enter PIN',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter transaction 4-digit PIN-code or use your biometrics\nto perform action.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),
          _buildPinDots(),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                ...List.generate(9, (index) {
                  final digit = (index + 1).toString();
                  return _buildKeypadButton(digit);
                }),
                _buildKeypadButton('', onTap: () {}),
                _buildKeypadButton('0'),
                _buildKeypadButton('⌫', onTap: _deleteDigit),
              ],
            ),
          ),
          if (pin.length == 4)
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ElevatedButton(
                onPressed: _submitPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          TextButton(
            onPressed: () {
               Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ForgotPinScreen()),
        );
            },
            child: const Text(
              'Forgot Pin?',
              style: TextStyle(color: Colors.blue),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class SuccessScreen extends StatelessWidget {
  final String accountName;
  final String amount;
  final String narration;
  final String accountNumber;
  final String bankName;
  final String transactionReference;

  const SuccessScreen({
    super.key,
    required this.accountName,
    required this.amount,
    required this.narration,
    required this.accountNumber,
    required this.bankName,
    required this.transactionReference,
  });

  Future<void> generateReceiptPdf() async {
    final pdf = pw.Document();
    final logo = pw.MemoryImage(
      (await rootBundle.load('images/logo.png')).buffer.asUint8List(),
    );

    final transactionDate = DateTime.now();
    final parsedAmount = double.tryParse(amount) ?? 0.0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(20),
          color: PdfColor.fromHex("#F5F7FA"),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Image(logo, height: 60)),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'Receipt',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex("#002B5C"), // Dark Blue
                  ),
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text("Transfer",
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _buildRow("Transfer ID", transactionReference),
              _buildRow("Transaction date",
                  "${transactionDate.day}-${_monthName(transactionDate.month)}-${transactionDate.year}"),
              _buildRow("Destination Name", accountName),
              _buildRow("Destination", accountNumber),
              _buildRow("Amount", "₦${parsedAmount.toStringAsFixed(2)}"),
              _buildRow("Receiver’s Bank", bankName),
              _buildRow("Reason", narration),
              pw.Spacer(),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Thank you for banking with us',
                  style: pw.TextStyle(
                      fontSize: 12, color: PdfColor.fromHex("#888")),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  pw.Widget _buildRow(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(value),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Successful')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: generateReceiptPdf,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text("Download Receipt"),
        ),
      ),
    );
  }
}
