import 'package:flutter/material.dart';
import '../data/salon_data.dart';

class SalonBookingPage extends StatefulWidget {
  final List<SalonService> services;
  final Map<String, String> visitTypeMap;

  const SalonBookingPage({
    super.key,
    required this.services,
    required this.visitTypeMap,
  });

  @override
  State<SalonBookingPage> createState() =>
      _SalonBookingPageState();
}

class _SalonBookingPageState
    extends State<SalonBookingPage> {

  Map<String, String> visitType = {};
  Map<String, DateTime> selectedDate = {};
  Map<String, TimeOfDay> selectedTime = {};

  @override
  void initState() {
    super.initState();

    for (var s in widget.services) {
      visitType[s.name] =
          widget.visitTypeMap[s.name] ?? "Salon";

      selectedDate[s.name] = DateTime.now();
      selectedTime[s.name] = TimeOfDay.now();
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Salon Booking"),
        backgroundColor: const Color(0xFFAE91BA),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const Text(
            "Selected Services",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          ...widget.services.map((service) {

            final type = visitType[service.name]!;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        Text("₹${service.finalPrice}")
                      ],
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade200,
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Text(type),
                    ),

                    const SizedBox(height: 10),

                    ListTile(
                      leading:
                          const Icon(Icons.calendar_today),
                      title: const Text("Select Date"),
                      subtitle: Text(
                          selectedDate[service.name]
                              .toString()
                              .split(" ")[0]),
                    ),

                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text("Select Time"),
                      subtitle: Text(
                          selectedTime[service.name]!
                              .format(context)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 20),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFFAE91BA),
            ),
            onPressed: () {},
            child: const Text("Confirm Booking"),
          )
        ],
      ),
    );
  }
}