import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class HotelProviderPage extends StatefulWidget {
  const HotelProviderPage({super.key});

  @override
  State<HotelProviderPage> createState() => _HotelProviderPageState();
}

class _HotelProviderPageState extends State<HotelProviderPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController hotelName = TextEditingController();
  final TextEditingController ownerName = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController email = TextEditingController();

  final TextEditingController address = TextEditingController();
  final TextEditingController city = TextEditingController();
  final TextEditingController stateCtrl = TextEditingController();
  final TextEditingController pincode = TextEditingController();

  final TextEditingController totalRooms = TextEditingController();
  final TextEditingController price = TextEditingController();

  // Room types
  Map<String, bool> roomTypes = {
    "Junior Suite": false,
    "Executive Suite": false,
    "Family Suite": false,
    "Deluxe Suite": false,
    "Mini Suite": false,
  };

  // Amenities
  Map<String, bool> amenities = {
    "Free Wi-Fi": false,
    "Air Conditioning": false,
    "Parking": false,
    "Room Service": false,
    "Restaurant": false,
    "Breakfast Included": false,
    "TV": false,
    "Laundry Service": false,
    "Power Backup": false,
    "24/7 Reception": false,
  };

  // Files
  File? aadhaar;
  File? pan;
  File? gst;
  File? license;
  List<File> hotelImages = [];

  final ImagePicker picker = ImagePicker();

  Future pickFile(Function(File) onSelected) async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      onSelected(File(picked.path));
      setState(() {});
    }
  }

  Future pickMultipleImages() async {
    final images = await picker.pickMultiImage();
    hotelImages = images.map((e) => File(e.path)).toList();
    setState(() {});
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: (val) => val!.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget buildCheckboxList(Map<String, bool> data) {
    return Column(
      children: data.keys.map((key) {
        return CheckboxListTile(
          title: Text(key),
          value: data[key],
          onChanged: (val) {
            setState(() {
              data[key] = val!;
            });
          },
        );
      }).toList(),
    );
  }

  Widget buildUpload(String title, File? file, Function() onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: file == null
                  ? const Text("Upload")
                  : const Icon(Icons.check_circle, color: Colors.green),
            ),
          ),
        ),
        const SizedBox(height: 10)
      ],
    );
  }

  void submit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hotel Registered Successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register Hotel")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle("Basic Details"),
              buildTextField("Hotel Name", hotelName),
              buildTextField("Owner Name", ownerName),
              buildTextField("Mobile Number", phone, type: TextInputType.phone),
              buildTextField("Email ID", email,
                  type: TextInputType.emailAddress),
              buildSectionTitle("Location Details"),
              buildTextField("Hotel Address", address),
              buildTextField("City", city),
              buildTextField("State", stateCtrl),
              buildTextField("Pincode", pincode, type: TextInputType.number),
              buildSectionTitle("Hotel Details"),
              buildTextField("Total Rooms", totalRooms,
                  type: TextInputType.number),
              buildSectionTitle("Room Types"),
              buildCheckboxList(roomTypes),
              buildSectionTitle("Amenities"),
              buildCheckboxList(amenities),
              buildSectionTitle("Pricing"),
              buildTextField("Starting Price Per Night", price,
                  type: TextInputType.number),
              buildSectionTitle("Upload Documents"),
              buildUpload("Owner Aadhaar Card", aadhaar,
                  () => pickFile((f) => aadhaar = f)),
              buildUpload("PAN Card", pan, () => pickFile((f) => pan = f)),
              buildUpload(
                  "GST Certificate", gst, () => pickFile((f) => gst = f)),
              buildUpload(
                  "Trade License", license, () => pickFile((f) => license = f)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: pickMultipleImages,
                child: const Text("Upload Hotel Photos"),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: submit,
                  child: const Text("Register Hotel"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
