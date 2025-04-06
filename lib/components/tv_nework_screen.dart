import 'package:flutter/material.dart';



class TvNetworkScreen extends StatefulWidget {
  const TvNetworkScreen({super.key});

  @override
  State<TvNetworkScreen> createState() => _TvNetworkScreenState();
}

class _TvNetworkScreenState extends State<TvNetworkScreen> {
  final TextEditingController decoderController = TextEditingController();
  String selectedPackage = "Compact Plus - \u20a69,000";
  String selectedProvider = 'DSTV';

  Widget buildHistoryItem(String logoPath, String decoderNumber) {
  return Container(
    width: 70,
    margin: const EdgeInsets.only(right: 12),
    child: Column(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
            image: DecorationImage(
              image: AssetImage(logoPath),
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          decoderNumber,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}


  void _openProviderDrawer() async {
    final result = await showModalBottomSheet(
      context: context,
      builder: (context) => const ProviderDrawer(),
    );
    if (result != null) setState(() => selectedProvider = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('Cable TV', style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
      const Text(
        'History',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 90,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            buildHistoryItem('images/dstv.png', '4324'),
            buildHistoryItem('images/gotv.png', '6543'),
            // buildHistoryItem('assets/startimes.png', '7890'),
            // Add more history items here
          ],
        ),
      ),
      const SizedBox(height: 20),
          children: [
            const Text('Service Provider'),
            GestureDetector(
              onTap: _openProviderDrawer,
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(selectedProvider),
                    const Icon(Icons.arrow_drop_down)
                  ],
                ),
              ),
            ),
            const Text('Decoder Number'),
            TextField(
              controller: decoderController,
              decoration: const InputDecoration(
                hintText: '4324353452452',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Package'),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(selectedPackage),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CablePreviewScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3478F6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Proceed'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProviderDrawer extends StatelessWidget {
  const ProviderDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final providers = ['DSTV', 'GoTV', 'MyTV', 'Startimes'];

    return Container(
      padding: const EdgeInsets.all(20),
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cable', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade200,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: providers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () => Navigator.pop(context, providers[index]),
                  title: Text(providers[index]),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class CablePreviewScreen extends StatelessWidget {
  const CablePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('Adeola Adedeji .E', style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Service provider: DSTv'),
                  Text('Amount: ₦9,000.00'),
                  Text('Transaction Fee: ₦100.00'),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OtpScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3478F6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Proceed'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter OTP'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Confirm'),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SuccessScreen()),
          ),
        ),
      ),
    );
  }
}

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Success')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Payment Successful!'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Share Receipt'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Download'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
                (route) => false,
              ),
              child: const Text('Close'),
            )
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(child: Text('Welcome to Dashboard')),
    );
  }
}
