import 'package:flutter/material.dart';

class ElectricityScreen extends StatefulWidget {
  const ElectricityScreen({super.key});

  @override
  State<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends State<ElectricityScreen> {
  final meterController = TextEditingController();
  final amountController = TextEditingController();
  String type = 'Prepaid';
  String selectedProvider = 'Choose a Provider';
  int step = 1; // Step 1: Form, Step 2: Review, Step 3: PIN, Step 4: Success

  void _openProviderDrawer() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _ProviderDrawer(onSelect: (provider) {
        Navigator.pop(context, provider);
      }),
    );

    if (result != null) {
      setState(() => selectedProvider = result);
    }
  }

  void _proceedToReview() {
    if (selectedProvider == 'Choose a Provider' ||
        meterController.text.isEmpty ||
        amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }
    setState(() => step = 2);
  }

  void _proceedToPin() => setState(() => step = 3);
  void _completeTransaction() => setState(() => step = 4);
  void _resetFlow() => setState(() {
        step = 1;
        selectedProvider = 'Choose a Provider';
        meterController.clear();
        amountController.clear();
        type = 'Prepaid';
      });

  @override
  Widget build(BuildContext context) {
    switch (step) {
      case 1:
        return _buildFormStep();
      case 2:
        return _buildReviewStep();
      case 3:
        return _buildPinStep();
      case 4:
        return _buildSuccessStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Scaffold _buildFormStep() {
    return Scaffold(
      appBar: AppBar(title: const Text('Electricity')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _openProviderDrawer,
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Service Provider',
                    hintText: selectedProvider,
                  ),
                ),
              ),
            ),
            TextFormField(
              controller: meterController,
              decoration: const InputDecoration(labelText: 'Meter Number'),
            ),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            Row(
              children: ['Prepaid', 'Postpaid'].map((e) {
                return Expanded(
                  child: RadioListTile<String>(
                    title: Text(e),
                    value: e,
                    groupValue: type,
                    onChanged: (val) => setState(() => type = val!),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _proceedToReview,
              child: const Text("Proceed"),
            ),
          ],
        ),
      ),
    );
  }

  Scaffold _buildReviewStep() {
    return Scaffold(
      appBar: AppBar(title: const Text("Review"), leading: BackButton(onPressed: () => setState(() => step = 1))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _reviewItem("Provider", selectedProvider),
            _reviewItem("Meter Number", meterController.text),
            _reviewItem("Amount", "₦${amountController.text}"),
            _reviewItem("Type", type),
            _reviewItem("Fee", "₦100.00"),
            const Spacer(),
            ElevatedButton(
              onPressed: _proceedToPin,
              child: const Text("Send"),
            )
          ],
        ),
      ),
    );
  }

  Widget _reviewItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(title), Text(value)],
      ),
    );
  }

  Scaffold _buildPinStep() {
    String pin = '';
    void addDigit(String digit) {
      if (pin.length < 4) {
        setState(() => pin += digit);
      }
      if (pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 300), _completeTransaction);
      }
    }

    void removeDigit() {
      if (pin.isNotEmpty) {
        setState(() => pin = pin.substring(0, pin.length - 1));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Enter PIN"), leading: BackButton(onPressed: () => setState(() => step = 2))),
      body: Column(
        children: [
          const SizedBox(height: 30),
          const Center(child: Text("Enter 4-digit PIN to authorize payment")),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              4,
              (i) => Container(
                margin: const EdgeInsets.all(8),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: i < pin.length ? Colors.black : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ...List.generate(9, (i) => _pinButton('${i + 1}', () => addDigit('${i + 1}'))),
              const SizedBox(),
              _pinButton('0', () => addDigit('0')),
              IconButton(onPressed: removeDigit, icon: const Icon(Icons.backspace)),
            ],
          )
        ],
      ),
    );
  }

  Widget _pinButton(String digit, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Center(child: Text(digit, style: const TextStyle(fontSize: 24))),
      ),
    );
  }

  Scaffold _buildSuccessStep() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text('Payment Successful!', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _resetFlow,
              child: const Text('Make another payment'),
            )
          ],
        ),
      ),
    );
  }
}

class _ProviderDrawer extends StatelessWidget {
  final Function(String) onSelect;
  const _ProviderDrawer({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final providers = [
      'ABUJA ELECTRICITY DISTRIBUTION',
      'ENUGU ELECTRICITY SHARING HOLDING',
      'IBEDC-IBEDC',
      'IKEDC'
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: providers.length,
        itemBuilder: (_, index) => ListTile(
          title: Text(providers[index]),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onSelect(providers[index]),
        ),
      ),
    );
  }
}