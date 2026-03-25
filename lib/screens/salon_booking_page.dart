import 'package:flutter/material.dart';
import '../data/salon_data.dart';

class SalonBookingPage extends StatefulWidget {
  final List<SalonService> services;
  final bool isHomeVisitDefault;

  const SalonBookingPage({
    super.key,
    required this.services,
    this.isHomeVisitDefault = false,
  });

  @override
  State<SalonBookingPage> createState() => _SalonBookingPageState();
}

class _SalonBookingPageState extends State<SalonBookingPage> {

  String selectedVisit = "Home";
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.isHomeVisitDefault) {
      selectedVisit = "Home";
    }
  }

  /// 📅 PICK DATE
  Future<void> pickDate() async {

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  /// ⏰ PICK TIME
  Future<void> pickTime() async {

    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  /// 💰 TOTAL
  int get totalPrice {

    int total = 0;

    for (var service in widget.services) {
      total += service.finalPrice;
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Salon Booking"),
        backgroundColor: const Color(0xFFAE91BA),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// =========================
            /// SELECTED SERVICES
            /// =========================

            const Text(
              "Selected Services",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            ...widget.services.map(
              (service) => Card(
                child: ListTile(
                  leading: Image.asset(
                    service.image,
                    width: 50,
                  ),
                  title: Text(service.name),
                  subtitle: Text("₹${service.finalPrice}"),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// =========================
            /// VISIT TYPE
            /// =========================

            const Text(
              "Appointment Type",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            Row(
              children: [

                Expanded(
                  child: RadioListTile(
                    value: "Home",
                    groupValue: selectedVisit,
                    title: const Text("Home Visit"),
                    onChanged: (val) {
                      setState(() {
                        selectedVisit = val!;
                      });
                    },
                  ),
                ),

                Expanded(
                  child: RadioListTile(
                    value: "Salon",
                    groupValue: selectedVisit,
                    title: const Text("Salon Visit"),
                    onChanged: (val) {
                      setState(() {
                        selectedVisit = val!;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// =========================
            /// DATE
            /// =========================

            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Select Date"),
              subtitle: Text(
                "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
              ),
              onTap: pickDate,
            ),

            /// =========================
            /// TIME
            /// =========================

            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text("Select Time"),
              subtitle: Text(selectedTime.format(context)),
              onTap: pickTime,
            ),

            const SizedBox(height: 20),

            /// =========================
            /// ADDRESS (HOME ONLY)
            /// =========================

            if (selectedVisit == "Home") ...[

              const Text(
                "Address",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter Home Address",
                ),
              ),

              const SizedBox(height: 20),
            ],

            /// =========================
            /// PHONE
            /// =========================

            const Text(
              "Phone Number",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter Phone Number",
              ),
            ),

            const SizedBox(height: 20),

            /// =========================
            /// TOTAL
            /// =========================

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    const Text(
                      "Total",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      "₹$totalPrice",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// =========================
            /// BOOK BUTTON
            /// =========================

            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAE91BA),
                ),

                onPressed: () {

                  if (phoneController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Enter phone number"),
                      ),
                    );
                    return;
                  }

                  if (selectedVisit == "Home" &&
                      addressController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Enter address"),
                      ),
                    );
                    return;
                  }

                  /// SUCCESS

                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Booking Confirmed"),
                      content: const Text(
                        "Your salon appointment is booked successfully.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text("OK"),
                        )
                      ],
                    ),
                  );
                },

                child: const Text(
                  "Confirm Booking",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}