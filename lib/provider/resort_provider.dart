import 'package:flutter/material.dart';

class ResortProvider extends ChangeNotifier {
  /// 🔹 STEP CONTROL (for multi-screen flow)
  int _currentStep = 0;
  int get currentStep => _currentStep;

  void nextStep() {
    _currentStep++;
    notifyListeners();
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void setStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  // =========================================================
  // 🔹 1. FACILITIES SELECTION
  // =========================================================

  final List<String> _allFacilities = [
    'Swimming Pool',
    'Free WiFi',
    'Parking',
    'Pick & Drop Service',
    'A/C & Non A/C Rooms',
    'Garden Area',
    'Kids Play Area',
    'Event Hall',
    'Water Slides',
    'Rain Dance',
    'Veg & Non Veg Food',
    'Bar',
  ];

  List<String> get allFacilities => _allFacilities;

  final List<String> _selectedFacilities = [];
  List<String> get selectedFacilities => _selectedFacilities;

  void toggleFacility(String facility) {
    if (_selectedFacilities.contains(facility)) {
      _selectedFacilities.remove(facility);
    } else {
      _selectedFacilities.add(facility);
    }
    notifyListeners();
  }

  bool isSelected(String facility) {
    return _selectedFacilities.contains(facility);
  }

  // =========================================================
  // 🔹 2. PERSONAL DETAILS
  // =========================================================

  String resortName = '';
  String ownerName = '';
  String contactNumber = '';
  String email = '';
  String address = '';
  String city = '';
  String state = '';
  String pinCode = '';

  void updatePersonalDetails({
    String? rName,
    String? oName,
    String? phone,
    String? mail,
    String? addr,
    String? c,
    String? s,
    String? pin,
  }) {
    resortName = rName ?? resortName;
    ownerName = oName ?? ownerName;
    contactNumber = phone ?? contactNumber;
    email = mail ?? email;
    address = addr ?? address;
    city = c ?? city;
    state = s ?? state;
    pinCode = pin ?? pinCode;

    notifyListeners();
  }

  // =========================================================
  // 🔹 3. BANK DETAILS
  // =========================================================

  String accountHolderName = '';
  String bankName = '';
  String accountNumber = '';
  String ifscCode = '';
  String branchName = '';
  String upiId = '';

  void updateBankDetails({
    String? holder,
    String? bank,
    String? accNo,
    String? ifsc,
    String? branch,
    String? upi,
  }) {
    accountHolderName = holder ?? accountHolderName;
    bankName = bank ?? bankName;
    accountNumber = accNo ?? accountNumber;
    ifscCode = ifsc ?? ifscCode;
    branchName = branch ?? branchName;
    upiId = upi ?? upiId;

    notifyListeners();
  }

  // =========================================================
  // 🔹 4. UPLOAD SECTION
  // =========================================================

  String? resortImage;
  String? roomImage;
  String? resortLicense;
  String? document;

  void setResortImage(String path) {
    resortImage = path;
    notifyListeners();
  }

  void setRoomImage(String path) {
    roomImage = path;
    notifyListeners();
  }

  void setResortLicense(String path) {
    resortLicense = path;
    notifyListeners();
  }

  void setDocument(String path) {
    document = path;
    notifyListeners();
  }

  // =========================================================
  // 🔹 FINAL SUBMIT (COLLECT ALL DATA)
  // =========================================================

  Map<String, dynamic> submitData() {
    return {
      "facilities": _selectedFacilities,
      "personalDetails": {
        "resortName": resortName,
        "ownerName": ownerName,
        "contact": contactNumber,
        "email": email,
        "address": address,
        "city": city,
        "state": state,
        "pinCode": pinCode,
      },
      "bankDetails": {
        "accountHolder": accountHolderName,
        "bankName": bankName,
        "accountNumber": accountNumber,
        "ifsc": ifscCode,
        "branch": branchName,
        "upi": upiId,
      },
      "uploads": {
        "resortImage": resortImage,
        "roomImage": roomImage,
        "license": resortLicense,
        "document": document,
      }
    };
  }

  // OPTIONAL RESET
  void reset() {
    _currentStep = 0;
    _selectedFacilities.clear();

    resortName = '';
    ownerName = '';
    contactNumber = '';
    email = '';
    address = '';
    city = '';
    state = '';
    pinCode = '';

    accountHolderName = '';
    bankName = '';
    accountNumber = '';
    ifscCode = '';
    branchName = '';
    upiId = '';

    resortImage = null;
    roomImage = null;
    resortLicense = null;
    document = null;

    notifyListeners();
  }
}
