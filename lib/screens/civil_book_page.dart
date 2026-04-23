import 'package:callme/provider/order_service.dart';
import 'package:flutter/material.dart';


class CivilBookingPage extends StatefulWidget {
  final String serviceName;

  const CivilBookingPage({super.key, required this.serviceName});

  @override
  State<CivilBookingPage> createState() => _CivilBookingPageState();
}

class _CivilBookingPageState extends State<CivilBookingPage> {

  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final note = TextEditingController();

  DateTime? date;
  TimeOfDay? time;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.serviceName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            _f(name, "Name"),
            _f(phone, "Phone"),
            _f(email, "Email"),
            _f(address, "Address"),
            _f(note, "Request"),

            ListTile(
              title: Text(date == null ? "Date" : date.toString()),
              onTap: _pickDate,
            ),
            ListTile(
              title: Text(time == null ? "Time" : time!.format(context)),
              onTap: _pickTime,
            ),

            ElevatedButton(
              onPressed: _submit,
              child: const Text("Submit"),
            )
          ],
        ),
      ),
    );
  }

  Widget _f(TextEditingController c, String h) =>
      TextField(controller: c, decoration: InputDecoration(labelText: h));

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

  void _submit() async {
    await OrderService.placeOrder(
      serviceType: widget.serviceName,
      services: [widget.serviceName],
      userName: name.text,
      phone: phone.text,
      email: email.text,
      address: address.text,
      note: note.text,
      date: date!,
      time: time!.format(context),
      totalAmount: 0,
    );

    Navigator.pop(context);
  }
}