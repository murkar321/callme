import 'package:callme/screens/booking_success_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/salon_data.dart';

class SalonBookingPage extends StatefulWidget {
  final List<SalonService> services;
  final bool isHomeVisitDefault;

  const SalonBookingPage({
    super.key,
    required this.services,
    required this.isHomeVisitDefault, required SalonService service, required String serviceName,
  });

  @override
  State<SalonBookingPage> createState() => _SalonBookingPageState();
}

class _SalonBookingPageState extends State<SalonBookingPage> {

  late bool isHomeVisit;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final instructionController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  final String salonName = "Beauty Glow Salon";
  final String salonAddress = "45, MG Road, Pune, Maharashtra";

  @override
  void initState() {
    super.initState();
    isHomeVisit = widget.isHomeVisitDefault;
  }

  /// ✅ TOTAL PRICE
  int get totalPrice {
    return widget.services.fold(
      0,
      (sum, item) => sum + (item.finalPrice),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔹 HOME / SALON TOGGLE
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Salon Appointment"),
                  selected: !isHomeVisit,
                  onSelected: (_) => setState(() => isHomeVisit = false),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Home Visit"),
                  selected: isHomeVisit,
                  onSelected: (_) => setState(() => isHomeVisit = true),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔥 SERVICES LIST
            const Text(
              "Selected Services",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            ...widget.services.map((service) => ListTile(
                  title: Text(service.name),
                  trailing: Text(
                    "₹${service.finalPrice}",
                  ),
                )),

            const SizedBox(height: 10),

            _readOnlyField("Salon Name", salonName),

            if (!isHomeVisit)
              _readOnlyField("Salon Address", salonAddress),

            const SizedBox(height: 15),

            /// 📅 DATE
            ListTile(
              title: Text(selectedDate == null
                  ? "Select Date"
                  : DateFormat('dd MMM yyyy').format(selectedDate!)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (date != null) setState(() => selectedDate = date);
              },
            ),

            /// ⏰ TIME
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
                if (time != null) setState(() => selectedTime = time);
              },
            ),

            const SizedBox(height: 15),

            /// 👤 NAME
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),

            /// 📱 PHONE
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone Number"),
              keyboardType: TextInputType.phone,
            ),

            /// 🏠 ADDRESS (ONLY FOR HOME VISIT)
            if (isHomeVisit) ...[
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Address"),
              ),
              TextField(
                controller: instructionController,
                decoration: const InputDecoration(
                    labelText: "Special Instructions"),
              ),
            ],

            const SizedBox(height: 20),

            /// 💰 TOTAL
            Text(
              "Total Price: ₹$totalPrice",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            /// ✅ CONFIRM BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmBooking,
                child: Text(
                  isHomeVisit
                      ? "Confirm Booking"
                      : "Confirm Appointment",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: value,
      ),
    );
  }

  /// ✅ VALIDATION + NAVIGATION
  void _confirmBooking() {

    if (selectedDate == null || selectedTime == null) {
      _showError("Please select date & time");
      return;
    }

    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty) {
      _showError("Please enter name & phone number");
      return;
    }

    if (isHomeVisit && addressController.text.isEmpty) {
      _showError("Please enter address");
      return;
    }

    String bookingId =
        "SLN${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingSuccessPage(
          services: widget.services,
          bookingId: bookingId,
          date: selectedDate!,
          time: selectedTime!,
          isHomeVisit: isHomeVisit,
          address: addressController.text,
        ),
      ),
    );
  }

  /// 🔥 ERROR SNACKBAR
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}