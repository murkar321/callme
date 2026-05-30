import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:callme/data/hotel_data.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/provider/order_service.dart';
import 'package:callme/screens/bottom_nav_page.dart';

class HotelBookingPage extends StatefulWidget {
  final HotelRoom hotel;
  final List<dynamic> products;

  const HotelBookingPage({
    super.key,
    required this.hotel,
    required this.products,
  });

  @override
  State<HotelBookingPage> createState() =>
      _HotelBookingPageState();
}

class _HotelBookingPageState
    extends State<HotelBookingPage> {
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

  List<CartItem> get cartItems =>
      Cart.getItems("Hotel");

  double get totalAmount {
    if (cartItems.isNotEmpty) {
      return Cart.getTotal("Hotel")
          .toDouble();
    }

    return (widget.hotel.price -
            (widget.hotel.price *
                widget.hotel.discount /
                100))
        .toDouble();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF6F7FB),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding:
                    EdgeInsets.zero,

                children: [
                  _hotelHeader(),

                  Padding(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    child: Column(
                      children: [
                        _hotelInfoCard(),

                        const SizedBox(
                            height: 16),

                        _bookingSummary(),

                        const SizedBox(
                            height: 16),

                        _scheduleCard(),

                        const SizedBox(
                            height: 16),

                        _guestCard(),

                        const SizedBox(
                            height: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _hotelHeader() {
    return Stack(
      children: [
        SizedBox(
          height: 250,
          width: double.infinity,
          child: Image.asset(
            widget.hotel.image,
            fit: BoxFit.cover,
          ),
        ),

        Positioned(
          top: 12,
          left: 12,
          child: CircleAvatar(
            backgroundColor:
                Colors.white,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
              ),
              onPressed: () =>
                  Navigator.pop(
                context,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _hotelInfoCard() {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            widget.hotel.hotelName,
            style:
                const TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            widget.hotel.city,
            style: TextStyle(
              color:
                  Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            widget.hotel.category,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            "₹${totalAmount.toStringAsFixed(0)}",
            style:
                const TextStyle(
              color:
                  Colors.deepPurple,
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingSummary() {
    return _card(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "Booking Summary",
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 12),

          if (cartItems.isEmpty)
            ListTile(
              contentPadding:
                  EdgeInsets.zero,
              title: Text(
                widget.hotel.category,
              ),
              trailing: Text(
                "₹${totalAmount.toStringAsFixed(0)}",
              ),
            ),

          ...cartItems.map(
            (e) => ListTile(
              contentPadding:
                  EdgeInsets.zero,
              title: Text(e.name),
              subtitle: Text(
                "Qty ${e.quantity}",
              ),
              trailing: Text(
                "₹${e.price * e.quantity}",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleCard() {
    return _card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.calendar_month,
            ),
            title: Text(
              selectedDate == null
                  ? "Select Check-In Date"
                  : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
            ),
            onTap: pickDate,
          ),

          const Divider(),

          ListTile(
            leading: const Icon(
              Icons.access_time,
            ),
            title: Text(
              selectedTime == null
                  ? "Select Time"
                  : selectedTime!
                      .format(
                    context,
                  ),
            ),
            onTap: pickTime,
          ),
        ],
      ),
    );
  }

  Widget _guestCard() {
    return _card(
      child: Column(
        children: [
          _field(
            nameController,
            "Guest Name",
          ),
          _field(
            phoneController,
            "Phone Number",
          ),
          _field(
            addressController,
            "Address",
            maxLines: 3,
          ),
          _field(
            noteController,
            "Special Request",
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black12,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Text(
                "₹${totalAmount.toStringAsFixed(0)}",
                style:
                    const TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    isLoading
                        ? null
                        : submitBooking,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        "Book Now",
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required Widget child,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),
      child: child,
    );
  }

  Widget _field(
    TextEditingController c,
    String hint, {
    int maxLines = 1,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration:
            InputDecoration(
          hintText: hint,
          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pickDate() async {
    final d =
        await showDatePicker(
      context: context,
      firstDate:
          DateTime.now(),
      lastDate:
          DateTime(2100),
      initialDate:
          DateTime.now(),
    );

    if (d != null) {
      setState(() {
        selectedDate = d;
      });
    }
  }

  Future<void> pickTime() async {
    final t =
        await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay.now(),
    );

    if (t != null) {
      setState(() {
        selectedTime = t;
      });
    }
  }

  Future<void> submitBooking()
      async {
    if (nameController.text
            .trim()
            .isEmpty ||
        phoneController.text
            .trim()
            .isEmpty ||
        addressController.text
            .trim()
            .isEmpty) {
      _show(
        "Please fill all details",
      );
      return;
    }

    if (selectedDate == null ||
        selectedTime == null) {
      _show(
        "Select date & time",
      );
      return;
    }

    final user =
        FirebaseAuth
            .instance
            .currentUser;

    if (user == null) {
      _show("Login required");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await OrderService.placeOrder(
        serviceType: "hotel",
        services: [
          widget.hotel.category,
        ],
        userId: user.uid,
        userName:
            nameController.text,
        phone:
            phoneController.text,
        createdBy: user.uid,
        createdByRole: "user",
        address:
            addressController.text,
        note: noteController.text,
        date: selectedDate!,
        time: selectedTime!
            .format(context),
        totalAmount:
            totalAmount,
      );

      Cart.clear("Hotel");

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible:
            false,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),
          content: const Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 70,
              ),
              SizedBox(height: 12),
              Text(
                "Booking Confirmed",
              ),
            ],
          ),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BottomNavPage(
            userPhone:
                phoneController
                    .text,
            userEmail: "",
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      _show(e.toString());
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(msg),
      ),
    );
  }
}

