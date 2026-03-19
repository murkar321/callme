import 'dart:math';
import 'package:callme/screens/upi_payment.dart';
import 'package:flutter/material.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/models/service_product.dart';
import 'package:callme/screens/map_picker_page.dart';
import 'package:callme/data/orders_data.dart';
import 'package:callme/models/order_model.dart';

class BookingPage extends StatefulWidget {
  final String serviceName;

  /// ✅ UNIVERSAL INPUTS
  final ServiceProduct? product;
  final int? adults;
  final int? children;

  const BookingPage({
    super.key,
    required this.serviceName,
    this.product,
    this.adults,
    this.children,
    required Map<ServiceProduct, int> cartItems,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  /// 🔥 MODE DETECTION
  bool get isCartFlow => Cart.quantities.isNotEmpty;
  bool get isSingleService => widget.product != null && !isCartFlow;
  bool get isResort => widget.adults != null;

  /// ✅ TOTAL AMOUNT (SMART)
  double get totalAmount {
    if (isCartFlow) {
      double total = 0;
      Cart.quantities.forEach((product, qty) {
        total += product.calculatedFinalPrice * qty;
      });
      return total;
    }

    if (isSingleService) {
      return widget.product!.calculatedFinalPrice.toDouble();
    }

    return 0;
  }

  @override
  void dispose() {
    addressController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceName),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _serviceSummaryCard(),

            const SizedBox(height: 20),

            /// ✅ SHOW GUESTS ONLY FOR RESORT
            if (isResort) _guestCard(),

            const SizedBox(height: 20),

            const Text(
              'Select Date & Time',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _selectTile(
                    icon: Icons.calendar_today,
                    title: selectedDate == null
                        ? 'Select Date'
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _selectTile(
                    icon: Icons.access_time,
                    title: selectedTime == null
                        ? 'Select Time'
                        : selectedTime!.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text('Service Address',
                style: TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 8),

            InkWell(
              onTap: () async {
                final address = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapPickerPage()),
                );
                if (address != null) {
                  setState(() => addressController.text = address);
                }
              },
              child: AbsorbPointer(
                child: _textField(
                  controller: addressController,
                  hint: 'Select address from map',
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text('Additional Notes (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 8),

            _textField(
              controller: noteController,
              hint: 'Any instructions',
              maxLines: 3,
            ),

            const SizedBox(height: 30),

            /// ✅ PAYMENT FLOW BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startPaymentFlow,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Proceed to Payment',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ SERVICE SUMMARY (SMART SWITCH)
  Widget _serviceSummaryCard() {
    if (isCartFlow) {
      return _cartSummary();
    } else if (isSingleService) {
      return _singleServiceSummary();
    } else {
      return const SizedBox();
    }
  }

  /// 🔹 CART UI
  Widget _cartSummary() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Selected Services',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...Cart.quantities.entries.map((entry) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${entry.key.name} x${entry.value}'),
              trailing:
                  Text('₹${entry.key.calculatedFinalPrice * entry.value}'),
            );
          }),
          const Divider(),
          Text('Total: ₹${totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// 🔹 SINGLE SERVICE / RESORT UI
  Widget _singleServiceSummary() {
    final p = widget.product;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p?.name ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('₹${p?.calculatedFinalPrice}',
              style: const TextStyle(color: Colors.green)),
        ],
      ),
    );
  }

  /// 🔹 GUEST CARD
  Widget _guestCard() {
    return _card(
      child: Row(
        children: [
          const Icon(Icons.people),
          const SizedBox(width: 10),
          Text("${widget.adults} Adults, ${widget.children} Children"),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: child,
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
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
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 10),
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
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
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

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: DateTime.now(),
    );
    if (date != null) setState(() => selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) setState(() => selectedTime = time);
  }

  /// 🚀 PAYMENT FLOW
  void _startPaymentFlow() async {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select date & time')),
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
      _confirmBooking();
    }
  }

  /// ✅ FINAL BOOKING
  void _confirmBooking() {
    final finalAddress = addressController.text.isEmpty
        ? "Demo Address"
        : addressController.text;

    final order = OrderModel(
      id: Random().nextInt(999999).toString(),
      services: isCartFlow
          ? Cart.quantities.entries
              .map((e) => '${e.key.name} x${e.value}')
              .toList()
          : [widget.product?.name ?? widget.serviceName],
      date: selectedDate!,
      time: selectedTime!.format(context),
      address: finalAddress,
      note: noteController.text,
      status: 'Ongoing',
      totalAmount: totalAmount,
    );

    OrdersData.orders.add(order);
    Cart.quantities.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking Confirmed')),
    );

    Navigator.pop(context);
  }
}
