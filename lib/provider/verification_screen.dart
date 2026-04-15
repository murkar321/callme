import 'package:flutter/material.dart';

class VerificationScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String email;

  const VerificationScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final aadharController = TextEditingController();
  final panController = TextEditingController();
  final bankController = TextEditingController();
  final accountController = TextEditingController();
  final upiController = TextEditingController();

  bool ownTools = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verification")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            /// 🔹 TOOLS SWITCH
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Own Tools"),
                Switch(
                  value: ownTools,
                  onChanged: (val) {
                    setState(() {
                      ownTools = val;
                    });
                  },
                )
              ],
            ),

            buildField("Aadhar Card", aadharController),
            buildField("PAN Card", panController),
            buildField("Bank Account Number", bankController),
            buildField("Account Holder Name", accountController),
            buildField("UPI ID (Optional)", upiController),

            const SizedBox(height: 20),

            /// 🔹 SUBMIT BUTTON
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Submitted Successfully ✅"),
                    ),
                  );

                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text("Submit"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}