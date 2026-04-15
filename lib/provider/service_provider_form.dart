import 'package:flutter/material.dart';
import 'package:callme/screens/success_page.dart';
import '../data/service_config.dart';

class ServiceProviderForm extends StatefulWidget {
  final String type;

  const ServiceProviderForm({super.key, required this.type});

  @override
  State<ServiceProviderForm> createState() => _ServiceProviderFormState();
}

class _ServiceProviderFormState extends State<ServiceProviderForm> {
  final List<String> selectedServices = [];
  bool homeVisit = false;

  int currentStep = 0;

  // Controllers
  final ownerController = TextEditingController();
  final businessController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();

  final bankHolderController = TextEditingController();
  final accountController = TextEditingController();
  final ifscController = TextEditingController();
  final upiController = TextEditingController();

  final aadharController = TextEditingController();
  final panController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final config = serviceConfigs[widget.type]!;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.type} Registration"),
        centerTitle: true,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: currentStep,
        onStepContinue: () {
          if (currentStep < 3) {
            setState(() => currentStep++);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SuccessPage()),
            );
          }
        },
        onStepCancel: () {
          if (currentStep > 0) {
            setState(() => currentStep--);
          }
        },
        steps: [

          /// 🔹 STEP 1: SERVICES
          Step(
            title: Text("Services"),
            isActive: currentStep >= 0,
            content: Column(
              children: config.services.map((service) {
                return CheckboxListTile(
                  title: Text(service),
                  value: selectedServices.contains(service),
                  onChanged: (val) {
                    setState(() {
                      val!
                          ? selectedServices.add(service)
                          : selectedServices.remove(service);
                    });
                  },
                );
              }).toList(),
            ),
          ),

          /// 🔹 STEP 2: PERSONAL DETAILS
          Step(
            title: Text("Personal Details"),
            isActive: currentStep >= 1,
            content: _buildCard(
              children: [
                _buildTextField(ownerController, "Owner Name", Icons.person),
                _buildTextField(businessController, config.businessLabel, Icons.business),
                _buildTextField(phoneController, "Phone", Icons.phone),
                _buildTextField(emailController, "Email", Icons.email),
                _buildTextField(addressController, "Address", Icons.location_on),
                Row(
                  children: [
                    Expanded(child: _buildTextField(cityController, "City", Icons.location_city)),
                    SizedBox(width: 10),
                    Expanded(child: _buildTextField(stateController, "State", Icons.map)),
                  ],
                ),
                _buildTextField(pincodeController, "Pincode", Icons.pin),

                if (config.hasHomeVisit)
                  SwitchListTile(
                    title: Text("Home Visit Available"),
                    value: homeVisit,
                    onChanged: (val) {
                      setState(() => homeVisit = val);
                    },
                  ),
              ],
            ),
          ),

          /// 🔹 STEP 3: BANK DETAILS
          Step(
            title: Text("Bank Details"),
            isActive: currentStep >= 2,
            content: _buildCard(
              children: [
                _buildTextField(bankHolderController, "Account Holder Name", Icons.person),
                _buildTextField(accountController, "Account Number", Icons.account_balance),
                _buildTextField(ifscController, "IFSC Code", Icons.code),
                _buildTextField(upiController, "UPI ID (Optional)", Icons.payment),
              ],
            ),
          ),

          /// 🔹 STEP 4: DOCUMENTS
          Step(
            title: Text("Documents"),
            isActive: currentStep >= 3,
            content: _buildCard(
              children: [
                _buildTextField(aadharController, "Aadhar Number", Icons.credit_card),
                _buildTextField(panController, "PAN Number", Icons.badge),

                SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.upload_file),
                  label: Text("Upload Shop Certificate"),
                ),

                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.upload_file),
                  label: Text("Upload Service Certificate"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 CARD UI (Professional Look)
  Widget _buildCard({required List<Widget> children}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(top: 10),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(children: children),
      ),
    );
  }

  /// 🔹 REUSABLE TEXTFIELD
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