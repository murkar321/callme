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
      "Hair Styling",
      "Hair Treatments",
      "Hair Color",
      "Facial",
      "Makeup",
      "Manicure",
      "Pedicure",
      "Waxing",
      "Mehandi",
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
      " Corporate Office Cleaning",
      "Bathroom Cleaning",
      "Kitchen Cleaning",
      "Deep Cleaning",
      "Sofa Cleaning",
      "Window Cleaning",
      "Electronic Cleaning",
      "Monthly Packages",

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
      "Tap Installation",
      "Drain Cleaning",
      "Toilet Repair",
      "Sink Installation",
      "Bathroom Repair",
      "Water Tank Installation",
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
      "Jar Exchange/Return",
      "Aqua Installation",
      "Brand Water",
      "Water Bottles",
      "Tanker Supply",
      "Ice Supply",
      "Commercial Water Services",
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
      "Washing",
      "Dry Cleaning",
      "Ironing",
      "Curtain Cleaning",
      "Shoe Cleaning",
      "BedSheet Cleaning",
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
      "Carpentry/Fabrication",
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