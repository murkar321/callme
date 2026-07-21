class ServiceConfig {
  final String businessLabel;
  final List<String> serviceCategories;
  final List<String> amenities;
  final List<String> requiredDocuments;
  final bool showPricing;
  final bool showRoomCount;

  // ✅ Controls whether the "Bank Details" step appears in
  // ServiceProviderForm. Set to false for enquiry-only categories
  // (no payouts happen through the app for these) — currently
  // Education and Civil.
  final bool showBankDetails;

  // ✅ NEW — Controls whether the "Service Preferences" step (the
  // "I have my own tools & equipment" toggle) appears in
  // ServiceProviderForm. Set to false for categories where a tools
  // toggle doesn't make sense — currently Education, Laundry, Hotel,
  // and Resort.
  final bool showToolsOption;

  // ============================================================

  // ============================================================
  final Map<String, List<String>> subServices;

  const ServiceConfig({
    required this.businessLabel,
    this.serviceCategories = const [],
    this.amenities = const [],
    this.requiredDocuments = const [],
    this.showPricing = true,
    this.showRoomCount = false,
    this.showBankDetails = true,
    this.showToolsOption = true,
    this.subServices = const {},
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
      "Mehandi",
      "Makeup",
      "Manicure",
      "Pedicure",
      "Waxing",

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
      "Home",
      "Corporate Office",
      "Bathroom",
      "Kitchen",
      "Deep",
      "Sofa",
      "Window",
      "Electronic",
      "Monthly Pakages",

    ],
    requiredDocuments: [
      "Aadhaar Card",
      "PAN Card",
      "Business Proof",
    ],
  ),

  // ✅ UPDATED — Education is enquiry-only: no bank payouts, and no
  // tools toggle (doesn't apply to an educational institution).
  "education": ServiceConfig(
    businessLabel: "Educational Institution Name",
    serviceCategories: [
      "Academic Coaching",
      "Aviation Training",
      "Beautician Courses",
      "Dance Classes",
      "Music Lessons",
      "English Speaking Classes",
      "Data Science Courses",
      "Software And Programming",
      "Government Exam Coaching",
      "Networking Courses",
      "Paramedical courses",
      "Technical Training",
      "Digital Marketing Courses",
      "Graphic and video Editing Courses",
      "MSC-IT Courses",

    ],
    requiredDocuments: [
      "Aadhaar Card",
      "PAN Card",
      "Institution License",
      "Educator Certificates",
    ],
    showBankDetails: false,
    showToolsOption: false,
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

  // ✅ UPDATED — Hotel: tools toggle removed (not relevant to hotels).
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
    showToolsOption: false,
  ),

  // ✅ UPDATED — amenities catalog added. This is the full pool of
  // facilities a resort provider can register against (checked at
  // onboarding). Each provider's `business.amenities` (or whatever field
  // ServiceProviderForm writes) should be a subset of this list. The
  // ResortBookingPage now reads the *specific* facilities registered
  // against the resort (via resorts_data.dart's `facilities`) and lets
  // the customer choose which of those they want for their visit.
  //
  // Also: tools toggle removed (not relevant to resorts).
  "resort": ServiceConfig(
    businessLabel: "Resort Name",
    serviceCategories: [
      "Anand Resort",
      "Alexon Resort",
    ],
    amenities: [
      "Swimming Pool",
      "Water Park",
      "Wedding / Banquet Hall",
      "Conference Hall",
      "Restaurant & Bar",
      "Fitness Center",
      "Natural Waterfall",
      "DJ / Rain Dance Floor",
      "A/C Rooms",
      "Free Parking",
      "Kids Play Area",
      "Beach Access",
    ],
    requiredDocuments: [
      "Aadhaar Card",
      "PAN Card",
      "License",
      "Resort Photos",
    ],
    showRoomCount: true,
    showToolsOption: false,
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

  // ✅ UPDATED — Laundry: tools toggle removed.
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
    showToolsOption: false,
  ),

  // ✅ UPDATED — Civil is enquiry-only: no bank payouts. Tools toggle
  // is kept (civil work commonly involves provider-owned tools).
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
    subServices: {
  "Renovation": ["Kitchen Renovation", "Bathroom Renovation", "Full House Renovation"],
  "Painting": ["Interior Painting", "Exterior Painting"],
  "Electrical": ["Wiring", "Lighting Installation", "Panel Upgrade"],
  "Plumbing": ["Pipe Fitting", "Bathroom Plumbing Setup"],
},
    requiredDocuments: [
      "Aadhaar Card",
      "PAN Card",
      "GST",
      "Contractor License",
    ],
    showBankDetails: false,

  ),
};