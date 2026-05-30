import 'package:callme/provider/order_service.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class CivilBookingPage extends StatefulWidget {
  final String serviceName;

  const CivilBookingPage({
    super.key,
    required this.serviceName,
  });

  @override
  State<CivilBookingPage> createState() =>
      _CivilBookingPageState();
}

class _CivilBookingPageState
    extends State<CivilBookingPage> {

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

  bool isGettingLocation = false;

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
          const Color(0xFFF5F7FC),

      body: SafeArea(

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

                  _detailsCard(),

                  const SizedBox(height: 20),

                  _dateTimeCard(),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar:
          Container(

        padding:
            const EdgeInsets.all(
          18,
        ),

        color: Colors.white,

        child: SafeArea(

          child: SizedBox(

            height: 58,

            child: ElevatedButton(

              onPressed:
                  isLoading
                      ? null
                      : _submit,

              style:
                  ElevatedButton.styleFrom(

                backgroundColor:
                    const Color(
                  0xFF5B67F1,
                ),

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
                  ? const CircularProgressIndicator(
                      color:
                          Colors.white,
                    )
                  : const Text(
                      "Submit Enquiry",

                      style:
                          TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// HEADER

  Widget _header() {

    return Container(

      width: double.infinity,

      padding:
          const EdgeInsets.all(24),

      decoration:
          const BoxDecoration(

        gradient: LinearGradient(
          colors: [
            Color(0xFF5B67F1),
            Color(0xFF7B86FF),
          ],
        ),

        borderRadius:
            BorderRadius.vertical(
          bottom:
              Radius.circular(32),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          GestureDetector(
            onTap: () =>
                Navigator.pop(
                  context,
                ),

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
                  12,
                ),
              ),

              child: const Icon(
                Icons.arrow_back,
                color:
                    Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 28),

          Text(
            widget.serviceName,

            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Tell us about your project requirements",

            style: TextStyle(
              color: Colors.white
                  .withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  /// DETAILS

  Widget _detailsCard() {

    return _card(

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Text(
            "Project Details",

            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          _input(
            controller:
                nameController,
            hint:
                "Full Name",
            icon:
                Icons.person,
          ),

          const SizedBox(height: 16),

          _input(
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

          _input(
            controller:
                addressController,
            hint:
                "Project Address",
            icon:
                Icons.location_on,
            maxLines: 3,
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,

            child:
                ElevatedButton.icon(

              onPressed:
                  isGettingLocation
                      ? null
                      : _getLocation,

              style:
                  ElevatedButton.styleFrom(

                backgroundColor:
                    const Color(
                  0xFF5B67F1,
                ),

                foregroundColor:
                    Colors.white,

                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
              ),

              icon:
                  isGettingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,

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

          _input(
            controller:
                noteController,
            hint:
                "Describe your requirement",
            icon:
                Icons.description,
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  /// DATE TIME

  Widget _dateTimeCard() {

    return Row(
      children: [

        Expanded(
          child: _pickerCard(
            icon:
                Icons.calendar_today,
            title: "Date",
            value:
                selectedDate == null
                    ? "Select"
                    : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
            onTap:
                _pickDate,
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: _pickerCard(
            icon:
                Icons.access_time,
            title: "Time",
            value:
                selectedTime == null
                    ? "Select"
                    : selectedTime!
                        .format(
                      context,
                    ),
            onTap:
                _pickTime,
          ),
        ),
      ],
    );
  }

  Widget _pickerCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        padding:
            const EdgeInsets.all(
          18,
        ),

        decoration:
            BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
            24,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.05),

              blurRadius: 14,
            ),
          ],
        ),

        child: Column(
          children: [

            Icon(
              icon,
              color:
                  const Color(
                0xFF5B67F1,
              ),
            ),

            const SizedBox(height: 10),

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

  Widget _card({
    required Widget child,
  }) {

    return Container(

      padding:
          const EdgeInsets.all(
        20,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          28,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.05),

            blurRadius: 15,
          ),
        ],
      ),

      child: child,
    );
  }

  Widget _input({
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
            const Color(
          0xFFF8F9FD,
        ),

        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child: TextField(

        controller: controller,

        keyboardType: keyboard,

        maxLines: maxLines,

        decoration: InputDecoration(

          border:
              InputBorder.none,

          hintText: hint,

          prefixIcon: Icon(
            icon,
            color:
                const Color(
              0xFF5B67F1,
            ),
          ),

          contentPadding:
              const EdgeInsets.all(
            18,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {

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

  Future<void> _pickTime() async {

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

  Future<void> _getLocation() async {

    try {

      setState(() {
        isGettingLocation =
            true;
      });

      Position position =
          await Geolocator
              .getCurrentPosition();

      List<Placemark> places =
          await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final place =
          places.first;

      addressController.text =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}";

    } catch (_) {}

    setState(() {
      isGettingLocation =
          false;
    });
  }

  Future<void> _submit() async {

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
            "Please fill all required fields",
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      await OrderService.placeOrder(
        serviceType:
            widget.serviceName,

        services: [
          widget.serviceName,
        ],

        userName:
            nameController.text,

        phone:
            phoneController.text,

        email: "",

        address:
            addressController.text,

        note:
            noteController.text,

        date: selectedDate!,

        time:
            selectedTime!.format(
          context,
        ),

        totalAmount: 0,

        userId: "",

        createdBy: "",

        createdByRole: "",

        isEnquiry: true,
      );

      if (!mounted) return;

      Navigator.pop(context);

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
      isLoading = false;
    });
  }
}