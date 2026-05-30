import 'package:callme/data/service_product.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/payment/payment_page.dart';
import 'package:callme/provider/order_service.dart';
import 'package:callme/screens/bottom_nav_page.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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

  /// =========================================================
  /// CONTROLLERS
  /// =========================================================

  final nameController =
      TextEditingController();

  final phoneController =
      TextEditingController();

  final addressController =
      TextEditingController();

  final noteController =
      TextEditingController();

  DateTime? selectedDate;

  TimeOfDay? selectedTime;

  bool isLoading = false;

  bool isSuccess = false;

  bool isGettingLocation = false;

  String bookingId = "";

  /// =========================================================
  /// CART
  /// =========================================================

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

  /// =========================================================
  /// TOTAL
  /// =========================================================

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

  /// =========================================================
  /// DISPOSE
  /// =========================================================

  @override
  void dispose() {

    nameController.dispose();

    phoneController.dispose();

    addressController.dispose();

    noteController.dispose();

    super.dispose();
  }

  /// =========================================================
  /// BUILD
  /// =========================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xFFF5F7FC),

      /// BODY
      body: isSuccess
          ? _successView()
          : _mainView(),

      /// THIS MUST STAY INSIDE SCAFFOLD
      bottomNavigationBar:
          isSuccess
              ? null
              : _bottomBar(),
    );
  }

  /// =========================================================
  /// MAIN VIEW
  /// =========================================================

  Widget _mainView() {

    return SafeArea(

      child: Column(
        children: [

          _header(),

          Expanded(

            child: ListView(

              padding:
                  const EdgeInsets.all(
                20,
              ),

              children: [

                /// ── SUMMARY MOVED TO TOP ──
                _summaryCard(),

                const SizedBox(height: 20),

                _detailsCard(),

                const SizedBox(height: 20),

                _dateTimeSection(),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// =========================================================
  /// HEADER
  /// =========================================================

  Widget _header() {

    return Container(

      width: double.infinity,

      padding:
          const EdgeInsets.all(24),

      decoration:
          const BoxDecoration(

        gradient: LinearGradient(
          colors: [
            Color(0xFF6A5AE0),
            Color(0xFF8F7CFF),
          ],
        ),

        borderRadius:
            BorderRadius.vertical(
          bottom:
              Radius.circular(34),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },

            child: Container(

              padding:
                  const EdgeInsets.all(
                10,
              ),

              decoration:
                  BoxDecoration(
                color: Colors.white
                    .withOpacity(0.15),

                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),

              child: const Icon(
                Icons.arrow_back,
                color:
                    Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            "Book Service",

            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            widget.serviceName,

            style: TextStyle(
              color: Colors.white
                  .withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  /// =========================================================
  /// DETAILS CARD
  /// =========================================================

  Widget _detailsCard() {

    return _card(

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Text(
            "Customer Details",

            style: TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          _field(
            controller:
                nameController,
            hint:
                "Full Name",
            icon:
                Icons.person,
          ),

          const SizedBox(height: 16),

          _field(
            controller:
                phoneController,
            hint:
                "Mobile Number",
            icon:
                Icons.phone,
            keyboard:
                TextInputType.phone,
          ),

          const SizedBox(height: 16),

          _field(
            controller:
                addressController,
            hint:
                "Enter Full Address",
            icon:
                Icons.location_on,
            maxLines: 3,
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,

            child: ElevatedButton.icon(

              onPressed:
                  isGettingLocation
                      ? null
                      : _getCurrentLocation,

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.deepPurple,

                foregroundColor:
                    Colors.white,

                padding:
                    const EdgeInsets.symmetric(
                  vertical: 16,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
              ),

              icon: isGettingLocation
                  ? const SizedBox(
                      height: 18,
                      width: 18,

                      child:
                          CircularProgressIndicator(
                        color:
                            Colors.white,
                        strokeWidth:
                            2,
                      ),
                    )
                  : const Icon(
                      Icons.my_location,
                    ),

              label: Text(
                isGettingLocation
                    ? "Getting Location..."
                    : "Use Current Location",
              ),
            ),
          ),

          const SizedBox(height: 16),

          _field(
            controller:
                noteController,
            hint:
                "Additional Note",
            icon:
                Icons.notes,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  /// =========================================================
  /// DATE TIME
  /// =========================================================

  Widget _dateTimeSection() {

    return Row(
      children: [

        Expanded(
          child: _dateCard(
            title: "Date",
            value:
                selectedDate == null
                    ? "Select"
                    : DateFormat(
                        'dd MMM yyyy',
                      ).format(
                        selectedDate!,
                      ),
            icon:
                Icons.calendar_today,
            color:
                Colors.deepPurple,
            onTap:
                _pickDate,
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: _dateCard(
            title: "Time",
            value:
                selectedTime == null
                    ? "Select"
                    : selectedTime!
                        .format(context),
            icon:
                Icons.access_time,
            color:
                Colors.orange,
            onTap:
                _pickTime,
          ),
        ),
      ],
    );
  }

  /// =========================================================
  /// SUMMARY
  /// =========================================================

  Widget _summaryCard() {

    return _card(

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Text(
            "Booking Summary",

            style: TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          ..._serviceItems(),

          const Padding(
            padding:
                EdgeInsets.symmetric(
              vertical: 18,
            ),
            child: Divider(),
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
                      FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              Text(
                "₹${total.toStringAsFixed(0)}",

                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 28,
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
  /// ITEMS
  /// =========================================================

  List<Widget> _serviceItems() {

    if (isCart) {

      return cartItems.map((item) {

        final itemTotal =
            item.price *
            item.quantity;

        return _itemTile(
          title: item.name,
          qty:
              "Qty: ${item.quantity}",
          price:
              "₹${itemTotal.toStringAsFixed(0)}",
        );
      }).toList();
    }

    return [

      _itemTile(
        title:
            widget.product?.name ??
                widget.serviceName,
        qty: "1 Service",
        price:
            "₹${total.toStringAsFixed(0)}",
      ),
    ];
  }

  Widget _itemTile({
    required String title,
    required String qty,
    required String price,
  }) {

    return Container(

      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),

      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color:
            const Color(0xFFF8F9FD),

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Row(
        children: [

          Container(
            height: 54,
            width: 54,

            decoration:
                BoxDecoration(

              gradient:
                  const LinearGradient(
                colors: [
                  Color(0xFF6A5AE0),
                  Color(0xFF8F7CFF),
                ],
              ),

              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),

            child: const Icon(
              Icons.miscellaneous_services,
              color:
                  Colors.white,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [

                Text(
                  title,

                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(qty),
              ],
            ),
          ),

          Text(
            price,

            style: const TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  /// =========================================================
  /// COMMON CARD
  /// =========================================================

  Widget _card({
    required Widget child,
  }) {

    return Container(

      padding:
          const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          28,
        ),

        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset:
                const Offset(0, 8),
            color:
                Colors.black
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

  Widget _field({
    required TextEditingController
        controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard =
        TextInputType.text,
    int maxLines = 1,
  }) {

    return Container(

      decoration: BoxDecoration(
        color:
            const Color(0xFFF8F9FD),

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: TextField(

        controller: controller,

        keyboardType: keyboard,

        maxLines: maxLines,

        decoration: InputDecoration(

          border: InputBorder.none,

          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),

          hintText: hint,

          prefixIcon: Icon(
            icon,
            color:
                Colors.deepPurple,
          ),
        ),
      ),
    );
  }

  /// =========================================================
  /// DATE CARD
  /// =========================================================

  Widget _dateCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        padding:
            const EdgeInsets.all(
          18,
        ),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
            24,
          ),

          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              offset:
                  const Offset(0, 8),

              color: Colors.black
                  .withOpacity(0.05),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,

          children: [

            Icon(
              icon,
              color: color,
            ),

            const SizedBox(height: 16),

            Text(title),

            const SizedBox(height: 6),

            Text(
              value,

              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// =========================================================
  /// BOTTOM BAR
  /// =========================================================

  Widget _bottomBar() {

    return Container(

      padding:
          const EdgeInsets.all(18),

      child: SafeArea(

        child: SizedBox(

          height: 60,

          child: ElevatedButton(

            onPressed:
                isLoading
                    ? null
                    : _validateAndPay,

            style:
                ElevatedButton.styleFrom(

              backgroundColor:
                  Colors.black,

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  22,
                ),
              ),
            ),

            child: isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : Text(
                    "Proceed to Payment  •  ₹${total.toStringAsFixed(0)}",

                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// =========================================================
  /// SUCCESS
  /// =========================================================

  Widget _successView() {

    return SafeArea(

      child: Center(

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment
                  .center,

          children: [

            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 120,
            ),

            const SizedBox(height: 20),

            const Text(
              "Booking Confirmed",

              style: TextStyle(
                fontSize: 30,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Booking ID: $bookingId",
            ),
          ],
        ),
      ),
    );
  }

  /// =========================================================
  /// DATE
  /// =========================================================

  void _pickDate() async {

    final picked =
        await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (picked != null) {

      setState(() {
        selectedDate = picked;
      });
    }
  }

  /// =========================================================
  /// TIME
  /// =========================================================

  void _pickTime() async {

    final picked =
        await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay.now(),
    );

    if (picked != null) {

      setState(() {
        selectedTime = picked;
      });
    }
  }

  /// =========================================================
  /// LOCATION
  /// =========================================================

  Future<void>
      _getCurrentLocation() async {

    try {

      setState(() {
        isGettingLocation = true;
      });

      bool serviceEnabled =
          await Geolocator
              .isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          "Location service disabled",
        );
      }

      LocationPermission permission =
          await Geolocator
              .checkPermission();

      if (permission ==
          LocationPermission.denied) {

        permission =
            await Geolocator
                .requestPermission();
      }

      Position position =
          await Geolocator
              .getCurrentPosition();

      List<Placemark> placemarks =
          await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place =
          placemarks.first;

      addressController.text =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}";
    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text("$e"),
        ),
      );
    }

    setState(() {
      isGettingLocation = false;
    });
  }

  /// =========================================================
  /// VALIDATE
  /// =========================================================

  void _validateAndPay() {

    if (nameController.text
            .trim()
            .isEmpty ||
        phoneController.text
            .trim()
            .isEmpty ||
        addressController.text
            .trim()
            .isEmpty ||
        selectedDate == null ||
        selectedTime == null) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill all details",
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
  /// SAVE
  /// =========================================================

  Future<void> _save() async {

    try {

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
            widget.serviceName
                .trim()
                .toLowerCase(),

        services: services,

        userId: user.uid,

        userName:
            nameController.text
                .trim(),

        phone:
            phoneController.text
                .trim(),

        email: "",

        address:
            addressController.text
                .trim(),

        note:
            noteController.text
                .trim(),

        date: selectedDate!,

        time:
            selectedTime!.format(
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

      setState(() {

        bookingId = docRef.id;

        isSuccess = true;

        isLoading = false;
      });

      await Future.delayed(
        const Duration(seconds: 2),
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