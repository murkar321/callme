import 'package:callme/screens/personal_detail.dart';
import 'package:flutter/material.dart';

class ServiceSelection extends StatefulWidget {
  final String type;

  const ServiceSelection({super.key, required this.type});

  @override
  _ServiceSelectionState createState() =>
      _ServiceSelectionState();
}

class _ServiceSelectionState extends State<ServiceSelection> {
  final Map<String, bool> services = {
    "Pipe Repair": false,
    "Leakage Fix": true,
    "Tap Installation": false,
    "Drain Cleaning": false,
    "Bathroom Repair": false,
    "Toilet Repair": false,
    "Water Tank Cleaning": false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.type} Services"),
        centerTitle: true,
      ),

      body: Column(
        children: [

          /// Title (like your wireframe)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              "Service Provided Options",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          /// Services List
          Expanded(
            child: ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, index) {
                String service = services.keys.elementAt(index);

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CheckboxListTile(
                    title: Text(service),
                    value: services[service],
                    activeColor: Colors.blue,
                    onChanged: (value) {
                      setState(() {
                        services[service] = value!;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          /// Next Button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {

                  /// Get selected services
                  List<String> selectedServices = services.entries
                      .where((entry) => entry.value)
                      .map((entry) => entry.key)
                      .toList();

                  /// Optional validation
                  if (selectedServices.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please select at least one service")),
                    );
                    return;
                  }

                  /// Navigate forward
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PersonalDetail(
                        selectedServices: selectedServices,
                        type: widget.type,
                      ),
                    ),
                  );
                },
                child: Text("Next"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}