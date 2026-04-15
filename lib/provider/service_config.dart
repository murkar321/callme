class ServiceConfig {
  final String businessLabel;
  final List<String> serviceCategories;
  final List<String> amenities;
  final List<String> requiredDocuments;
  final bool showPricing;
  final bool showRoomCount;
  final bool showBankDetails;

  const ServiceConfig({
    required this.businessLabel,
    this.serviceCategories = const [],
    this.amenities = const [],
    this.requiredDocuments = const [],
    this.showPricing = true,
    this.showRoomCount = false,
    this.showBankDetails = true,
  });
}

final Map<String, ServiceConfig> serviceConfigs = {
  "salon": ServiceConfig(
    businessLabel: "Salon Name",
    serviceCategories: [
      "Haircut",
      "Facial",
      "Makeup",
      "Bridal Makeup",
      "Hair Spa",
      "Home Visit",
    ],
    requiredDocuments: [
      "Aadhaar Card",
      "PAN Card",
      "Shop License",
      "Salon Photos",
    ],
  ),

  "cleaning": ServiceConfig(
    businessLabel: "Cleaning Business Name",
    serviceCategories: [
      "Home Cleaning",
      "Office Cleaning",
      "Bathroom Cleaning",
      "Kitchen Cleaning",
      "Deep Cleaning",
    ],
    requiredDocuments: [
      "Aadhaar Card",
      "PAN Card",
      "Business Proof",
    ],
  ),

  "plumbing": ServiceConfig(
    businessLabel: "Plumbing Business Name",
    serviceCategories: [
      "Pipe Repair",
      "Leakage Repair",
      "Tap Fitting",
      "Bathroom Plumbing",
      "Water Tank Work",
    ],
    requiredDocuments: [
      "Aadhaar Card",
      "PAN Card",
      "Trade Certificate",
    ],
  ),

  "hotel": ServiceConfig(
    businessLabel: "Hotel Name",
    serviceCategories: [
      "Junior Suite",
      "Executive Suite",
      "Family Suite",
      "Deluxe Suite",
      "Mini Suite",
    ],
    amenities: [
      "Free WiFi",
      "Air Conditioning",
      "Parking",
      "Room Service",
      "Restaurant",
      "Breakfast",
      "Laundry",
      "Power Backup",
    ],
    requiredDocuments: [
      "Aadhaar Card",
      "PAN Card",
      "GST",
      "Trade License",
      "Hotel Photos",
    ],
    showRoomCount: true,
  ),

  "resort": ServiceConfig(
    businessLabel: "Resort Name",
    serviceCategories: [
      "Day Package",
      "Night Stay",
      "Wedding Event",
      "Corporate Event",
      "Family Stay",
    ],
    amenities: [
      "Swimming Pool",
      "Free WiFi",
      "Parking",
      "Garden Area",
      "Kids Play Area",
      "Rain Dance",
      "Event Hall",
      "Bar",
    ],
    requiredDocuments: [
      "Aadhaar Card",
      "PAN Card",
      "License",
      "Resort Photos",
    ],
    showRoomCount: true,
  ),

  "water": ServiceConfig(
    businessLabel: "Business Name",
    serviceCategories: [
      "Jar Exchange",
      "Brand Water",
      "Water Bottles",
      "Tanker Supply",
      "Ice Supply",
      "RO Installation",
      "Commercial Water",
    ],
    requiredDocuments: [
      "Aadhaar Card",
      "PAN Card",
      "Business License",
    ],
  ),

  "laundry": ServiceConfig(
    businessLabel: "Laundry Name",
    serviceCategories: [
      "Wash & Fold",
      "Dry Cleaning",
      "Ironing",
      "Home Pickup",
    ],
    requiredDocuments: [
      "Aadhaar Card",
      "PAN Card",
      "Shop License",
    ],
  ),

  "civil": ServiceConfig(
    businessLabel: "Construction Company Name",
    serviceCategories: [
      "New Build",
      "Renovation",
      "Painting",
      "Carpentry",
      "Electrical",
      "Plumbing",
    ],
    requiredDocuments: [
      "Aadhaar Card",
      "PAN Card",
      "GST",
      "Contractor License",
    ],
  ),
};