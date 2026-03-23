import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../models/order_model.dart';
import '../data/orders_data.dart';

class CivilBookPage extends StatefulWidget {
  const CivilBookPage({super.key}); // NO required service

  @override
  State<CivilBookPage> createState() => _CivilBookPageState();
}

class _CivilBookPageState extends State<CivilBookPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final pincodeController = TextEditingController();
  final budgetFromController = TextEditingController();
  final budgetToController = TextEditingController();
  final notesController = TextEditingController();

  String propertyType = "Residential";
  String timeSlot = "Morning";
  DateTime? selectedDate;

  // Pick Date
  Future pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  // Submit Booking
  void submitBooking() {
    if (!_formKey.currentState!.validate()) return;

    final civilItems = Cart.getByService("Civil Contract Services");
    if (civilItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add Civil services before booking")),
      );
      return;
    }

    final serviceNames = civilItems.map((e) => e.name).toList();
    final totalAmount = Cart.getTotal("Civil Contract Services").toDouble();

    final order = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      services: serviceNames,
      date: selectedDate ?? DateTime.now(),
      time: timeSlot,
      address: "${addressController.text}, ${cityController.text}, ${pincodeController.text}",
      note: notesController.text,
      status: "Pending",
      totalAmount: totalAmount,
    );

    OrdersData.orders.add(order);
    Cart.clear("Civil Contract Services"); // Keep cart universal but clear this service

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Booking Confirmed"),
        content: const Text("Civil Contract Inspection Booked Successfully"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to services page
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );

    setState(() {}); // refresh page
  }

  @override
  Widget build(BuildContext context) {
    final civilItems = Cart.getByService("Civil Contract Services");
    final total = Cart.getTotal("Civil Contract Services");

    return Scaffold(
      appBar: AppBar(title: const Text("Civil Contract Booking"), backgroundColor: Colors.blue),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected Services
              const Text("Selected Civil Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (civilItems.isEmpty) const Text("No services added yet.", style: TextStyle(color: Colors.grey)),
              ...civilItems.map(
                (item) => ListTile(
                  leading: const Icon(Icons.build),
                  title: Text(item.name),
                  trailing: Text("₹${item.price}"),
                ),
              ),
              const Divider(),
              Text("Total: ₹$total", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 20),

              // Customer Details
              const Text("Customer Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Enter name" : null),
              const SizedBox(height: 10),
              TextFormField(controller: mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Mobile Number", border: OutlineInputBorder()), validator: (v) => v!.length < 10 ? "Enter valid mobile" : null),
              const SizedBox(height: 10),
              TextFormField(controller: emailController, decoration: const InputDecoration(labelText: "Email ID", border: OutlineInputBorder())),
              const SizedBox(height: 20),

              // Location
              const Text("Location Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(controller: addressController, decoration: const InputDecoration(labelText: "Address", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextFormField(controller: cityController, decoration: const InputDecoration(labelText: "City", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextFormField(controller: pincodeController, decoration: const InputDecoration(labelText: "Pincode", border: OutlineInputBorder())),
              const SizedBox(height: 20),

              // Property Type
              const Text("Property Type", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Radio(value: "Residential", groupValue: propertyType, onChanged: (val) => setState(() => propertyType = val!)),
                  const Text("Residential"),
                  Radio(value: "Commercial", groupValue: propertyType, onChanged: (val) => setState(() => propertyType = val!)),
                  const Text("Commercial"),
                ],
              ),
              const SizedBox(height: 20),

              // Date & Time
              const Text("Inspection Date & Time", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: pickDate,
                child: Text(selectedDate == null ? "Select Inspection Date" : selectedDate!.toString().split(" ")[0]),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField(
                value: timeSlot,
                items: const [
                  DropdownMenuItem(value: "Morning", child: Text("Morning")),
                  DropdownMenuItem(value: "Afternoon", child: Text("Afternoon")),
                  DropdownMenuItem(value: "Evening", child: Text("Evening")),
                ],
                onChanged: (val) => setState(() => timeSlot = val!),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),

              // Budget
              const Text("Budget Preference", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: budgetFromController, decoration: const InputDecoration(labelText: "From", border: OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: budgetToController, decoration: const InputDecoration(labelText: "To", border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 20),

              // Notes
              const Text("Additional Requirements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(controller: notesController, maxLines: 4, decoration: const InputDecoration(labelText: "Special Request / Notes", border: OutlineInputBorder())),
              const SizedBox(height: 30),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: submitBooking,
                  child: const Text("Book Inspection", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}