import 'package:callme/data/hotel_data.dart';
import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../models/service_product.dart';

class HotelBookingPage extends StatefulWidget {
  final List<ServiceProduct> products;

  const HotelBookingPage({
    super.key,
    required this.products,
    required HotelRoom hotel,
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

  /// 🔥 TOTAL PRICE
  int get totalPrice {
    int total = 0;
    for (var product in widget.products) {
      int qty = Cart.quantities[product] ?? 0;
      total += (product.finalPrice ?? product.price) * qty;
    }
    return total;
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

            /// 🔷 SERVICE DETAILS
            const Text(
              "Room Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ...widget.products.map((product) {
              int qty = Cart.quantities[product] ?? 0;
              if (qty == 0) return const SizedBox();

              return Card(
                child: ListTile(
                  leading: Image.asset(product.imagePath, width: 50),
                  title: Text(product.name),
                  subtitle: Text("Qty: $qty"),
                  trailing: Text(
                    "₹${(product.finalPrice ?? product.price) * qty}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList(),

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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Booking Confirmed!"),
                          ),
                        );
                      },
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
}
