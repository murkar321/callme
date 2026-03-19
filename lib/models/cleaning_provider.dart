import 'package:flutter/material.dart';

////////////////////////////////////////////////////////////
/// ENTRY
////////////////////////////////////////////////////////////

class CleaningProvider extends StatelessWidget {
  const CleaningProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return const UserTypeSelectionScreen();
  }
}

////////////////////////////////////////////////////////////
/// COMMON FIELD
////////////////////////////////////////////////////////////

Widget field(String label, IconData icon) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}

////////////////////////////////////////////////////////////
/// 1️⃣ USER TYPE SELECTION
////////////////////////////////////////////////////////////

class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Type")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(context, "Individual", Icons.person),
            _card(context, "Business", Icons.store),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ServiceSelectionScreen(),
            ),
          );
        },
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// 2️⃣ SERVICE SELECTION
////////////////////////////////////////////////////////////

class ServiceSelectionScreen extends StatefulWidget {
  const ServiceSelectionScreen({super.key});

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
  final List<Map<String, dynamic>> services = [
    {"name": "Home Cleaning", "icon": Icons.home},
    {"name": "Bathroom Cleaning", "icon": Icons.bathtub},
    {"name": "Kitchen Cleaning", "icon": Icons.kitchen},
    {"name": "Sofa Cleaning", "icon": Icons.weekend},
    {"name": "Carpet Cleaning", "icon": Icons.layers},
  ];

  final List<String> selected = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Services")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: services.map((service) {
                return CheckboxListTile(
                  title: Text(service["name"]),
                  secondary: Icon(service["icon"]),
                  value: selected.contains(service["name"]),
                  onChanged: (val) {
                    setState(() {
                      if (val!) {
                        selected.add(service["name"]);
                      } else {
                        selected.remove(service["name"]);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PersonalDetailsScreen(),
                  ),
                );
              },
              child: const Text("Next"),
            ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// 3️⃣ PERSONAL DETAILS
////////////////////////////////////////////////////////////

class PersonalDetailsScreen extends StatelessWidget {
  const PersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Personal Details")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  field("Full Name", Icons.person),
                  field("Phone Number", Icons.phone),
                  field("Email ID", Icons.email),
                  field("Address", Icons.home),
                  field("City", Icons.location_city),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BankDetailsScreen(),
                  ),
                );
              },
              child: const Text("Next"),
            ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// 4️⃣ BANK + OWN TOOLS
////////////////////////////////////////////////////////////

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  bool ownTools = false;

  void showSuccess(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Success"),
        content: const Text("Registration Confirmed 🎉"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bank Details")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  field("Bank Account Number", Icons.account_balance),
                  field("IFSC Code", Icons.code),
                  field("PAN Card", Icons.badge),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text("Do you own tools?"),
                    secondary: const Icon(Icons.build),
                    value: ownTools,
                    onChanged: (val) {
                      setState(() {
                        ownTools = val;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                showSuccess(context);
              },
              child: const Text("Submit"),
            ),
          ),
        ],
      ),
    );
  }
}
