import 'package:flutter/material.dart';

class UpiPaymentScreen extends StatefulWidget {
  final double amount;

  const UpiPaymentScreen({super.key, required this.amount});

  @override
  State<UpiPaymentScreen> createState() => _UpiPaymentScreenState();
}

class _UpiPaymentScreenState extends State<UpiPaymentScreen> {
  String selectedUpi = '';

  final List<Map<String, dynamic>> upiApps = [
    {
      'name': 'Google Pay',
      'icon': Icons.account_balance_wallet,
    },
    {
      'name': 'PhonePe',
      'icon': Icons.phone_android,
    },
    {
      'name': 'Paytm',
      'icon': Icons.payment,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UPI Payment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 💰 Amount
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${widget.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Select UPI App',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            /// 📱 UPI Options
            ...upiApps.map((app) {
              return Card(
                child: RadioListTile(
                  value: app['name'],
                  groupValue: selectedUpi,
                  onChanged: (value) {
                    setState(() {
                      selectedUpi = value.toString();
                    });
                  },
                  title: Text(app['name']),
                  secondary: Icon(app['icon']),
                ),
              );
            }),

            const Spacer(),

            /// ✅ Pay Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _payNow,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _payNow() {
    if (selectedUpi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a UPI app')),
      );
      return;
    }

    /// ✅ Fake Success (Demo)
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Payment Successful'),
        content: Text('Paid via $selectedUpi'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true); // return success
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
