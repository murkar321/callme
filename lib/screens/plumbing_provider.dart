import 'package:callme/screens/service_selection.dart';
import 'package:flutter/material.dart';

class PlumbingProvider extends StatelessWidget {
  const PlumbingProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Plumber")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildOption(context, "Agency"),
            buildOption(context, "Individual"),
            buildOption(context, "Business"),
          ],
        ),
      ),
    );
  }

  Widget buildOption(BuildContext context, String type) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceSelection(type: type),
            ),
          );
        },
        child: Text(type),
      ),
    );
  }
}
