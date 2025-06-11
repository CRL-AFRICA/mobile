import 'package:flutter/material.dart';

import '../widgets/custom_amount_currency_text_field.dart'
    show AmountInputField;
import 'data_otp_view.dart';

class DataInputScreen extends StatefulWidget {
  const DataInputScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DataInputScreenState createState() => _DataInputScreenState();
}

class _DataInputScreenState extends State<DataInputScreen> {
  final _formKey = GlobalKey<FormState>();
  String? networkProvider, phoneNumber;
  String? amount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Data",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text("Select your network provider to get instant data."),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Beneficiaries",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Find Beneficiary",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.people, color: Colors.grey),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "No frequent beneficiaries available",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text("Select network provider"),
                items:
                    ["MTN", "Airtel", "Glo", "9mobile"].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (value) => setState(() => networkProvider = value),
                validator:
                    (value) => value == null ? "Select a provider" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Phone number",
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) => setState(() => phoneNumber = value),
                validator:
                    (value) => value!.isEmpty ? "Enter phone number" : null,
              ),
              const SizedBox(height: 10),
              AmountInputField(
                onChanged: (value) {
                  setState(() {
                    amount =
                        value.isEmpty
                            ? null
                            : value; // Now it's stored as a string
                  });
                },
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6197BC),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    if (networkProvider != null &&
                        phoneNumber != null &&
                        amount != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ReviewScreen(
                                phoneNumber: phoneNumber!,
                                amount: amount!,
                                provider: networkProvider!,
                              ),
                        ),
                      );
                    } else {
                      print("Error: One of the required fields is null.");
                    }
                  }
                },
                child: const Text("Next", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewScreen extends StatelessWidget {
  final String phoneNumber;
  final String amount;
  final String provider;

  const ReviewScreen({
    super.key,
    required this.phoneNumber,
    required this.amount,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              "Review",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // From & To Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("From", style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 4),
                    Text(
                      "2018253547",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("To", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      provider,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      phoneNumber,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Amount with Line Representation
            Row(
              children: [
                const Expanded(child: Divider(color: Colors.black, thickness: 2)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    "₦$amount",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(child: Divider(color: Colors.black, thickness: 2)),
              ],
            ),

            const SizedBox(height: 30),

            // Narration Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFDCEAF5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "AIRTIME/$provider$phoneNumber",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),

            const Spacer(),

            // Send Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6197BC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // Navigate to OTP Screen
                  Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OTPScreen()),
        );
                  
                },
                child: const Text(
                  "Send",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 20),
            Text(
              "Transaction Successful!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
