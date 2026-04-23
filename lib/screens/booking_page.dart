import 'package:flutter/material.dart';
import 'package:callme/provider/order_service.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/models/service_product.dart';
import 'package:callme/screens/map_picker_page.dart';
import 'package:callme/screens/upi_payment.dart';

class BookingPage extends StatefulWidget {
  final String serviceName;

  final ServiceProduct? product;
  final int? adults;
  final int? children;
  final List<CartItem>? cart;

  const BookingPage({
    super.key,
    required this.serviceName,
    this.product,
    this.adults,
    this.children,
    this.cart, required List<CartItem> products,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final note = TextEditingController();

  DateTime? date;
  TimeOfDay? time;

  /// ================= CART LOGIC (UNCHANGED) =================
  List<CartItem> get cartItems =>
      widget.cart ?? Cart.getItems(widget.serviceName);

  bool get isCart => cartItems.isNotEmpty;
  bool get isSingle => widget.product != null && cartItems.isEmpty;

  double get total {
    if (isCart) {
      return Cart.getTotal(widget.serviceName).toDouble();
    }

    if (isSingle) {
      return widget.product!.calculatedFinalPrice.toDouble();
    }

    return 0;
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    address.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.serviceName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            _field(name, "Full Name"),
            _field(email, "Email"),
            _field(phone, "Phone"),

            /// DATE
            ListTile(
              title: Text(
                date == null
                    ? "Select Date"
                    : "${date!.day}/${date!.month}/${date!.year}",
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),

            /// TIME
            ListTile(
              title: Text(
                time == null ? "Select Time" : time!.format(context),
              ),
              trailing: const Icon(Icons.access_time),
              onTap: _pickTime,
            ),

            /// ADDRESS (SAFE MAP HANDLING)
            InkWell(
              onTap: () async {
                try {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MapPickerPage(),
                    ),
                  );

                  if (result != null && result.toString().isNotEmpty) {
                    setState(() {
                      address.text = result;
                    });
                  }
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Map not available. Enter address manually.",
                      ),
                    ),
                  );
                }
              },
              child: _field(address, "Enter Address (Optional)"),
            ),

            _field(note, "Note"),

            const SizedBox(height: 20),

            Text(
              "Total: ₹$total",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _validateAndPay,
              child: const Text("Proceed to Payment"),
            )
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  void _pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (d != null) setState(() => date = d);
  }

  void _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (t != null) setState(() => time = t);
  }

  /// ================= VALIDATION =================
  void _validateAndPay() {
    if (name.text.isEmpty ||
        phone.text.isEmpty ||
        date == null ||
        time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all required details")),
      );
      return;
    }

    _pay();
  }

  /// ================= PAYMENT =================
  void _pay() async {
    final success = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpiPaymentScreen(amount: total),
      ),
    );

    if (success == true) {
      _save();
    }
  }

  /// ================= SAVE ORDER =================
  void _save() async {
    List<String> services = isCart
        ? cartItems.map((e) => "${e.name} x${e.quantity}").toList()
        : [widget.product?.name ?? widget.serviceName];

    /// 🔥 ONLY FOR RESORT
    int? adults = widget.serviceName.toLowerCase() == "resort"
        ? widget.adults
        : null;

    int? children = widget.serviceName.toLowerCase() == "resort"
        ? widget.children
        : null;

    await OrderService.placeOrder(
      serviceType: widget.serviceName,
      services: services,
      userName: name.text,
      phone: phone.text,
      email: email.text,
      address: address.text.isEmpty ? "Not Provided" : address.text,
      note: note.text,
      date: date!,
      time: time!.format(context),
      totalAmount: total,

      /// 🔥 ONLY RESORT DATA SAVED
      adults: adults,
      children: children,
    );

    if (isCart) {
      Cart.clear(widget.serviceName);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking Confirmed")),
    );

    Navigator.pop(context);
  }
}