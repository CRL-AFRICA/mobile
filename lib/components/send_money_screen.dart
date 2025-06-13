import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
// import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../pages/dashboard.dart';
import '../utils/toast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'forgot_pin_security_questions_screen.dart' show ForgotPinScreen;

void main() {
  runApp(const SendMoneyApp());
}

class SendMoneyApp extends StatelessWidget {
  const SendMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
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
  String? selectedBankCode;
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController narrationController = TextEditingController();
  List<Map<String, String>> banks = [];
  bool isLoading = true;
  bool hasError = false;
  String? accountName;
  String? vatFee;
  double? accountBalance;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchBanks();
    fetchAccountBalance();
  }

  Future<void> fetchAccountBalance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final storedBalanceString = prefs.getString('accountBalance');
    double balance = 0.0;
    if (storedBalanceString != null) {
      balance = double.tryParse(storedBalanceString) ?? 0.0;
    }

    setState(() {
      accountBalance = balance;
    });
  }

  Future<void> fetchBanks() async {
    try {
      final response = await http.get(
        Uri.parse("https://demoapi.crlafrica.com/api/customer/Nip/Bank"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["banks"] is List) {
          List<dynamic> bankData = data["banks"];

          setState(() {
            banks = bankData.map<Map<String, String>>((bank) {
              return {
                "bankCode": bank["bankCode"].toString(),
                "bankName": bank["bankName"].toString(),
              };
            }).toList();
            isLoading = false;
            hasError = false;
          });
        } else {
          throw Exception("Invalid response format");
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Future<void> fetchAccountName() async {
    if (selectedBank == null || accountNumberController.text.isEmpty) return;

    const String apiUrl =
        "https://demoapi.crlafrica.com/api/customer/Nip/InterBankNameEnquiry";

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
          "beneficiaryBank": selectedBank!,
          "beneficiaryBankCode": selectedBankCode!,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          accountName = data["accountName"] ?? "Account name not found";
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

  Future<void> fetchVatFee(String amount) async {
    final url = Uri.parse(
      "https://demoapi.crlafrica.com/api/customer/Nip/InterBankTransferFee/$amount",
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        setState(() {
          vatFee = "Access token not found. Please login.";
        });
        return;
      }

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final totalFees = decoded["totalFees"]?.toString() ?? "0.00";

        setState(() {
          vatFee = totalFees;
        });
      } else {
        setState(() {
          vatFee = "0.00";
        });
      }
    } catch (e) {
      setState(() {
        vatFee = "0.00";
      });
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
      resizeToAvoidBottomInset: true,
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
      body: SingleChildScrollView(
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
            if (accountBalance != null)
              Text(
                "Account Balance: ₦${accountBalance!.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 16, color: Colors.blue),
              ),
            const SizedBox(height: 15),
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
            const SizedBox(height: 10),
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
                                selectedBankCode = banks.firstWhere(
                                  (bank) => bank["bankName"] == value,
                                  orElse: () => {"bankCode": ""},
                                )["bankCode"];
                              });
                            },
                            items: banks.map((bank) {
                              return DropdownMenuItem(
                                value: bank["bankName"],
                                child: Text(bank["bankName"]!),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
            const SizedBox(height: 15),
            TextField(
              controller: accountNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Account Number",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value.length >= 10 && selectedBank != null) {
                  fetchAccountName();
                }
              },
            ),
            const SizedBox(height: 10),
            if (accountName != null)
              Align(
                alignment: Alignment.centerRight,
                child: Text(accountName!, style: const TextStyle(fontSize: 16)),
              ),
            const SizedBox(height: 15),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  fetchVatFee(value);
                }
              },
            ),
            const SizedBox(height: 10),
            if (vatFee != null)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "VAT Fee: ₦$vatFee",
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              ),
            const SizedBox(height: 15),
            TextField(
              controller: narrationController,
              decoration: const InputDecoration(
                labelText: "Narration",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 25),
            if (isFormFilled)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewScreen(
                          bankName: selectedBank!,
                          bankCode: selectedBankCode!,
                          accountNumber: accountNumberController.text,
                          amount: amountController.text,
                          narration: narrationController.text,
                          accountName: accountName!,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text("Continue", style: TextStyle(fontSize: 18)),
                ),
              ),
            const SizedBox(
                height: 40), // Extra space at the bottom for keyboard
          ],
        ),
      ),
    );
  }
}

class ReviewScreen extends StatelessWidget {
  final String bankName;
  final String bankCode;
  final String accountNumber;
  final String amount;
  final String narration;
  final String accountName;

  const ReviewScreen({
    super.key,
    required this.bankName,
    required this.bankCode,
    required this.accountNumber,
    required this.amount,
    required this.narration,
    required this.accountName,
  });

  @override
  Widget build(BuildContext context) {
    final double amountValue = double.tryParse(amount) ?? 0.0;
    const double commission = 0.75;
    final double total = amountValue + commission;

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
            _buildInfoRow("Amount", "₦${amountValue.toStringAsFixed(2)}"),
            _buildInfoRow("Narration", narration),
            _buildInfoRow("Vat Fee", "₦${commission.toStringAsFixed(2)}"),
            _buildInfoRow("Total", "₦${total.toStringAsFixed(2)}"),

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
                        bankName: bankName,
                        bankCode: bankCode,
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
  final String bankName;
  final String bankCode;

  const OtpScreen({
    super.key,
    required this.accountName,
    required this.accountNumber,
    required this.amount,
    required this.narration,
    required this.bankName,
    required this.bankCode,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String pin = '';
  String? sourceAccountName;
  String? sourceAccountNumber;

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
      sourceAccountName = accountNames;
      sourceAccountNumber = accountNumber;
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
    final randomDigits =
        List.generate(16, (index) => (index * 7 + 3) % 10).join();
    return randomDigits;
  }

  void _submitPin() async {
    if (pin.length != 4) return;

    if (sourceAccountName == null ||
        sourceAccountNumber == null ||
        sourceAccountName!.isEmpty ||
        sourceAccountNumber!.isEmpty) {
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
      "saveBeneficiary": true,
      "beneficiaryAlias": "string",
      "transactionAmount": double.tryParse(widget.amount) ?? 0,
      "narration": widget.narration,
      "sourceAccountName": sourceAccountName!,
      "sourceAccountNumber": sourceAccountNumber!,
      "beneficiaryAccountNumber": widget.accountNumber,
      "beneficiaryBankCode": widget.bankCode,
      "beneficiaryBankName": widget.bankName,
      "transactionReference": transactionReference,
      "transactionPin": pin,
    };

    try {
      final response = await http.post(
        Uri.parse(
          "https://demoapi.crlafrica.com/api/customer/Nip/InterBankTransfer",
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SuccessScreen(
              accountName: widget.accountName,
              amount: widget.amount,
              narration: widget.narration,
              accountNumber: widget.accountNumber,
              bankName: widget.bankName,
              transactionReference: transactionReference,
              sourceAccountName: sourceAccountName!,
              sourceAccountNumber: sourceAccountNumber!,
            ),
          ),
        );
      } else {
        print("Transaction failed: ${response.statusCode} - ${response.body}");

        // Decode response body for better error extraction
        try {
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
        } catch (_) {
          // fallback if decoding fails
          showToast("Transaction failed: ${response.body}");
        }
      }
    } catch (e, stackTrace) {
      print("Error during transaction: $e");
      print("Stack trace: $stackTrace");

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Submit', style: TextStyle(fontSize: 16)),
              ),
            ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ForgotPinScreen()),
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
  final String sourceAccountName;
  final String sourceAccountNumber;

  const SuccessScreen({
    super.key,
    required this.accountName,
    required this.amount,
    required this.narration,
    required this.accountNumber,
    required this.bankName,
    required this.transactionReference,
    required this.sourceAccountName,
    required this.sourceAccountNumber,
  });

  Future<void> generateReceiptPdf({
    bool download = true,
    bool asImage = false,
  }) async {
    final pdf = pw.Document();
    final transactionDate = DateTime.now();
    final parsedAmount = double.tryParse(amount) ?? 0.0;

    pw.MemoryImage? logoImage;
    try {
      final logoBytes =
          (await rootBundle.load('images/logo.png')).buffer.asUint8List();
      logoImage = pw.MemoryImage(logoBytes);
    } catch (_) {}

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoImage != null)
                pw.Center(child: pw.Image(logoImage, height: 60)),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text('Receipt',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 30),
              _buildRow("Transfer ID", transactionReference),
              _buildRow("Date",
                  "${transactionDate.day}-${_monthName(transactionDate.month)}-${transactionDate.year}"),
              _buildRow("Sender", sourceAccountName),
              _buildRow("Source",
                  "xxxxx${sourceAccountNumber.substring(sourceAccountNumber.length - 4)}"),
              _buildRow("Receiver", accountName),
              _buildRow("Destination", accountNumber),
              _buildRow("Bank", bankName),
              _buildRow("Amount", "₦${parsedAmount.toStringAsFixed(2)}"),
              _buildRow("Narration", narration),
            ],
          ),
        ),
      ),
    );

    final bytes = await pdf.save();
    final directory = await getTemporaryDirectory();

    if (download) {
      final file = File('${directory.path}/receipt.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: "Transaction Receipt");
    } else if (asImage) {
      final raster = await Printing.raster(bytes, dpi: 300);
      final imageList = await raster.toList(); // Converts stream to list
      if (imageList.isNotEmpty) {
        final png = await imageList.first.toPng();
        final file = File('${directory.path}/receipt.png');
        await file.writeAsBytes(png);
        await Share.shareXFiles([XFile(file.path)],
            text: "Transaction Receipt (Image)");
      }
    }
  }

  pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height - kToolbarHeight,
          width: double.infinity,
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset('images/success.json',
                      height: 140, repeat: false),
                  const SizedBox(height: 16),
                  const Text(
                    'Transaction was successful!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async =>
                            await generateReceiptPdf(download: true),
                        icon: const Icon(Icons.download),
                        label: const Text("Download PDF"),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async => await generateReceiptPdf(
                            download: false, asImage: true),
                        icon: const Icon(Icons.image),
                        label: const Text("Image"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton.icon(
                    onPressed: () async => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DashboardScreen())),
                    icon: const Icon(Icons.home),
                    label: const Text("Back to dashboard"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
