import 'package:callme/data/salon_data.dart';
import 'package:flutter/material.dart';

class SalonBookingPage extends StatefulWidget {
  final String serviceName;

  const SalonBookingPage(
      {super.key, required this.serviceName, required SalonService service});

  @override
  State<SalonBookingPage> createState() => _SalonBookingPageState();
}

class _SalonBookingPageState extends State<SalonBookingPage> {
  bool homeVisit = false;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final pincodeController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// SERVICE IMAGE
            Image.asset(
              "assets/salon.png",
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            const SizedBox(height: 20),

            /// BOOKING TYPE
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Salon Appointment"),
                  selected: !homeVisit,
                  onSelected: (v) {
                    setState(() {
                      homeVisit = false;
                    });
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Home Visit"),
                  selected: homeVisit,
                  onSelected: (v) {
                    setState(() {
                      homeVisit = true;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// USER DETAILS
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
              ),
            ),

            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: "Contact No",
              ),
            ),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
              ),
            ),

            const SizedBox(height: 15),

            /// HOME VISIT EXTRA FIELDS
            if (homeVisit) ...[
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: "Full Address",
                ),
              ),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: "City",
                ),
              ),
              TextField(
                controller: pincodeController,
                decoration: const InputDecoration(
                  labelText: "Pincode",
                ),
              ),
            ],

            const SizedBox(height: 15),

            /// DATE PICKER
            ListTile(
              title: Text(selectedDate == null
                  ? "Select Appointment Date"
                  : selectedDate.toString().split(" ")[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                  initialDate: DateTime.now(),
                );

                if (date != null) {
                  setState(() {
                    selectedDate = date;
                  });
                }
              },
            ),

            /// TIME PICKER
            ListTile(
              title: Text(selectedTime == null
                  ? "Select Time"
                  : selectedTime!.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (time != null) {
                  setState(() {
                    selectedTime = time;
                  });
                }
              },
            ),

            const SizedBox(height: 25),

            /// CONFIRM BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(15),
                  backgroundColor: const Color.fromARGB(255, 185, 169, 212),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Booking Confirmed"),
                    ),
                  );
                },
                child: const Text(
                  "Confirm Booking",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
