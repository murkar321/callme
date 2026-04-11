import 'package:callme/models/cart.dart';
import 'package:flutter/material.dart';
import '../data/salon_data.dart';

class SalonBookingPage extends StatefulWidget {
  final List<SalonService> services;
  final Map<String, String> visitTypeMap;

  const SalonBookingPage({
    super.key,
    required this.services,
    required this.visitTypeMap,
  });

  @override
  State<SalonBookingPage> createState() => _SalonBookingPageState();
}

class _SalonBookingPageState extends State<SalonBookingPage> {

  Map<int, String> visitType = {};
  Map<int, DateTime> selectedDate = {};
  Map<int, TimeOfDay> selectedTime = {};

  /// 👇 COMMON INPUTS (for ALL services)
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  /// 👇 ONLY FOR HOME SERVICES
  final addressController = TextEditingController();

  @override
  void initState() {
    super.initState();

    for (var s in widget.services) {
      visitType[s.id] =
          widget.visitTypeMap[s.id.toString()] ?? "Salon";

      selectedDate[s.id] = DateTime.now();
      selectedTime[s.id] = TimeOfDay.now();
    }
  }

  Future<void> pickDate(int id) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate[id] ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => selectedDate[id] = picked);
    }
  }

  Future<void> pickTime(int id) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime[id] ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => selectedTime[id] = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Salon Booking"),
        backgroundColor: const Color(0xFFAE91BA),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const Text(
            "Selected Services",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          /// ================= SERVICES =================
          ...widget.services.map((service) {

            final type = visitType[service.id] ?? "Salon";
            final date = selectedDate[service.id]!;
            final time = selectedTime[service.id]!;

            Cart.getItems("Salon")
                .where((i) => i.id == service.id)
                .fold(0, (sum, i) => sum + i.quantity);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            service.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text("₹${service.finalPrice}")
                      ],
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(type),
                    ),

                    const SizedBox(height: 10),

                    /// DATE
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text("Select Date"),
                      subtitle: Text("${date.day}/${date.month}/${date.year}"),
                      onTap: () => pickDate(service.id),
                    ),

                    /// TIME
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text("Select Time"),
                      subtitle: Text(time.format(context)),
                      onTap: () => pickTime(service.id),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          /// ================= CONTACT INFO =================
          const Text(
            "Customer Details",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: "Phone Number",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: "Email",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 10),

          /// ================= ADDRESS ONLY FOR HOME =================
          if (widget.services.any((s) =>
              (widget.visitTypeMap[s.id.toString()] ?? "Salon") == "Home"))
            TextField(
              controller: addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Address (Only for Home Service)",
                border: OutlineInputBorder(),
              ),
            ),

          const SizedBox(height: 20),

          /// ================= CONFIRM =================
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFAE91BA),
              padding: const EdgeInsets.all(14),
            ),
            onPressed: () {

              if (phoneController.text.isEmpty ||
                  emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please fill phone & email"),
                  ),
                );
                return;
              }

              if (addressController.text.isEmpty &&
                  widget.services.any((s) =>
                      (widget.visitTypeMap[s.id.toString()] ?? "Salon") == "Home")) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please fill address for Home service"),
                  ),
                );
                return;
              }

              for (var s in widget.services) {
                debugPrint("""
Service: ${s.name}
Type: ${visitType[s.id]}
Date: ${selectedDate[s.id]}
Time: ${selectedTime[s.id]?.format(context)}
Phone: ${phoneController.text}
Email: ${emailController.text}
Address: ${addressController.text}
""");
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Booking Confirmed Successfully"),
                ),
              );
            },
            child: const Text("Confirm Booking"),
          )
        ],
      ),
    );
  }
}