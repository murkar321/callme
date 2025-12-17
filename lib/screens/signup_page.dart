import 'package:callme/screens/home_page.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<SignupPage> {
  final TextEditingController _mobileController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Image.asset('assets/logo.png', height: 100),
            const SizedBox(height: 20),
            const Text('Enter Mobile Number', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            TextField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixText: '+91 ',
                labelText: 'Your 10-digit number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Get OTP'),
            ),
            const SizedBox(height: 10),
            const Text('Terms & Conditions'),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
