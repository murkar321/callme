class CleaningService {
  final String name;
  final String category;
  final int price;
  final int discount;
  final int finalPrice;
  final String time;
  final String slogan;
  final String description;
  final List<String> includes;
  final List<String> excludes;
  final List<String> tools;
  final String warranty;

  CleaningService({
    required this.name,
    required this.category,
    required this.price,
    required this.discount,
    required this.finalPrice,
    required this.time,
    required this.slogan,
    required this.description,
    required this.includes,
    required this.excludes,
    required this.tools,
    required this.warranty,
  });
}

/// ✅ CATEGORIES
final List<String> cleaningCategories = [
  "Home Cleaning",
  "Kitchen Cleaning",
  "Bathroom Cleaning",
  "Sofa Cleaning",
  "Carpet Cleaning",
  "Window Cleaning",
];

/// ✅ SERVICES LIST
final List<CleaningService> cleaningServices = [
  /// 🏠 HOME CLEANING
  CleaningService(
    name: "1 BHK Full Cleaning",
    category: "Home Cleaning",
    price: 999,
    discount: 20,
    finalPrice: 799,
    time: "2–3 Hours",
    slogan: "Complete cleaning for small homes",
    description:
        "Complete cleaning solution for small homes with proper dust removal and hygiene care.",
    includes: [
      "Floor sweeping & mopping",
      "Furniture dusting",
      "Kitchen surface cleaning",
      "Bathroom cleaning",
      "Cobweb removal"
    ],
    excludes: ["Chimney deep cleaning", "Sofa shampooing", "Wall washing"],
    tools: ["Vacuum cleaner", "Microfiber cloth", "Mop", "Disinfectant"],
    warranty: "24 Hours re-clean support",
  ),

  CleaningService(
    name: "2 BHK Full Cleaning",
    category: "Home Cleaning",
    price: 1499,
    discount: 20,
    finalPrice: 1199,
    time: "3–4 Hours",
    slogan: "Perfect cleaning for medium homes",
    description:
        "Ideal for medium homes with detailed cleaning of all rooms and common areas.",
    includes: [
      "Full house cleaning",
      "Kitchen & bathroom cleaning",
      "Dust removal from all surfaces"
    ],
    excludes: ["Appliance deep cleaning", "Wall stains removal"],
    tools: ["Vacuum", "Scrubber", "Cleaning liquids"],
    warranty: "24 Hours re-clean support",
  ),

  CleaningService(
    name: "3 BHK Full Cleaning",
    category: "Home Cleaning",
    price: 1999,
    discount: 25,
    finalPrice: 1499,
    time: "4–5 Hours",
    slogan: "Deep cleaning for large homes",
    description:
        "Deep and detailed cleaning for large homes ensuring every corner is covered.",
    includes: [
      "Complete house cleaning",
      "Deep dusting",
      "Mopping",
      "Bathroom & kitchen cleaning"
    ],
    excludes: ["Curtain washing", "Paint cleaning"],
    tools: ["High power vacuum", "Professional cleaning agents"],
    warranty: "24 Hours re-clean support",
  ),

  CleaningService(
    name: "Living Room Cleaning",
    category: "Home Cleaning",
    price: 399,
    discount: 10,
    finalPrice: 359,
    time: "60 minutes",
    slogan: "Fresh and dust free living space",
    description:
        "Focused cleaning of your living space to maintain freshness and hygiene.",
    includes: [
      "Sofa dusting",
      "Table cleaning",
      "TV unit cleaning",
      "Floor mopping"
    ],
    excludes: ["Sofa shampoo cleaning"],
    tools: ["Cloth", "Vacuum"],
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "Bedroom Cleaning",
    category: "Home Cleaning",
    price: 349,
    discount: 10,
    finalPrice: 314,
    time: "45 minutes",
    slogan: "Clean and relaxing bedroom",
    description:
        "Clean and relaxing bedroom environment with proper dust removal.",
    includes: ["Bed area cleaning", "Furniture dusting", "Floor cleaning"],
    excludes: ["Mattress deep cleaning"],
    tools: ["Mop", "Duster"],
    warranty: "12 Hours support",
  ),

  /// 🍳 KITCHEN CLEANING
  CleaningService(
    name: "Basic Kitchen Cleaning",
    category: "Kitchen Cleaning",
    price: 499,
    discount: 10,
    finalPrice: 449,
    time: "60 minutes",
    slogan: "Quick kitchen refresh",
    description: "Quick cleaning for daily kitchen maintenance.",
    includes: ["Slab cleaning", "Sink wash", "Basic surface cleaning"],
    excludes: ["Chimney interior", "Cabinet inside cleaning"],
    tools: ["Scrubber", "Liquid cleaner"],
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "Deep Kitchen Cleaning",
    category: "Kitchen Cleaning",
    price: 1199,
    discount: 20,
    finalPrice: 959,
    time: "2–3 Hours",
    slogan: "Remove grease and tough stains",
    description: "Complete grease and stain removal for a hygienic kitchen.",
    includes: [
      "Grease removal",
      "Slab cleaning",
      "Tiles cleaning",
      "Cabinet exterior cleaning"
    ],
    excludes: ["Appliance repair"],
    tools: ["Degreaser", "Scrub machine"],
    warranty: "24 Hours support",
  ),

  /// 🚿 BATHROOM CLEANING
  CleaningService(
    name: "Basic Bathroom Cleaning",
    category: "Bathroom Cleaning",
    price: 399,
    discount: 10,
    finalPrice: 359,
    time: "45 minutes",
    slogan: "Quick bathroom refresh",
    description: "Regular cleaning to maintain hygiene.",
    includes: ["Toilet", "Sink", "Mirror", "Floor cleaning"],
    excludes: ["Hard stain removal"],
    tools: ["Brush", "Disinfectant"],
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "Deep Bathroom Cleaning",
    category: "Bathroom Cleaning",
    price: 799,
    discount: 15,
    finalPrice: 679,
    time: "90 minutes",
    slogan: "Remove stains and bacteria",
    description: "Removes tough stains and bacteria for deep hygiene.",
    includes: ["Tile scrubbing", "Stain removal", "Full sanitization"],
    excludes: ["Plumbing services"],
    tools: ["Acid solution", "Scrubber"],
    warranty: "24 Hours support",
  ),

  /// 🛋️ SOFA CLEANING
  CleaningService(
    name: "Fabric Sofa Cleaning",
    category: "Sofa Cleaning",
    price: 599,
    discount: 15,
    finalPrice: 509,
    time: "60 minutes",
    slogan: "Fresh and dust free sofa",
    description: "Deep cleaning for fabric sofas.",
    includes: ["Dust removal", "Surface cleaning"],
    excludes: ["Tear repair"],
    tools: ["Vacuum", "Foam cleaner"],
    warranty: "12 Hours support",
  ),

  /// 🧼 ADD MORE SAME WAY...
];
