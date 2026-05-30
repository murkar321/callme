import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../models/cart.dart';
import '../provider/order_service.dart';
import '../screens/bottom_nav_page.dart';
import '../payment/payment_page.dart';

class SalonBookingPage extends StatefulWidget {
  final List<dynamic> cartItems;

  const SalonBookingPage({
    super.key,
    required this.cartItems,
  });

  @override
  State<SalonBookingPage> createState() =>
      _SalonBookingPageState();
}

class _SalonBookingPageState
    extends State<SalonBookingPage> {

  /// =========================================================
  /// CONTROLLERS
  /// =========================================================

  final phoneController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final addressController =
      TextEditingController();

  final noteController =
      TextEditingController();

  bool isLoading = false;

  bool isGettingLocation = false;

  /// =========================================================
  /// VISIT TYPE
  /// =========================================================

  bool get hasHome =>
      widget.cartItems.any(
            (e) => e.id
                .toString()
                .contains("Home"),
      );

  bool get hasSalon =>
      widget.cartItems.any(
            (e) => e.id
                .toString()
                .contains("Salon"),
      );

  /// =========================================================
  /// TOTAL
  /// =========================================================

  double get totalAmount {

    double total = 0;

    for (var item in widget.cartItems) {
      total +=
          item.price *
          item.quantity;
    }

    return total;
  }

  /// =========================================================
  /// DISPOSE
  /// =========================================================

  @override
  void dispose() {

    phoneController.dispose();

    emailController.dispose();

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
          const Color(0xFFF6F7FB),

      body: SafeArea(

        child: Column(
          children: [

            /// =================================================
            /// HEADER
            /// =================================================

            _header(),

            /// =================================================
            /// BODY
            /// =================================================

            Expanded(
              child: ListView(

                padding:
                    const EdgeInsets.all(
                  20,
                ),

                children: [

                  /// SERVICES
                  _sectionTitle(
                    "Selected Services",
                  ),

                  _card(
                    child: Column(
                      children:
                          widget.cartItems
                              .map((item) {

                        final isHome =
                            item.id
                                .toString()
                                .contains(
                                  "Home",
                                );

                        return Container(

                          margin:
                              const EdgeInsets.only(
                            bottom: 14,
                          ),

                          padding:
                              const EdgeInsets.all(
                            14,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFF8F9FD,
                            ),

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
                                      Color(
                                        0xFFB38BFA,
                                      ),
                                      Color(
                                        0xFFE8A0BF,
                                      ),
                                    ],
                                  ),

                                  borderRadius:
                                      BorderRadius.circular(
                                    16,
                                  ),
                                ),

                                child: const Icon(
                                  Icons.content_cut,
                                  color:
                                      Colors
                                          .white,
                                ),
                              ),

                              const SizedBox(
                                  width:
                                      14),

                              Expanded(
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [

                                    Text(
                                      item.name,

                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,

                                        fontSize:
                                            16,
                                      ),
                                    ),

                                    const SizedBox(
                                        height:
                                            4),

                                    Text(
                                      "${isHome ? "Home Visit" : "Salon Visit"} • Qty ${item.quantity}",
                                    ),
                                  ],
                                ),
                              ),

                              Text(
                                "₹${item.price * item.quantity}",

                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,

                                  fontSize:
                                      17,
                                ),
                              ),
                            ],
                          ),
                        );

                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// APPOINTMENT TYPE
                  _sectionTitle(
                    "Appointment Type",
                  ),

                  _card(
                    child: Row(
                      children: [

                        _chip(
                          Icons.home,
                          "Home",
                          hasHome,
                        ),

                        const SizedBox(
                            width: 12),

                        _chip(
                          Icons.store,
                          "Salon",
                          hasSalon,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// DETAILS
                  _sectionTitle(
                    "Your Details",
                  ),

                  _card(
                    child: Column(
                      children: [

                        _input(
                          phoneController,
                          "Phone Number",
                          Icons.phone,
                        ),

                        const SizedBox(
                            height: 16),

                        _input(
                          emailController,
                          "Email Address",
                          Icons.email,
                        ),

                        const SizedBox(
                            height: 16),

                        if (hasHome) ...[

                          _input(
                            addressController,
                            "Home Address",
                            Icons.location_on,
                            maxLines: 3,
                          ),

                          const SizedBox(
                              height:
                                  12),

                          SizedBox(
                            width:
                                double.infinity,

                            child:
                                ElevatedButton.icon(

                              onPressed:
                                  isGettingLocation
                                      ? null
                                      : _getCurrentLocation,

                              style:
                                  ElevatedButton.styleFrom(

                                backgroundColor:
                                    const Color(
                                  0xFFB38BFA,
                                ),

                                foregroundColor:
                                    Colors.white,

                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical:
                                      16,
                                ),

                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    18,
                                  ),
                                ),
                              ),

                              icon:
                                  isGettingLocation
                                      ? const SizedBox(
                                          height:
                                              18,
                                          width:
                                              18,

                                          child:
                                              CircularProgressIndicator(
                                            color:
                                                Colors.white,

                                            strokeWidth:
                                                2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons
                                              .my_location,
                                        ),

                              label: Text(
                                isGettingLocation
                                    ? "Getting Location..."
                                    : "Use Current Location",
                              ),
                            ),
                          ),

                          const SizedBox(
                              height:
                                  16),
                        ],

                        _input(
                          noteController,
                          "Additional Note",
                          Icons.notes,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),

      /// =======================================================
      /// BOTTOM BAR
      /// =======================================================

      bottomNavigationBar:
          Container(

        padding:
            const EdgeInsets.all(
          18,
        ),

        decoration:
            const BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.vertical(
            top:
                Radius.circular(
              28,
            ),
          ),
        ),

        child: SafeArea(

          child: Row(
            children: [

              Expanded(
                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  mainAxisSize:
                      MainAxisSize.min,

                  children: [

                    const Text(
                      "Total Amount",

                      style: TextStyle(
                        color:
                            Colors.grey,
                      ),
                    ),

                    Text(
                      "₹${totalAmount.toStringAsFixed(0)}",

                      style:
                          const TextStyle(
                        fontSize: 24,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child:
                    ElevatedButton(

                  onPressed:
                      isLoading
                          ? null
                          : _continueToPayment,

                  style:
                      ElevatedButton.styleFrom(

                    backgroundColor:
                        const Color(
                      0xFFB38BFA,
                    ),

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
                      : const Text(
                          "Proceed To Pay",

                          style:
                              TextStyle(
                            fontSize:
                                16,

                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
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
            Color(0xFFB38BFA),
            Color(0xFFE8A0BF),
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
                    .withOpacity(0.2),

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
            "Salon Booking",

            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "${widget.cartItems.length} services selected",

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
  /// PAYMENT FLOW
  /// =========================================================

  Future<void>
      _continueToPayment() async {

    final user =
        FirebaseAuth
            .instance
            .currentUser;

    if (phoneController.text
            .trim()
            .isEmpty ||
        emailController.text
            .trim()
            .isEmpty) {

      _showCenterPopup(
        "Please fill all details",
        false,
      );

      return;
    }

    if (hasHome &&
        addressController.text
            .trim()
            .isEmpty) {

      _showCenterPopup(
        "Address required",
        false,
      );

      return;
    }

    if (user == null) {

      _showCenterPopup(
        "Please login first",
        false,
      );

      return;
    }

    final result =
        await Navigator.push(

      context,

      MaterialPageRoute(
        builder: (_) => PaymentPage(

          serviceName:
              "Salon Booking",

          amount:
              totalAmount.toInt(),
        ),
      ),
    );

    if (result == true ||
        result == 'offline') {

      setState(() {
        isLoading = true;
      });

      try {

        await OrderService.placeOrder(

          serviceType:
              "salon",

          services:
              widget.cartItems
                  .map(
                    (e) =>
                        "${e.name} (${e.id.toString().contains("Home") ? "Home" : "Salon"}) x${e.quantity}",
                  )
                  .toList(),

          userId: user.uid,

          userName:
              "Salon User",

          phone:
              phoneController.text
                  .trim(),

          email:
              emailController.text
                  .trim(),

          createdBy:
              user.uid,

          createdByRole:
              "user",

          address: hasHome
              ? addressController.text
                    .trim()
              : "Salon Visit",

          date:
              DateTime.now(),

          time:
              TimeOfDay.now()
                  .format(
                context,
              ),

          totalAmount:
              totalAmount,

          visitType:
              hasHome &&
                      hasSalon
                  ? "Mixed"
                  : hasHome
                      ? "Home"
                      : "Salon",

          providerId:
              null,

          providerUserId:
              null,

          providerName:
              null,

          isEnquiry:
              false,
        );

        /// CLEAR CART
        Cart.clear("Salon");

        _showCenterPopup(
          result == 'offline'
              ? "Booking Placed Successfully"
              : "Payment Successful",
          true,
        );

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
                  phoneController
                      .text,

              userEmail:
                  emailController
                      .text,
            ),
          ),

          (route) => false,
        );

      } catch (e) {

        _showCenterPopup(
          "Error: $e",
          false,
        );
      }

      setState(() {
        isLoading = false;
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
        isGettingLocation =
            true;
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

      _showCenterPopup(
        "$e",
        false,
      );
    }

    setState(() {
      isGettingLocation =
          false;
    });
  }

  /// =========================================================
  /// CENTER POPUP
  /// =========================================================

  void _showCenterPopup(
    String message,
    bool success,
  ) {

    showDialog(

      context: context,

      barrierDismissible: true,

      builder: (_) {

        return Dialog(

          backgroundColor:
              Colors.transparent,

          child: Container(

            padding:
                const EdgeInsets.all(
              24,
            ),

            decoration:
                BoxDecoration(
              color:
                  Colors.white,

              borderRadius:
                  BorderRadius.circular(
                28,
              ),
            ),

            child: Column(

              mainAxisSize:
                  MainAxisSize.min,

              children: [

                Container(
                  height: 80,
                  width: 80,

                  decoration:
                      BoxDecoration(
                    color: success
                        ? Colors.green
                            .withOpacity(
                            0.1,
                          )
                        : Colors.red
                            .withOpacity(
                            0.1,
                          ),

                    shape:
                        BoxShape.circle,
                  ),

                  child: Icon(
                    success
                        ? Icons
                            .check_circle
                        : Icons.error,

                    color: success
                        ? Colors.green
                        : Colors.red,

                    size: 50,
                  ),
                ),

                const SizedBox(
                    height: 20),

                Text(
                  message,

                  textAlign:
                      TextAlign.center,

                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(
      const Duration(
        seconds: 2,
      ),
      () {

        if (mounted &&
            Navigator.canPop(
              context,
            )) {

          Navigator.pop(context);
        }
      },
    );
  }

  /// =========================================================
  /// UI HELPERS
  /// =========================================================

  Widget _sectionTitle(
    String title,
  ) {

    return Padding(

      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),

      child: Text(
        title,

        style: const TextStyle(
          fontSize: 18,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Widget _card({
    required Widget child,
  }) {

    return Container(

      padding:
          const EdgeInsets.all(
        18,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          26,
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

      child: child,
    );
  }

  Widget _chip(
    IconData icon,
    String label,
    bool active,
  ) {

    return Expanded(
      child: Container(

        padding:
            const EdgeInsets.symmetric(
          vertical: 14,
        ),

        decoration:
            BoxDecoration(

          gradient: active
              ? const LinearGradient(
                  colors: [
                    Color(
                      0xFFB38BFA,
                    ),
                    Color(
                      0xFFE8A0BF,
                    ),
                  ],
                )
              : null,

          color: active
              ? null
              : Colors.grey
                    .shade200,

          borderRadius:
              BorderRadius.circular(
            20,
          ),
        ),

        child: Row(

          mainAxisAlignment:
              MainAxisAlignment
                  .center,

          children: [

            Icon(
              icon,

              size: 18,

              color: active
                  ? Colors.white
                  : Colors.black54,
            ),

            const SizedBox(width: 6),

            Text(
              label,

              style: TextStyle(
                color: active
                    ? Colors.white
                    : Colors.black54,

                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController
        controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {

    return Container(

      decoration: BoxDecoration(
        color:
            const Color(
          0xFFF8F9FD,
        ),

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: TextField(

        controller: controller,

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
                const Color(
              0xFFB38BFA,
            ),
          ),
        ),
      ),
    );
  }
}