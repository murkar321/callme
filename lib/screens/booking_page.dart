import 'dart:math';
import 'package:flutter/material.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/models/service_product.dart';
import 'package:callme/screens/map_picker_page.dart';
import 'package:callme/screens/upi_payment.dart';
import 'package:callme/data/orders_data.dart';
import 'package:callme/models/order_model.dart';

class BookingPage extends StatefulWidget {
  final String serviceName;

  /// OPTIONAL (single service)
  final ServiceProduct? product;
  final int? adults;
  final int? children;

  const BookingPage({
    super.key,
    required this.serviceName,
    this.product,
    this.adults,
    this.children, Object? service, required products,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  /// ✅ NEW CART FLOW
  List<CartItem> get cartItems => Cart.getByService(widget.serviceName);

  bool get isCartFlow => cartItems.isNotEmpty;

  bool get isSingleService => widget.product != null && !isCartFlow;

  bool get isResort => widget.adults != null;

  /// ✅ TOTAL
  double get totalAmount {
    if (isCartFlow) {
      return Cart.totalPrice(widget.serviceName).toDouble();
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

            /// DATE & TIME
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

            /// ADDRESS
            InkWell(
              onTap: () async {
                final address = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MapPickerPage(),
                  ),
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

            /// NOTES
            _textField(
              controller: noteController,
              hint: 'Additional Notes',
              maxLines: 3,
            ),

            const SizedBox(height: 30),

            /// PAYMENT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startPaymentFlow,
                child: const Text('Proceed to Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ SUMMARY SWITCH
  Widget _serviceSummaryCard() {
    if (isCartFlow) return _cartSummary();
    if (isSingleService) return _singleSummary();
    return const SizedBox();
  }

  /// 🔹 CART SUMMARY (FIXED)
  Widget _cartSummary() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Selected Services'),
          const SizedBox(height: 8),
          ...cartItems.map((item) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${item.name} x${item.quantity}'),
              trailing: Text(
                '₹${item.price * item.quantity}',
              ),
            );
          }),
          const Divider(),
          Text(
            'Total: ₹${totalAmount.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.green),
          ),
        ],
      ),
    );
  }

  /// 🔹 SINGLE
  Widget _singleSummary() {
    final p = widget.product!;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.name),
          const SizedBox(height: 6),
          Text('₹${p.calculatedFinalPrice}'),
        ],
      ),
    );
  }

  /// 🔹 RESORT
  Widget _guestCard() {
    return _card(
      child: Text("${widget.adults} Adults, ${widget.children} Children"),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
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
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon),
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

  void _startPaymentFlow() async {
    if (selectedDate == null || selectedTime == null) return;

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

  void _confirmBooking() {
    final order = OrderModel(
      id: Random().nextInt(999999).toString(),
      services: isCartFlow
          ? cartItems.map((item) => "${item.name} x${item.quantity}").toList()
          : [widget.product?.name ?? widget.serviceName],
      date: selectedDate!,
      time: selectedTime!.format(context),
      address: addressController.text,
      note: noteController.text,
      status: 'Ongoing',
      totalAmount: totalAmount,
    );

    OrdersData.orders.add(order);

    /// ✅ CLEAR ONLY CURRENT SERVICE
    Cart.clear(widget.serviceName);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking Confirmed')),
    );

    Navigator.pop(context);
  }
}
