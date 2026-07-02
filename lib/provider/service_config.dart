class ServiceConfig {
  final String businessLabel;
  final List<String> serviceCategories;
  final List<String> amenities;
  final List<String> requiredDocuments;
  final bool showPricing;
  final bool showRoomCount;
  final bool showBankDetails;

  // ============================================================
  // NEW: SUB-SERVICE → CATEGORY MAP
  //
  // `serviceCategories` above is the BROAD list a provider picks
  // from at registration (e.g. "Jar Exchange/Return", "New Build").
  // Booking pages, however, often let a customer book a much more
  // SPECIFIC item within one of those categories — e.g. under the
  // "Jar Exchange / Return" sidebar tab, the actual bookable cards
  // are "20L Water Jar Exchange" and "Empty Jar Return Pickup"; under
  // the civil "New Build" tab, the cards are "Residential House
  // Construction", "Commercial Building Construction", etc.
  //
  // When an order is placed for one of those specific items, the
  // `category`/`services` values booking pages send are the SPECIFIC
  // item name, not the broad category — and a specific item name like
  // "Residential House Construction" shares literally no words with
  // "New Build", so plain word-overlap fuzzy matching (see
  // categoryMatchFuzzy() in order_service.dart) cannot bridge the two
  // and the order silently never matches any provider.
  //
  // `subServices` fixes this: it's a map of
  //   canonical category name -> [specific bookable item names]
  // `parentCategoryForSubService()` in order_service.dart uses this to
  // resolve a specific item straight back to its parent category, both
  // when an order is first placed (resolveCanonicalCategory()) AND at
  // match time for orders that were already stored with the raw item
  // name (categoryMatchFuzzy()'s Stage 3).
  //
  // ⚠️ IMPORTANT: this is only populated for the categories/items
  // confirmed from actual booking-page screenshots so far (water's
  // "Jar Exchange/Return" and civil's "New Build"). Add entries here
  // as you audit each booking page's card titles — an empty/missing
  // list just means that category falls back to plain fuzzy word
  // matching, which still works fine when item names happen to share
  // a word with the category (e.g. "Pipe Repair" booking items).
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
      "Corporate Office Cleaning",
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
    // Confirmed from the "Jar Exchange / Return" booking-page tab —
    // add the other tabs' card titles here as you audit them.
    subServices: {
      "Jar Exchange/Return": [
        "20L Water Jar Exchange",
        "Empty Jar Return Pickup",
      ],
    },
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
    // Confirmed from the "New Build" booking-page tab — add the
    // other tabs' (Renovation, Painting, etc.) card titles here as
    // you audit them.
    subServices: {
      "New Build": [
        "Residential House Construction",
        "Commercial Building Construction",
        "Bungalow / Villa Construction",
        "Apartment / Flat Construction",
        "Toilet Construction",
      ],
      "Renovation": [
        "Basic Package",
        "Standard Package",
        "Premium Pacakage",
      ],
    },
  ),
};