import 'package:callme/data/hotel_data.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart.dart';
import '../models/service_product.dart';

class HotelBookingPage extends StatefulWidget {
  final List<ServiceProduct> products;

  const HotelBookingPage({
    super.key,
    required this.products, required HotelRoom hotel,
  });

  @override
  State<HotelBookingPage> createState() => _HotelBookingPageState();
}

class _HotelBookingPageState extends State<HotelBookingPage> {
  /// 🔷 CONTROLLERS
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final pincodeCtrl = TextEditingController();
  final messageCtrl = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  /// 🔥 GET CART ITEMS (HOTEL)
  List<CartItem> get cartItems => Cart.getItems("Hotel");

  /// 🔥 TOTAL PRICE
  int get totalPrice {
    return cartItems.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  /// 📅 PICK DATE
  Future pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (date != null) setState(() => selectedDate = date);
  }

  /// ⏰ PICK TIME
  Future pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) setState(() => selectedTime = time);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    pincodeCtrl.dispose();
    messageCtrl.dispose();
    super.dispose();
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hotel Booking"),
        backgroundColor: Colors.purple.shade200,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔷 CUSTOMER DETAILS
            const Text(
              "Customer Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Mobile Number"),
            ),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "Email ID"),
            ),

            const SizedBox(height: 20),

            /// 🔷 ROOM DETAILS (FROM CART)
            const Text(
              "Room Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ...cartItems.map((item) {
              return Card(
                child: ListTile(
                  leading: item.image != null
                      ? Image.asset(item.image!, width: 50)
                      : null,
                  title: Text(item.name),
                  subtitle: Text("Qty: ${item.quantity}"),
                  trailing: Text(
                    "₹${item.price * item.quantity}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            /// 🔷 ADDRESS
            const Text(
              "Address Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: "Address"),
            ),
            TextField(
              controller: cityCtrl,
              decoration: const InputDecoration(labelText: "City"),
            ),
            TextField(
              controller: pincodeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Pincode"),
            ),

            const SizedBox(height: 20),

            /// 🔷 DATE & TIME
            const Text(
              "Check-in Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: pickDate,
                    child: Text(
                      selectedDate == null
                          ? "Select Date"
                          : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: pickTime,
                    child: Text(
                      selectedTime == null
                          ? "Select Time"
                          : selectedTime!.format(context),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔷 SPECIAL REQUEST
            const Text(
              "Special Request",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            TextField(
              controller: messageCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Any extra instructions",
              ),
            ),

            const SizedBox(height: 30),

            /// 🔥 TOTAL + BUTTON
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    "Total: ₹$totalPrice",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 175, 153, 179),
                      ),
                      child: const Text("Confirm Booking"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= FIRESTORE =================
  Future<void> _confirmBooking() async {
    if (nameCtrl.text.isEmpty ||
        phoneCtrl.text.isEmpty ||
        addressCtrl.text.isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all details")),
      );
      return;
    }

    try {
      final services = cartItems
          .map((e) => "${e.name} x${e.quantity}")
          .toList();

      await FirebaseFirestore.instance.collection("orders").add({
        "services": services,
        "date": Timestamp.fromDate(selectedDate!),
        "time": selectedTime!.format(context),
        "address": "${addressCtrl.text}, ${cityCtrl.text}",
        "note": messageCtrl.text,
        "status": "pending",
        "totalAmount": totalPrice,
        "userName": nameCtrl.text,
        "phone": phoneCtrl.text,
        "email": emailCtrl.text,
        "serviceType": "Hotel", // 🔥 IMPORTANT
        "createdAt": FieldValue.serverTimestamp(),
      });

      Cart.clear("Hotel");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking Confirmed")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}