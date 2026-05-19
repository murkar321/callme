import 'package:callme/data/service_product.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/payment/payment_page.dart';
import 'package:callme/provider/order_service.dart';
import 'package:callme/screens/bottom_nav_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingPage extends StatefulWidget {
  final String serviceName;
  final ServiceProduct? product;
  final List<CartItem>? cart;

  const BookingPage({
    super.key,
    required this.serviceName,
    this.product,
    this.cart,
    required List<dynamic> products,
  });

  @override
  State<BookingPage> createState() =>
      _BookingPageState();
}

class _BookingPageState
    extends State<BookingPage> {
  final name = TextEditingController();

  final email =
      TextEditingController();

  final phone =
      TextEditingController();

  final address =
      TextEditingController();

  final note =
      TextEditingController();

  DateTime? date;

  TimeOfDay? time;

  bool isSuccess = false;

  bool isLoading = false;

  String bookingId = "";

  /// ================= CART =================

  List<CartItem> get cartItems =>
      widget.cart ??
      Cart.getItems(
        widget.serviceName,
      );

  bool get isCart =>
      cartItems.isNotEmpty;

  bool get isSingle =>
      widget.product != null &&
      cartItems.isEmpty;

  /// ================= TOTAL =================

  double get total {
    if (isCart) {
      double sum = 0;

      for (var item in cartItems) {
        sum +=
            item.price *
            item.quantity;
      }

      return sum;
    }

    if (isSingle) {
      return widget.product!
          .calculatedFinalPrice
          .toDouble();
    }

    return 0;
  }

  /// ================= NORMALIZE =================

  String normalize(String s) {
    return s.trim().toLowerCase();
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
      backgroundColor:
          const Color(0xFFF5F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            Colors.white,
        foregroundColor:
            Colors.black,

        title: Text(
          widget.serviceName,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: isSuccess
          ? _successView()
          : _bookingForm(),
    );
  }

  /// =========================================================
  /// BOOKING FORM
  /// =========================================================

  Widget _bookingForm() {
    return SafeArea(
      child: ListView(
        padding:
            const EdgeInsets.all(16),

        children: [
          _sectionCard(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                const Text(
                  "Customer Details",

                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                    height: 20),

                _field(
                  name,
                  "Full Name *",
                  Icons.person_outline,
                ),

                _field(
                  phone,
                  "Phone Number *",
                  Icons.phone_outlined,
                  keyboard:
                      TextInputType.phone,
                ),

                _field(
                  email,
                  "Email Address",
                  Icons.email_outlined,
                  keyboard:
                      TextInputType
                          .emailAddress,
                ),

                _field(
                  address,
                  "Full Address *",
                  Icons.location_on_outlined,
                  maxLines: 3,
                ),

                _field(
                  note,
                  "Additional Note",
                  Icons.note_alt_outlined,
                  maxLines: 3,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _sectionCard(
            child: Column(
              children: [
                _dateTile(),

                const Divider(),

                _timeTile(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _serviceSummary(),

          const SizedBox(height: 24),

          SizedBox(
            height: 56,

            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : _validateAndPay,

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.deepPurple,

                foregroundColor:
                    Colors.white,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
              ),

              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,

                      child:
                          CircularProgressIndicator(
                        color:
                            Colors.white,
                        strokeWidth:
                            2,
                      ),
                    )
                  : Text(
                      "Proceed to Payment • ₹${total.toStringAsFixed(0)}",

                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// =========================================================
  /// SUCCESS VIEW
  /// =========================================================

  Widget _successView() {
    return SafeArea(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          children: [
            const SizedBox(height: 30),

            Container(
              padding:
                  const EdgeInsets.all(
                24,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Colors.green.shade50,

                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 90,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Booking Confirmed!",

              style: TextStyle(
                fontSize: 26,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Booking ID: $bookingId",

              style: TextStyle(
                color:
                    Colors.grey.shade700,
                fontWeight:
                    FontWeight.w500,
              ),
            ),

            const SizedBox(height: 24),

            _sectionCard(
              child: Column(
                children: [
                  _row(
                    "Name",
                    name.text,
                  ),

                  _row(
                    "Phone",
                    phone.text,
                  ),

                  _row(
                    "Date",
                    DateFormat(
                      'dd MMM yyyy',
                    ).format(date!),
                  ),

                  _row(
                    "Time",
                    time!.format(context),
                  ),

                  _row(
                    "Address",
                    address.text,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _sectionCard(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  const Text(
                    "Booked Services",

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                      height: 12),

                  ..._servicesList(),

                  const Divider(
                    height: 26,
                  ),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,

                    children: [
                      const Text(
                        "Total Amount",

                        style: TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),

                      Text(
                        "₹${total.toStringAsFixed(0)}",

                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,

                          color: Colors
                              .deepPurple,

                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// =========================================================
  /// SERVICE SUMMARY
  /// =========================================================

  Widget _serviceSummary() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            "Booking Summary",

            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          ..._servicesList(),

          const Divider(height: 28),

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            children: [
              const Text(
                "Total",

                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              Text(
                "₹${total.toStringAsFixed(0)}",

                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 20,
                  color:
                      Colors.deepPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// =========================================================
  /// SERVICES LIST
  /// =========================================================

  List<Widget> _servicesList() {
    if (isCart) {
      return cartItems.map((e) {
        return Padding(
          padding:
              const EdgeInsets.only(
            bottom: 10,
          ),

          child: Container(
            padding:
                const EdgeInsets.all(
              14,
            ),

            decoration:
                BoxDecoration(
              color:
                  Colors.grey.shade100,

              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),

            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e.name,

                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                Text(
                  "x${e.quantity}",
                ),
              ],
            ),
          ),
        );
      }).toList();
    }

    return [
      Container(
        padding:
            const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color:
              Colors.grey.shade100,

          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),

        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.product?.name ??
                    "",

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            Text(
              "₹${total.toStringAsFixed(0)}",
            ),
          ],
        ),
      ),
    ];
  }

  /// =========================================================
  /// DATE TILE
  /// =========================================================

  Widget _dateTile() {
    return ListTile(
      contentPadding:
          EdgeInsets.zero,

      leading: Container(
        padding:
            const EdgeInsets.all(10),

        decoration: BoxDecoration(
          color:
              Colors.deepPurple
                  .withOpacity(0.1),

          borderRadius:
              BorderRadius.circular(
            12,
          ),
        ),

        child: const Icon(
          Icons.calendar_today,
          color: Colors.deepPurple,
        ),
      ),

      title: const Text(
        "Booking Date",

        style: TextStyle(
          fontWeight:
              FontWeight.bold,
        ),
      ),

      subtitle: Text(
        date == null
            ? "Select preferred date"
            : DateFormat(
                'dd MMM yyyy',
              ).format(date!),
      ),

      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
      ),

      onTap: _pickDate,
    );
  }

  /// =========================================================
  /// TIME TILE
  /// =========================================================

  Widget _timeTile() {
    return ListTile(
      contentPadding:
          EdgeInsets.zero,

      leading: Container(
        padding:
            const EdgeInsets.all(10),

        decoration: BoxDecoration(
          color:
              Colors.orange
                  .withOpacity(0.1),

          borderRadius:
              BorderRadius.circular(
            12,
          ),
        ),

        child: const Icon(
          Icons.access_time,
          color: Colors.orange,
        ),
      ),

      title: const Text(
        "Booking Time",

        style: TextStyle(
          fontWeight:
              FontWeight.bold,
        ),
      ),

      subtitle: Text(
        time == null
            ? "Select preferred time"
            : time!.format(context),
      ),

      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
      ),

      onTap: _pickTime,
    );
  }

  /// =========================================================
  /// COMMON CARD
  /// =========================================================

  Widget _sectionCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          22,
        ),

        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(
              0,
              6,
            ),
            color: Colors.black
                .withOpacity(0.05),
          ),
        ],
      ),

      child: child,
    );
  }

  /// =========================================================
  /// FIELD
  /// =========================================================

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    TextInputType keyboard =
        TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 16,
      ),

      child: TextField(
        controller: c,
        keyboardType: keyboard,
        maxLines: maxLines,

        decoration: InputDecoration(
          hintText: hint,

          prefixIcon: Icon(
            icon,
            color:
                Colors.deepPurple,
          ),

          filled: true,

          fillColor:
              const Color(
            0xFFF7F8FC,
          ),

          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),

            borderSide:
                BorderSide.none,
          ),

          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),

            borderSide:
                BorderSide.none,
          ),

          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),

            borderSide:
                const BorderSide(
              color:
                  Colors.deepPurple,
            ),
          ),
        ),
      ),
    );
  }

  /// =========================================================
  /// INFO ROW
  /// =========================================================

  Widget _row(
    String key,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          SizedBox(
            width: 90,

            child: Text(
              key,

              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const Text(":  "),

          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// =========================================================
  /// DATE PICKER
  /// =========================================================

  void _pickDate() async {
    final d =
        await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (d != null && mounted) {
      setState(() {
        date = d;
      });
    }
  }

  /// =========================================================
  /// TIME PICKER
  /// =========================================================

  void _pickTime() async {
    final t =
        await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay.now(),
    );

    if (t != null && mounted) {
      setState(() {
        time = t;
      });
    }
  }

  /// =========================================================
  /// VALIDATE
  /// =========================================================

  void _validateAndPay() {
    if (name.text.trim().isEmpty ||
        phone.text.trim().isEmpty ||
        address.text.trim().isEmpty ||
        date == null ||
        time == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Fill all required fields",
          ),
        ),
      );

      return;
    }

    _pay();
  }

  /// =========================================================
  /// PAYMENT
  /// =========================================================

  void _pay() async {
    final result =
        await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) => PaymentPage(
          serviceName:
              widget.serviceName,

          amount: total.toInt(),
        ),
      ),
    );

    if (!mounted) return;

    if (result == true ||
        result == 'offline') {
      await _save();
    }
  }

  /// =========================================================
  /// SAVE ORDER
  /// =========================================================

  Future<void> _save() async {
    try {
      if (!mounted) return;

      setState(() {
        isLoading = true;
      });

      final user = FirebaseAuth
          .instance.currentUser;

      if (user == null) {
        throw Exception(
          "User not logged in",
        );
      }

      final services = isCart
          ? cartItems
              .map(
                (e) =>
                    "${e.name} x${e.quantity}",
              )
              .toList()
          : [
              widget.product?.name ??
                  widget.serviceName,
            ];

      final docRef =
          await OrderService.placeOrder(
        serviceType:
            normalize(
          widget.serviceName,
        ),

        services: services,

        userId: user.uid,

        userName: name.text.trim(),

        phone:
            phone.text.trim(),

        email:
            email.text.trim(),

        address:
            address.text.trim(),

        note: note.text.trim(),

        date: date!,

        time: time!.format(
          context,
        ),

        totalAmount: total,

        createdBy: user.uid,

        createdByRole: "user",

        providerId: "",

        providerUserId: "",

        providerName: "",

        isEnquiry: false,
      );

      /// CLEAR CART
      if (isCart) {
        Cart.clear(
          widget.serviceName,
        );
      }

      if (!mounted) return;

      setState(() {
        bookingId = docRef.id;

        isSuccess = true;

        isLoading = false;
      });

      await Future.delayed(
        const Duration(
          seconds: 2,
        ),
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,

        MaterialPageRoute(
          builder: (_) =>
              BottomNavPage(
            userPhone:
                user.phoneNumber ??
                    "",

            userEmail:
                user.email ?? "",
          ),
        ),

        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text("Error: $e"),
        ),
      );
    }
  }
}