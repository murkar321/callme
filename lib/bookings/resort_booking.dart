import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:callme/data/resorts_data.dart';
import 'package:callme/provider/order_service.dart';
import 'package:callme/screens/bottom_nav_page.dart';
import 'package:callme/screens/upi_payment.dart';

class ResortBookingPage extends StatefulWidget {
  final Resort resort;

  const ResortBookingPage({
    super.key,
    required this.resort,
  });

  @override
  State<ResortBookingPage> createState() => _ResortBookingPageState();
}

class _ResortBookingPageState extends State<ResortBookingPage> {
  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController addressController =
      TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  int adults = 1;
  int children = 0;

  bool isLoading = false;

  double get totalAmount {
    return (widget.resort.price * adults) +
        ((widget.resort.price / 2) * children);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,

            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),

            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    widget.resort.image,
                    fit: BoxFit.cover,
                  ),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(.15),
                          Colors.black.withOpacity(.65),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 25,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.resort.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.resort.location,
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
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
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Booking Summary",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        _infoRow(
                          "Resort",
                          widget.resort.name,
                        ),

                        _infoRow(
                          "City",
                          widget.resort.city,
                        ),

                        _infoRow(
                          "Price Per Adult",
                          "₹${widget.resort.price}",
                        ),

                        _infoRow(
                          "Rating",
                          "⭐ ${widget.resort.rating}",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _sectionCard(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Guests",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),

                        const SizedBox(height: 16),

                        _counterTile(
                          title: "Adults",
                          value: adults,
                          onMinus: () {
                            if (adults > 1) {
                              setState(() {
                                adults--;
                              });
                            }
                          },
                          onPlus: () {
                            setState(() {
                              adults++;
                            });
                          },
                        ),

                        const Divider(),

                        _counterTile(
                          title: "Children",
                          value: children,
                          onMinus: () {
                            if (children > 0) {
                              setState(() {
                                children--;
                              });
                            }
                          },
                          onPlus: () {
                            setState(() {
                              children++;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _sectionCard(
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding:
                              EdgeInsets.zero,
                          leading: const Icon(
                            Icons.calendar_month,
                            color: Colors.deepPurple,
                          ),
                          title: Text(
                            selectedDate == null
                                ? "Select Check-In Date"
                                : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                          ),
                          trailing:
                              const Icon(Icons.chevron_right),
                          onTap: _pickDate,
                        ),

                        const Divider(),

                        ListTile(
                          contentPadding:
                              EdgeInsets.zero,
                          leading: const Icon(
                            Icons.access_time,
                            color: Colors.deepPurple,
                          ),
                          title: Text(
                            selectedTime == null
                                ? "Select Check-In Time"
                                : selectedTime!
                                    .format(context),
                          ),
                          trailing:
                              const Icon(Icons.chevron_right),
                          onTap: _pickTime,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _sectionCard(
                    child: Column(
                      children: [
                        _field(
                          controller: nameController,
                          hint: "Full Name",
                          icon: Icons.person_outline,
                        ),

                        const SizedBox(height: 14),

                        _field(
                          controller: phoneController,
                          hint: "Mobile Number",
                          icon: Icons.phone_outlined,
                          keyboard:
                              TextInputType.phone,
                        ),

                        const SizedBox(height: 14),

                        _field(
                          controller:
                              addressController,
                          hint: "Address",
                          icon:
                              Icons.location_city_outlined,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _sectionCard(
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
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
                          "₹${totalAmount.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 24,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed:
                          isLoading ? null : _payNow,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.deepPurple,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Proceed To Payment",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _payNow() async {
    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty) {
      _show("Please fill all details");
      return;
    }

    if (selectedDate == null ||
        selectedTime == null) {
      _show("Please select date and time");
      return;
    }

    final paymentSuccess =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpiPaymentScreen(
          amount: totalAmount,
        ),
      ),
    );

    if (paymentSuccess == true) {
      await _saveBooking();
    }
  }

  Future<void> _saveBooking() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _show("User not logged in");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await OrderService.placeOrder(
        serviceType: "resort",
        services: [
          widget.resort.name,
        ],
        userId: user.uid,
        userName:
            nameController.text.trim(),
        phone:
            phoneController.text.trim(),
        createdBy: user.uid,
        createdByRole: "user",
        address:
            addressController.text.trim(),
        date: selectedDate!,
        time:
            selectedTime!.format(context),
        totalAmount: totalAmount,
        adults: adults,
        children: children,
        visitType: "resort",
        providerId:
            widget.resort.providerId,
        providerName:
            widget.resort.name,
        isEnquiry: false,
      );

      if (!mounted) return;

      _show("Booking Confirmed ✅");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => BottomNavPage(
            userPhone:
                phoneController.text.trim(),
            userEmail: "",
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      _show("Error: $e");
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboard =
        TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hint,
        filled: true,
        fillColor:
            const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _counterTile({
    required String title,
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.w600,
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: onMinus,
              icon: const Icon(
                Icons.remove_circle_outline,
              ),
            ),
            Text(
              "$value",
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: onPlus,
              icon: const Icon(
                Icons.add_circle_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked =
        await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}