
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:callme/models/cart.dart';
import 'package:callme/models/service_product.dart';
import 'package:callme/screens/map_picker_page.dart';
import 'package:callme/screens/upi_payment.dart';

class BookingPage extends StatefulWidget {
  final String serviceName;

  /// SINGLE SERVICE
  final ServiceProduct? product;

  /// RESORT SUPPORT
  final int? adults;
  final int? children;

  /// CART FLOW
  final List<CartItem>? cart;

  const BookingPage({
    super.key,
    required this.serviceName,
    this.product,
    this.adults,
    this.children,
    this.cart, Object? products,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  /// ================= FLOW DETECTION =================
  List<CartItem> get cartItems =>
      widget.cart ?? Cart.getItems(widget.serviceName);

  bool get isCartFlow => cartItems.isNotEmpty;
  bool get isSingleService => widget.product != null && cartItems.isEmpty;
  bool get isResort => widget.adults != null;

  /// ================= TOTAL =================
  double get totalAmount {
    if (isCartFlow) {
      return Cart.getTotal(widget.serviceName).toDouble();
    }

    if (isSingleService) {
      return widget.product!.calculatedFinalPrice.toDouble();
    }

    return 0;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    noteController.dispose();
    super.dispose();
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.serviceName)),
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _serviceSummaryCard(),
            const SizedBox(height: 20),

            if (isResort) _guestCard(),
            const SizedBox(height: 20),

            _textField(controller: nameController, hint: "Full Name"),
            const SizedBox(height: 16),

            _textField(
              controller: emailController,
              hint: "Email",
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            _textField(
              controller: phoneController,
              hint: "Phone Number",
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            /// DATE & TIME
            Row(
              children: [
                Expanded(
                  child: _selectTile(
                    icon: Icons.calendar_today,
                    title: selectedDate == null
                        ? "Select Date"
                        : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _selectTile(
                    icon: Icons.access_time,
                    title: selectedTime == null
                        ? "Select Time"
                        : selectedTime!.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ADDRESS
            InkWell(
              onTap: () async {
                final address = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapPickerPage()),
                );

                if (address != null) {
                  setState(() {
                    addressController.text = address;
                  });
                }
              },
              child: AbsorbPointer(
                child: _textField(
                  controller: addressController,
                  hint: "Select address from map",
                ),
              ),
            ),

            const SizedBox(height: 16),

            _textField(
              controller: noteController,
              hint: "Additional Notes",
              maxLines: 3,
            ),

            const SizedBox(height: 20),

            /// TOTAL
            _card(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total"),
                  Text(
                    "₹${totalAmount.toStringAsFixed(0)}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// PAYMENT
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startPaymentFlow,
                child: const Text("Proceed to Payment"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= SUMMARY =================
  Widget _serviceSummaryCard() {
    if (isCartFlow) return _cartSummary();
    if (isSingleService) return _singleSummary();
    return const SizedBox();
  }

  Widget _cartSummary() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Selected Services",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...cartItems.map(
            (item) => ListTile(
              title: Text("${item.name} x${item.quantity}"),
              trailing: Text("₹${item.price * item.quantity}"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _singleSummary() {
    final p = widget.product!;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.name),
          Text("₹${p.calculatedFinalPrice}"),
        ],
      ),
    );
  }

  Widget _guestCard() {
    return _card(
      child: Text("${widget.adults} Adults, ${widget.children} Children"),
    );
  }

  /// ================= COMMON UI =================
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14)),
      child: child,
    );
  }

  Widget _selectTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// ================= DATE TIME =================
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());

    if (time != null) {
      setState(() => selectedTime = time);
    }
  }

  /// ================= PAYMENT =================
  void _startPaymentFlow() async {
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        addressController.text.isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all details")),
      );
      return;
    }

    final success = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpiPaymentScreen(amount: totalAmount),
      ),
    );

    if (success == true) {
      _saveToFirestore();
    }
  }

  /// ================= FIRESTORE =================
  Future<void> _saveToFirestore() async {
    try {
      List<String> servicesList;

      if (isCartFlow) {
        servicesList =
            cartItems.map((e) => "${e.name} x${e.quantity}").toList();
      } else {
        servicesList = [widget.product?.name ?? widget.serviceName];
      }

      await FirebaseFirestore.instance.collection("orders").add({
        "services": servicesList,
        "date": Timestamp.fromDate(selectedDate!),
        "time": selectedTime!.format(context),
        "address": addressController.text,
        "note": noteController.text,
        "status": "pending",
        "totalAmount": totalAmount,
        "userName": nameController.text,
        "phone": phoneController.text,
        "serviceType": widget.serviceName,
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (isCartFlow) {
        Cart.clear(widget.serviceName);
      }

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