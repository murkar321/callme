// lib/real_estate_interactive_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RealEstateInteractivePage extends StatefulWidget {
  const RealEstateInteractivePage({super.key});

  @override
  State<RealEstateInteractivePage> createState() =>
      _RealEstateInteractivePageState();
}

class _RealEstateInteractivePageState extends State<RealEstateInteractivePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Step & selections
  int _step = 0;
  String? _selectedCategory;
  String? _selectedPropertyType;
  String? _selectedGender;
  RangeValues _priceRange = const RangeValues(1000, 50000);

  final List<String> categories = [
    'House/Villa',
    'Plots & Land',
    'Commercial & Offices',
    'Store',
    'Apartment/Flat'
  ];

  final Map<String, List<String>> propertyOptions = {
    'House/Villa': ['1BHK', '2BHK', '3BHK'],
    'Plots & Land': ['0.85 Acres', '1.10 Acres', '2.00 Acres'],
    'Commercial & Offices': ['50-100 Sq ft', '100-200 Sq ft', '200-400 Sq ft'],
    'Store': ['50 - 100 Sq ft', '100 - 200 Sq ft', '200 - 400 Sq ft'],
    'Apartment/Flat': ['1RK', '1BHK', '2BHK'],
  };

  // Image upload
  final ImagePicker _picker = ImagePicker();
  final List<File> _pickedImages = [];

  // Personal details
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _aadhar = TextEditingController();
  final TextEditingController _pan = TextEditingController();
  final TextEditingController _propertyAddress = TextEditingController();
  final TextEditingController _personalAddress = TextEditingController();
  final TextEditingController _contact = TextEditingController();
  final TextEditingController _email = TextEditingController();

  final Color primaryPurple = const Color(0xFF6F3E9B);

  // Animation
  late final AnimationController _animController;
  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _animController.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _aadhar.dispose();
    _pan.dispose();
    _propertyAddress.dispose();
    _personalAddress.dispose();
    _contact.dispose();
    _email.dispose();
    super.dispose();
  }

  // --- Image Picker ---
  Future<void> _pickImage(ImageSource src) async {
    try {
      final XFile? picked = await _picker.pickImage(source: src, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _pickedImages.add(File(picked.path));
        });
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  void _removeImageAt(int index) {
    setState(() => _pickedImages.removeAt(index));
  }

  // --- Step Controls ---
  void _nextStep() {
    setState(() => _step = (_step + 1).clamp(0, 5));
  }

  void _previousStep() {
    setState(() => _step = (_step - 1).clamp(0, 5));
  }

  void _confirmDetails() {
    if ((_formKey.currentState?.validate() ?? false) && _selectedGender != null) {
      setState(() {
        _step = 5; // go to final confirmation screen
      });
    } else if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a gender.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all personal details.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Real Estate Interactive Form'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Material(
                  color: Colors.white,
                  elevation: 6,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, anim) {
                            return FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.1),
                                      end: Offset.zero,
                                    ).animate(anim),
                                    child: child));
                          },
                          child: _buildStepBody(key: ValueKey<int>(_step), screen: screen),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            if (_step > 0 && _step < 5)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _previousStep,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: primaryPurple.withOpacity(0.6)),
                                  ),
                                  child: const Text("Back"),
                                ),
                              )
                            else
                              const Spacer(),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_step < 4) {
                                    _nextStep();
                                  } else if (_step == 4) {
                                    _confirmDetails();
                                  } else if (_step == 5) {
                                    Navigator.pop(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryPurple,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(_step < 4
                                    ? "Next"
                                    : _step == 4
                                        ? "Confirm"
                                        : "Close"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildStepIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Step body builder ---
  Widget _buildStepBody({required Key key, required Size screen}) {
    switch (_step) {
      case 0:
        return _buildCategoryStep(key);
      case 1:
        return _buildTypeStep(key);
      case 2:
        return _buildPriceStep(key);
      case 3:
        return _buildUploadStep(key);
      case 4:
        return _buildDetailsStep(key);
      case 5:
      default:
        return _buildSummaryStep(key);
    }
  }

  // --- Step 0: Category Selection ---
  Widget _buildCategoryStep(Key key) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Category",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: categories.map((cat) {
            final selected = cat == _selectedCategory;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                  _selectedPropertyType = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 150,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: selected ? primaryPurple : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    cat,
                    style: TextStyle(
                        color: selected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- Step 1: Property Type Selection ---
  Widget _buildTypeStep(Key key) {
    final options = propertyOptions[_selectedCategory] ?? [];
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedCategory == null
              ? 'Please select a category first'
              : 'Select ${_selectedCategory!} Type',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_selectedCategory != null)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((opt) {
              final selected = opt == _selectedPropertyType;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedPropertyType = opt);
                },
                child: Container(
                  width: 100,
                  height: 70,
                  decoration: BoxDecoration(
                    color: selected ? primaryPurple : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(opt,
                        style: TextStyle(
                            color: selected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('For More options coming soon...')),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: primaryPurple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
                child: Text("For More",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
          ),
        ),
      ],
    );
  }

  // --- Step 2: Price Range ---
  Widget _buildPriceStep(Key key) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Set Price Range",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          "Selected Range: ₹${_priceRange.start.round()} - ₹${_priceRange.end.round()}",
          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 100000,
          divisions: 100,
          activeColor: primaryPurple,
          labels: RangeLabels(
            '₹${_priceRange.start.round()}',
            '₹${_priceRange.end.round()}',
          ),
          onChanged: (range) {
            setState(() => _priceRange = range);
          },
        ),
      ],
    );
  }

  // --- Step 3: Upload Photos ---
  Widget _buildUploadStep(Key key) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Upload Property Photos",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _uploadAction(Icons.camera_alt, 'Camera', () => _pickImage(ImageSource.camera)),
            _uploadAction(Icons.photo, 'Gallery', () => _pickImage(ImageSource.gallery)),
          ],
        ),
        const SizedBox(height: 10),
        if (_pickedImages.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('No images selected')),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pickedImages.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemBuilder: (context, i) => Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_pickedImages[i], fit: BoxFit.cover),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: InkWell(
                    onTap: () => _removeImageAt(i),
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // --- Step 4: Personal Details ---
  Widget _buildDetailsStep(Key key) {
    return Form(
      key: _formKey,
      child: Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Personal Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildTextField("First Name", _firstName),
          _buildTextField("Last Name", _lastName),
          const SizedBox(height: 8),
          const Text("Gender", style: TextStyle(fontWeight: FontWeight.w600)),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  value: "Male",
                  groupValue: _selectedGender,
                  title: const Text("Male"),
                  activeColor: primaryPurple,
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  value: "Female",
                  groupValue: _selectedGender,
                  title: const Text("Female"),
                  activeColor: primaryPurple,
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  value: "Other",
                  groupValue: _selectedGender,
                  title: const Text("Other"),
                  activeColor: primaryPurple,
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
              ),
            ],
          ),
          _buildTextField("Contact No.", _contact,
              keyboardType: TextInputType.phone),
          _buildTextField("Email ID", _email,
              keyboardType: TextInputType.emailAddress),
          _buildTextField("Aadhar Card", _aadhar,
              keyboardType: TextInputType.number),
          _buildTextField("Pan Card", _pan),
          _buildTextField("Property Address", _propertyAddress, maxLines: 2),
          _buildTextField("Personal Address", _personalAddress, maxLines: 2),
        ],
      ),
    );
  }

  // --- Step 5: Summary / Confirmation ---
  Widget _buildSummaryStep(Key key) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("✅ Summary",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _summaryTile("Category", _selectedCategory),
        _summaryTile("Property Type", _selectedPropertyType),
        _summaryTile("Price Range",
            "₹${_priceRange.start.round()} - ₹${_priceRange.end.round()}"),
        _summaryTile("Gender", _selectedGender),
        _summaryTile("Name", "${_firstName.text} ${_lastName.text}"),
        _summaryTile("Contact", _contact.text),
        _summaryTile("Email", _email.text),
        _summaryTile("Aadhar", _aadhar.text),
        _summaryTile("Pan", _pan.text),
        _summaryTile("Property Address", _propertyAddress.text),
        _summaryTile("Personal Address", _personalAddress.text),
        _summaryTile("Uploaded Photos", "${_pickedImages.length} selected"),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.done),
            label: const Text("Finish"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _uploadAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: primaryPurple.withOpacity(0.1),
            child: Icon(icon, color: primaryPurple, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: primaryPurple)),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (v) => v == null || v.isEmpty ? "Enter $label" : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _summaryTile(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text("$title:",
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
              flex: 5,
              child: Text(value ?? "-",
                  style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final labels = ['Category', 'Type', 'Price', 'Photos', 'Details', 'Summary'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(labels.length, (i) {
        final active = i == _step;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 36 : 12,
            height: 12,
            decoration: BoxDecoration(
              color: active ? primaryPurple : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }),
    );
  }
}
