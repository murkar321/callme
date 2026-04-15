import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/resort_provider.dart';

class ResortProviderPage extends StatelessWidget {
  const ResortProviderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ResortProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Resort"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔹 STEP INDICATOR
            Text(
              "Step ${provider.currentStep + 1}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 STEP UI SWITCH
            Expanded(
              child: _buildStepUI(provider),
            ),

            /// 🔹 BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (provider.currentStep > 0)
                  ElevatedButton(
                    onPressed: provider.previousStep,
                    child: const Text("Back"),
                  ),
                ElevatedButton(
                  onPressed: () {
                    if (provider.currentStep < 3) {
                      provider.nextStep();
                    } else {
                      final data = provider.submitData();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Submitted Successfully")),
                      );

                      print(data); // 🔥 all data here
                    }
                  },
                  child: Text(
                    provider.currentStep < 3 ? "Next" : "Submit",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 STEP UI BUILDER
  Widget _buildStepUI(ResortProvider provider) {
    switch (provider.currentStep) {
      /// STEP 1 → FACILITIES
      case 0:
        return ListView(
          children: provider.allFacilities.map((facility) {
            return CheckboxListTile(
              title: Text(facility),
              value: provider.isSelected(facility),
              onChanged: (_) => provider.toggleFacility(facility),
            );
          }).toList(),
        );

      /// STEP 2 → PERSONAL DETAILS
      case 1:
        return Column(
          children: [
            _field("Resort Name", (v) => provider.resortName = v),
            _field("Owner Name", (v) => provider.ownerName = v),
            _field("Phone", (v) => provider.contactNumber = v),
            _field("Email", (v) => provider.email = v),
          ],
        );

      /// STEP 3 → BANK DETAILS
      case 2:
        return Column(
          children: [
            _field("Account Holder", (v) => provider.accountHolderName = v),
            _field("Bank Name", (v) => provider.bankName = v),
            _field("Account Number", (v) => provider.accountNumber = v),
            _field("IFSC Code", (v) => provider.ifscCode = v),
          ],
        );

      /// STEP 4 → FINAL
      case 3:
        return const Center(
          child: Text("Ready to Submit 🚀"),
        );

      default:
        return const SizedBox();
    }
  }

  /// 🔹 COMMON TEXTFIELD
  Widget _field(String label, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
