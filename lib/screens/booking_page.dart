import 'dart:math';
import 'package:flutter/material.dart';
import 'package:callme/screens/cart.dart';
import 'package:callme/screens/map_picker_page.dart';
import 'package:callme/data/orders_data.dart';
import 'package:callme/models/order_model.dart';
import 'package:callme/models/service_product.dart';

class BookingPage extends StatefulWidget {
  final String serviceName;
  final ServiceProduct product;

  const BookingPage({
    super.key,
    required this.serviceName,
    required this.product,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  double get totalAmount => Cart.items.fold(0, (sum, item) => sum + item.price);

  @override
  void initState() {
    super.initState();
    // Automatically add the selected product to Cart if not already added
    if (!Cart.items.contains(widget.product)) {
      Cart.items.add(widget.product);
    }
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
        elevation: 1,
      ),
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _serviceSummaryCard(),
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
            const Text(
              'Service Address',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
            const Text(
              'Additional Notes (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _textField(
              controller: noteController,
              hint: 'Any instructions for service provider',
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmBooking,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Confirm Booking',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected Services',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...Cart.items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.name),
              trailing: Text("₹${item.price}"),
            ),
          ),
          const Divider(),
          Text(
            'Total Amount: ₹${totalAmount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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

  void _confirmBooking() {
    if (selectedDate == null ||
        selectedTime == null ||
        addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required details')),
      );
      return;
    }

    final order = OrderModel(
      id: Random().nextInt(999999).toString(),
      services: Cart.items.map((e) => e.name).toList(),
      date: selectedDate!,
      time: selectedTime!.format(context),
      address: addressController.text,
      note: noteController.text,
      status: 'Ongoing',
      totalAmount: totalAmount,
    );

    OrdersData.orders.add(order);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking Confirmed')),
    );
    Cart.items.clear();
    Navigator.pop(context);
  }
}
