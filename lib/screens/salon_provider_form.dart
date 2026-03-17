import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SalonProviderForm extends StatefulWidget {
  const SalonProviderForm({super.key});

  @override
  State<SalonProviderForm> createState() => _SalonProviderFormState();
}

class _SalonProviderFormState extends State<SalonProviderForm> {
  final _formKey = GlobalKey<FormState>();

  final salonName = TextEditingController();
  final ownerName = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final city = TextEditingController();
  final stateController = TextEditingController();
  final experience = TextEditingController();
  final staff = TextEditingController();
  final bank = TextEditingController();

  bool isLoading = false;

  List<String> selectedServices = [];

  final services = [
    "Hair Cut",
    "Hair Styling",
    "Hair Treatments",
    "Hair Color",
    "Facial",
    "Makeup",
    "Manicure",
    "Pedicure",
    "Waxing"
  ];

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one service")),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      await FirebaseFirestore.instance.collection("salon_providers").add({
        "salonName": salonName.text.trim(),
        "ownerName": ownerName.text.trim(),
        "phone": phone.text.trim(),
        "email": email.text.trim(),
        "address": address.text.trim(),
        "city": city.text.trim(),
        "state": stateController.text.trim(),
        "experience": experience.text.trim(),
        "staff": staff.text.trim(),
        "bankAccount": bank.text.trim(),
        "services": selectedServices,
        "createdAt": Timestamp.now()
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Salon Registered Successfully 🎉")),
      );

      _formKey.currentState!.reset();
      selectedServices.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  Widget inputField(TextEditingController controller, String label,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter $label";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget buildServiceSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Services Provided",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: services.map((service) {
                final selected = selectedServices.contains(service);

                return FilterChip(
                  label: Text(service),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        selectedServices.add(service);
                      } else {
                        selectedServices.remove(service);
                      }
                    });
                  },
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    salonName.dispose();
    ownerName.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
    city.dispose();
    stateController.dispose();
    experience.dispose();
    staff.dispose();
    bank.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Salon Registration"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              /// Header Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: const [
                      Icon(Icons.content_cut, size: 60, color: Colors.pink),
                      SizedBox(height: 8),
                      Text(
                        "Register Your Salon",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Join our platform and grow your business",
                        textAlign: TextAlign.center,
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              inputField(salonName, "Salon Name"),
              inputField(ownerName, "Owner Name"),
              inputField(phone, "Phone", type: TextInputType.phone),
              inputField(email, "Email", type: TextInputType.emailAddress),
              inputField(address, "Salon Address"),
              inputField(city, "City"),
              inputField(stateController, "State"),
              inputField(experience, "Experience (years)",
                  type: TextInputType.number),
              inputField(staff, "Number of Staff", type: TextInputType.number),
              inputField(bank, "Bank Account Number",
                  type: TextInputType.number),

              const SizedBox(height: 10),

              buildServiceSelector(),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submitForm,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Register Salon",
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
