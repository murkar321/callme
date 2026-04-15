import 'package:flutter/material.dart';
import '../provider/service_config.dart';
import '../screens/success_page.dart';

class ServiceProviderForm extends StatefulWidget {
  final String type;
  final String providerType;

  const ServiceProviderForm({
    super.key,
    required this.type,
    required this.providerType,
  });

  @override
  State<ServiceProviderForm> createState() => _ServiceProviderFormState();
}

class _ServiceProviderFormState extends State<ServiceProviderForm> {
  int currentStep = 0;

  final List<String> selectedCategories = [];
  final List<String> selectedAmenities = [];

  bool ownTools = false;
  bool homeVisit = false;
  bool pickupDrop = false;

  // Controllers
  final ownerController = TextEditingController();
  final businessController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();

  final staffCountController = TextEditingController();
  final roomCountController = TextEditingController();
  final priceController = TextEditingController();

  final bankHolderController = TextEditingController();
  final accountController = TextEditingController();
  final ifscController = TextEditingController();
  final upiController = TextEditingController();

  @override
  void dispose() {
    ownerController.dispose();
    businessController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    staffCountController.dispose();
    roomCountController.dispose();
    priceController.dispose();
    bankHolderController.dispose();
    accountController.dispose();
    ifscController.dispose();
    upiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = serviceConfigs[widget.type]!;

    final steps = <Step>[
      /// STEP 1 → Categories
      Step(
        title: const Text("Service Categories"),
        isActive: currentStep >= 0,
        content: Column(
          children: config.serviceCategories.map((category) {
            return CheckboxListTile(
              title: Text(category),
              value: selectedCategories.contains(category),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    selectedCategories.add(category);
                  } else {
                    selectedCategories.remove(category);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),

      /// STEP 2 → Business + Provider Details
      Step(
        title: const Text("Provider Details"),
        isActive: currentStep >= 1,
        content: _buildCard(
          children: [
            _buildTextField(
              businessController,
              config.businessLabel,
              Icons.business,
            ),
            _buildTextField(
              ownerController,
              "Owner Name",
              Icons.person,
            ),
            _buildTextField(
              phoneController,
              "Phone Number",
              Icons.phone,
            ),
            _buildTextField(
              emailController,
              "Email",
              Icons.email,
            ),
            _buildTextField(
              addressController,
              "Address",
              Icons.location_on,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    cityController,
                    "City",
                    Icons.location_city,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    stateController,
                    "State",
                    Icons.map,
                  ),
                ),
              ],
            ),
            _buildTextField(
              pincodeController,
              "Pincode",
              Icons.pin_drop,
            ),

            const SizedBox(height: 10),

            Text(
              "Provider Type: ${widget.providerType}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            if (widget.providerType != "Individual")
              _buildTextField(
                staffCountController,
                "Staff Count",
                Icons.groups,
              ),
          ],
        ),
      ),

      /// STEP 3 → Service Specific Options
      Step(
        title: const Text("Service Options"),
        isActive: currentStep >= 2,
        content: _buildCard(
          children: [
            if (config.showRoomCount)
              _buildTextField(
                roomCountController,
                "Total Rooms",
                Icons.hotel,
              ),

            _buildTextField(
              priceController,
              "Base Price / Starting Price",
              Icons.currency_rupee,
            ),

            if (widget.type == "salon" ||
                widget.type == "cleaning" ||
                widget.type == "plumbing")
              SwitchListTile(
                title: const Text("Own Tools Available"),
                value: ownTools,
                onChanged: (val) {
                  setState(() => ownTools = val);
                },
              ),

            if (widget.type == "salon")
              SwitchListTile(
                title: const Text("Home Visit Available"),
                value: homeVisit,
                onChanged: (val) {
                  setState(() => homeVisit = val);
                },
              ),

            if (widget.type == "laundry")
              SwitchListTile(
                title: const Text("Pickup & Drop Available"),
                value: pickupDrop,
                onChanged: (val) {
                  setState(() => pickupDrop = val);
                },
              ),

            if (config.amenities.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                "Amenities",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ...config.amenities.map((amenity) {
                return CheckboxListTile(
                  title: Text(amenity),
                  value: selectedAmenities.contains(amenity),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        selectedAmenities.add(amenity);
                      } else {
                        selectedAmenities.remove(amenity);
                      }
                    });
                  },
                );
              }),
            ],
          ],
        ),
      ),

      /// STEP 4 → Bank Details
      Step(
        title: const Text("Bank Details"),
        isActive: currentStep >= 3,
        content: _buildCard(
          children: [
            _buildTextField(
              bankHolderController,
              "Account Holder Name",
              Icons.person,
            ),
            _buildTextField(
              accountController,
              "Account Number",
              Icons.account_balance,
            ),
            _buildTextField(
              ifscController,
              "IFSC Code",
              Icons.code,
            ),
            _buildTextField(
              upiController,
              "UPI ID",
              Icons.payment,
            ),
          ],
        ),
      ),

      /// STEP 5 → Documents
      Step(
        title: const Text("Documents"),
        isActive: currentStep >= 4,
        content: _buildCard(
          children: config.requiredDocuments.map((doc) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload_file),
                label: Text("Upload $doc"),
              ),
            );
          }).toList(),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.type.toUpperCase()} Registration"),
      ),
      body: Stepper(
        currentStep: currentStep,
        steps: steps,
        onStepContinue: () {
          if (currentStep < steps.length - 1) {
            setState(() => currentStep++);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SuccessPage(),
              ),
            );
          }
        },
        onStepCancel: () {
          if (currentStep > 0) {
            setState(() => currentStep--);
          }
        },
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}