import 'dart:io';
import 'package:flutter/material.dart';

class HotelProvider extends ChangeNotifier {
  /// 🔹 STEP CONTROL
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

  void goToStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  /// 🔹 BASIC DETAILS
  String hotelName = "";
  String ownerName = "";
  String phone = "";
  String email = "";

  /// 🔹 LOCATION
  String address = "";
  String city = "";
  String state = "";
  String pincode = "";

  /// 🔹 HOTEL DETAILS
  int totalRooms = 0;
  int pricePerNight = 0;

  /// 🔹 ROOM TYPES
  Map<String, bool> roomTypes = {
    "Junior Suite": false,
    "Executive Suite": false,
    "Family Suite": false,
    "Deluxe Suite": false,
    "Mini Suite": false,
  };

  void toggleRoomType(String key) {
    roomTypes[key] = !(roomTypes[key] ?? false);
    notifyListeners();
  }

  List<String> get selectedRoomTypes =>
      roomTypes.entries.where((e) => e.value).map((e) => e.key).toList();

  /// 🔹 AMENITIES
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

  void toggleAmenity(String key) {
    amenities[key] = !(amenities[key] ?? false);
    notifyListeners();
  }

  List<String> get selectedAmenities =>
      amenities.entries.where((e) => e.value).map((e) => e.key).toList();

  /// 🔹 DOCUMENTS
  File? aadhaar;
  File? pan;
  File? gst;
  File? license;

  void setAadhaar(File file) {
    aadhaar = file;
    notifyListeners();
  }

  void setPan(File file) {
    pan = file;
    notifyListeners();
  }

  void setGst(File file) {
    gst = file;
    notifyListeners();
  }

  void setLicense(File file) {
    license = file;
    notifyListeners();
  }

  /// 🔹 HOTEL IMAGES
  List<File> hotelImages = [];

  void setHotelImages(List<File> images) {
    hotelImages = images;
    notifyListeners();
  }

  /// 🔹 FORM UPDATE METHODS
  void updateBasicDetails({
    required String hotel,
    required String owner,
    required String mobile,
    required String mail,
  }) {
    hotelName = hotel;
    ownerName = owner;
    phone = mobile;
    email = mail;
    notifyListeners();
  }

  void updateLocation({
    required String addr,
    required String c,
    required String s,
    required String pin,
  }) {
    address = addr;
    city = c;
    state = s;
    pincode = pin;
    notifyListeners();
  }

  void updateHotelDetails({
    required int rooms,
    required int price,
  }) {
    totalRooms = rooms;
    pricePerNight = price;
    notifyListeners();
  }

  /// 🔹 FINAL DATA (API READY)
  Map<String, dynamic> get hotelData => {
        "hotelName": hotelName,
        "ownerName": ownerName,
        "phone": phone,
        "email": email,
        "address": address,
        "city": city,
        "state": state,
        "pincode": pincode,
        "totalRooms": totalRooms,
        "pricePerNight": pricePerNight,
        "roomTypes": selectedRoomTypes,
        "amenities": selectedAmenities,
      };

  /// 🔹 RESET (AFTER SUBMIT)
  void reset() {
    _currentStep = 0;

    hotelName = "";
    ownerName = "";
    phone = "";
    email = "";

    address = "";
    city = "";
    state = "";
    pincode = "";

    totalRooms = 0;
    pricePerNight = 0;

    roomTypes.updateAll((key, value) => false);
    amenities.updateAll((key, value) => false);

    aadhaar = null;
    pan = null;
    gst = null;
    license = null;

    hotelImages.clear();

    notifyListeners();
  }
}
