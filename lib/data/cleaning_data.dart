
class CleaningService {
  final String name;
  final String image;
  final String description;

  final List<String> includes;
  final List<String> excludes;
  final List<String> steps;

  final String tools;
  final String time;

  final int price;
  final int discount;
  final int finalPrice;

  final String warranty;

  CleaningService({
    required this.name,
    required this.image,
    required this.description,
    required this.includes,
    required this.excludes,
    required this.steps,
    required this.tools,
    required this.time,
    required this.price,
    required this.discount,
    required this.finalPrice,
    required this.warranty,
  });
}


Map<String, List<CleaningService>> cleaningServices = {
  /// 🏠 HOME CLEANING
"Home Cleaning": [

  CleaningService(
    name: "1 BHK Full Cleaning",
    image: "assets/clean.jfif",
    description: "Complete cleaning for small homes",
    includes: [
      "Living room cleaning",
      "Bedroom cleaning",
      "Kitchen basic cleaning",
      "Bathroom cleaning",
      "Dusting and mopping"
    ],
    excludes: [
      "Deep cleaning",
      "Repair work"
    ],
    steps: [
      "Dusting",
      "Floor cleaning",
      "Surface cleaning",
      "Final finishing"
    ],
    tools: "Vacuum, mop, cleaning chemicals",
    time: "2–3 Hours",
    price: 999,
    discount: 20,
    finalPrice: 799,
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "2 BHK Full Cleaning",
    image: "assets/hc4.jpg",
    description: "Perfect cleaning for medium homes",
    includes: [
      "2 bedrooms cleaning",
      "Living room cleaning",
      "Kitchen cleaning",
      "Bathroom cleaning",
      "Dusting and mopping"
    ],
    excludes: [
      "Deep cleaning",
      "Repair work"
    ],
    steps: [
      "Dusting",
      "Mopping",
      "Surface cleaning",
      "Final finish"
    ],
    tools: "Vacuum & cleaning kit",
    time: "3–4 Hours",
    price: 1499,
    discount: 20,
    finalPrice: 1199,
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "3 BHK Full Cleaning",
    image: "assets/hc3.jpg",
    description: "Deep cleaning for large homes",
    includes: [
      "3 bedrooms cleaning",
      "Living room cleaning",
      "Kitchen cleaning",
      "Bathrooms cleaning",
      "Dusting and mopping"
    ],
    excludes: [
      "Repair work"
    ],
    steps: [
      "Inspection",
      "Cleaning",
      "Sanitization",
      "Final finishing"
    ],
    tools: "Professional cleaning kit",
    time: "4–5 Hours",
    price: 1999,
    discount: 25,
    finalPrice: 1499,
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "Living Room Cleaning",
    image: "assets/Living Room Cleaning.jfif",
    description: "Fresh and dust free living space",
    includes: [
      "Dusting",
      "Floor cleaning",
      "Furniture cleaning",
      "Surface cleaning"
    ],
    excludes: [
      "Sofa shampoo cleaning"
    ],
    steps: [
      "Dust removal",
      "Surface cleaning",
      "Floor mopping"
    ],
    tools: "Vacuum & mop",
    time: "60 Minutes",
    price: 399,
    discount: 10,
    finalPrice: 359,
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "Bedroom Cleaning",
    image: "assets/bedroom_cleaning.jfif",
    description: "Clean and relaxing bedroom",
    includes: [
      "Dusting",
      "Floor cleaning",
      "Bed area cleaning",
      "Surface cleaning"
    ],
    excludes: [
      "Mattress deep cleaning"
    ],
    steps: [
      "Dusting",
      "Surface cleaning",
      "Mopping"
    ],
    tools: "Cleaning kit",
    time: "45 Minutes",
    price: 349,
    discount: 10,
    finalPrice: 314,
    warranty: "12 Hours support",
  ),

],
/// 🍳 KITCHEN CLEANING
"Kitchen Cleaning": [

  CleaningService(
    name: "Basic Kitchen Cleaning",
    image: "assets/basic_kitchen_cleaning.jfif",
    description: "Quick kitchen refresh",
    includes: [
      "Platform cleaning",
      "Sink cleaning",
      "Floor cleaning",
      "Surface dust removal"
    ],
    excludes: [
      "Deep grease removal"
    ],
    steps: [
      "Clean platform",
      "Wash sink",
      "Mop floor"
    ],
    tools: "Cleaning liquid & cloth",
    time: "60 Minutes",
    price: 499,
    discount: 10,
    finalPrice: 449,
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "Deep Kitchen Cleaning",
    image: "assets/kitchen_deep_cleaning.jfif",
    description: "Remove grease and tough stains",
    includes: [
      "Platform deep cleaning",
      "Cabinet exterior cleaning",
      "Sink and tiles cleaning",
      "Grease removal"
    ],
    excludes: [
      "Appliance repair"
    ],
    steps: [
      "Remove grease",
      "Scrub surfaces",
      "Sanitize kitchen"
    ],
    tools: "Degreaser & scrubber",
    time: "2–3 Hours",
    price: 1199,
    discount: 20,
    finalPrice: 959,
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "Chimney Cleaning",
    image: "assets/chimney_cleaning.jfif",
    description: "Smoke free kitchen experience",
    includes: [
      "Filter cleaning",
      "Oil removal",
      "Surface cleaning"
    ],
    excludes: [
      "Motor repair"
    ],
    steps: [
      "Remove filters",
      "Clean oil",
      "Reassemble"
    ],
    tools: "Chimney cleaning kit",
    time: "60 Minutes",
    price: 599,
    discount: 15,
    finalPrice: 509,
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "Stove Cleaning",
    image: "assets/stove_cleaning.jfif",
    description: "Sparkling clean stove",
    includes: [
      "Burner cleaning",
      "Surface cleaning",
      "Oil removal"
    ],
    excludes: [
      "Gas repair"
    ],
    steps: [
      "Remove burners",
      "Clean stove",
      "Finish"
    ],
    tools: "Cleaning solution",
    time: "30 Minutes",
    price: 299,
    discount: 10,
    finalPrice: 269,
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "Kitchen Cabinet Cleaning",
    image: "assets/Kitchen Cleaning.jpg",
    description: "Clean and organized cabinets",
    includes: [
      "Cabinet exterior cleaning",
      "Dust removal",
      "Surface cleaning"
    ],
    excludes: [
      "Cabinet repair"
    ],
    steps: [
      "Dust removal",
      "Surface cleaning",
      "Finish"
    ],
    tools: "Cloth & spray",
    time: "45 Minutes",
    price: 399,
    discount: 10,
    finalPrice: 359,
    warranty: "12 Hours support",
  ),

],

  /// 🚿 BATHROOM CLEANING
"Bathroom Cleaning": [

  CleaningService(
    name: "Basic Bathroom Cleaning",
    image: "assets/bc1.jpg",
    description: "Quick bathroom refresh",
    includes: [
      "Floor cleaning",
      "Wash basin cleaning",
      "Mirror cleaning",
      "Toilet cleaning"
    ],
    excludes: [
      "Hard stain removal",
      "Tile polishing"
    ],
    steps: [
      "Spray cleaner",
      "Scrub surfaces",
      "Wash and finish"
    ],
    tools: "Brush, disinfectant, gloves",
    time: "45 Minutes",
    price: 399,
    discount: 10,
    finalPrice: 359,
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "Deep Bathroom Cleaning",
    image: "assets/bathroom_deep_cleaning.jfif",
    description: "Remove stains and bacteria",
    includes: [
      "Tile cleaning",
      "Toilet cleaning",
      "Wash basin cleaning",
      "Hard stain removal",
      "Disinfection"
    ],
    excludes: [
      "Repair work"
    ],
    steps: [
      "Apply chemicals",
      "Scrub tiles",
      "Wash and disinfect"
    ],
    tools: "Scrubber machine & chemicals",
    time: "90 Minutes",
    price: 799,
    discount: 15,
    finalPrice: 679,
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "Toilet Cleaning",
    image: "assets/Toilet Cleaning.jpg",
    description: "Hygienic toilet cleaning",
    includes: [
      "Toilet seat cleaning",
      "Disinfection",
      "Odor removal"
    ],
    excludes: [
      "Bathroom full cleaning"
    ],
    steps: [
      "Apply cleaner",
      "Scrub toilet",
      "Sanitize"
    ],
    tools: "Toilet cleaner & brush",
    time: "30 Minutes",
    price: 299,
    discount: 10,
    finalPrice: 269,
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "Tile and Grout Cleaning",
    image: "assets/tile_grout_cleaning.jfif",
    description: "Shine your bathroom tiles",
    includes: [
      "Tile scrubbing",
      "Grout cleaning",
      "Surface wash"
    ],
    excludes: [
      "Tile repair"
    ],
    steps: [
      "Apply cleaner",
      "Scrub tiles",
      "Wash and finish"
    ],
    tools: "Scrubber & cleaning liquid",
    time: "60 Minutes",
    price: 499,
    discount: 10,
    finalPrice: 449,
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "Hard Water Stain Removal",
    image: "assets/hard_water_stain_removal.jfif",
    description: "Remove tough water stains",
    includes: [
      "Stain removal",
      "Glass cleaning",
      "Tile cleaning"
    ],
    excludes: [
      "Full bathroom deep cleaning"
    ],
    steps: [
      "Apply acid cleaner",
      "Scrub stains",
      "Wash and polish"
    ],
    tools: "Acid cleaner & scrubber",
    time: "60 Minutes",
    price: 599,
    discount: 15,
    finalPrice: 509,
    warranty: "12 Hours support",
  ),

],

/// 🛋 SOFA CLEANING
"Sofa Cleaning": [

  CleaningService(
    name: "Fabric Sofa Cleaning",
    image: "assets/sofac1.jpg",
    description: "Fresh and dust free sofa",
    includes: [
      "Vacuum cleaning",
      "Shampoo wash",
      "Dust removal",
      "Drying"
    ],
    excludes: [
      "Fabric repair"
    ],
    steps: [
      "Vacuum sofa",
      "Apply shampoo",
      "Dry and finish"
    ],
    tools: "Vacuum & shampoo machine",
    time: "60 Minutes",
    price: 599,
    discount: 15,
    finalPrice: 509,
    warranty: "24 Hours support",
  ),

  CleaningService(
    name: "Leather Sofa Cleaning",
    image: "assets/sofac.jpg",
    description: "Safe care for leather sofas",
    includes: [
      "Dust removal",
      "Leather cleaning",
      "Polishing"
    ],
    excludes: [
      "Leather repair"
    ],
    steps: [
      "Wipe leather",
      "Apply conditioner",
      "Polish finish"
    ],
    tools: "Leather cleaner & cloth",
    time: "60 Minutes",
    price: 699,
    discount: 15,
    finalPrice: 594,
    warranty: "24 Hours support",
  ),

  CleaningService(
    name: "L Shaped Sofa Cleaning",
    image: "assets/l_shaped_sofa.jfif",
    description: "Deep clean for large sofas",
    includes: [
      "Full sofa cleaning",
      "Shampoo wash",
      "Dust removal"
    ],
    excludes: [
      "Repair"
    ],
    steps: [
      "Vacuum",
      "Shampoo wash",
      "Dry and finish"
    ],
    tools: "Machine & shampoo solution",
    time: "90 Minutes",
    price: 999,
    discount: 20,
    finalPrice: 799,
    warranty: "24 Hours support",
  ),

  CleaningService(
    name: "Cushion Cleaning",
    image: "assets/cushion.jfif",
    description: "Clean and fresh cushions",
    includes: [
      "Dust removal",
      "Surface wash",
      "Drying"
    ],
    excludes: [
      "Fabric repair"
    ],
    steps: [
      "Vacuum",
      "Clean cushions",
      "Dry"
    ],
    tools: "Vacuum & brush",
    time: "30 Minutes",
    price: 299,
    discount: 10,
    finalPrice: 269,
    warranty: "24 Hours support",
  ),

  CleaningService(
    name: "Sofa Stain Removal",
    image: "assets/sofa_stain_removal.jfif",
    description: "Remove stubborn stains easily",
    includes: [
      "Spot cleaning",
      "Stain removal",
      "Surface cleaning"
    ],
    excludes: [
      "Full sofa shampooing"
    ],
    steps: [
      "Apply stain remover",
      "Scrub stain",
      "Finish"
    ],
    tools: "Stain remover & brush",
    time: "45 Minutes",
    price: 399,
    discount: 10,
    finalPrice: 359,
    warranty: "24 Hours support",
  ),

],

 /// 🧹 CARPET CLEANING
"Carpet Cleaning": [

  CleaningService(
    name: "Dry Carpet Cleaning",
    image: "assets/cc1.jpg",
    description: "Quick and effective cleaning",
    includes: [
      "Vacuum cleaning",
      "Dust removal",
      "Surface cleaning"
    ],
    excludes: [
      "Wet shampooing",
      "Repair"
    ],
    steps: [
      "Vacuum carpet",
      "Dust removal",
      "Final finishing"
    ],
    tools: "Vacuum cleaner & brush",
    time: "45 Minutes",
    price: 399,
    discount: 10,
    finalPrice: 359,
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "Wet Carpet Shampooing",
    image: "assets/Carpet cleaning.jpg",
    description: "Deep wash for carpets",
    includes: [
      "Shampoo wash",
      "Deep cleaning",
      "Odor removal"
    ],
    excludes: [
      "Carpet repair"
    ],
    steps: [
      "Apply shampoo",
      "Deep wash",
      "Dry and finish"
    ],
    tools: "Carpet shampoo machine",
    time: "60 Minutes",
    price: 599,
    discount: 15,
    finalPrice: 509,
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "Carpet Stain Removal",
    image: "assets/stain removal.jfif",
    description: "Remove tough stains",
    includes: [
      "Spot cleaning",
      "Stain removal",
      "Surface cleaning"
    ],
    excludes: [
      "Full carpet wash"
    ],
    steps: [
      "Apply stain remover",
      "Scrub stains",
      "Final cleaning"
    ],
    tools: "Stain remover & brush",
    time: "45 Minutes",
    price: 399,
    discount: 10,
    finalPrice: 359,
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "Dust and Allergen Removal",
    image: "assets/dust_allergen_carpet.jfif",
    description: "Healthy and dust free carpets",
    includes: [
      "Dust removal",
      "Allergen cleaning",
      "Vacuum cleaning"
    ],
    excludes: [
      "Wet wash"
    ],
    steps: [
      "Vacuum",
      "Remove allergens",
      "Finish"
    ],
    tools: "HEPA vacuum",
    time: "60 Minutes",
    price: 499,
    discount: 10,
    finalPrice: 449,
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "Rug Cleaning",
    image: "assets/rug cleaning.jfif",
    description: "Gentle cleaning for rugs",
    includes: [
      "Soft cleaning",
      "Dust removal",
      "Surface wash"
    ],
    excludes: [
      "Heavy carpet wash"
    ],
    steps: [
      "Dust removal",
      "Gentle cleaning",
      "Finish"
    ],
    tools: "Soft brush & vacuum",
    time: "45 Minutes",
    price: 349,
    discount: 10,
    finalPrice: 314,
    warranty: "12 Hours support",
  ),

],

/// 🪟 WINDOW CLEANING
"Window Cleaning": [

  CleaningService(
    name: "Glass Cleaning",
    image: "assets/window.jpg",
    description: "Crystal clear windows",
    includes: [
      "Glass cleaning",
      "Dust removal",
      "Streak-free polish"
    ],
    excludes: [
      "High-rise exterior work"
    ],
    steps: [
      "Spray cleaner",
      "Wipe glass",
      "Polish finish"
    ],
    tools: "Glass cleaner & microfiber",
    time: "30 Minutes",
    price: 299,
    discount: 10,
    finalPrice: 269,
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "Frame and Track Cleaning",
    image: "assets/frame_track_cleaning.jfif",
    description: "Clean frames and tracks",
    includes: [
      "Frame cleaning",
      "Track dust removal",
      "Surface cleaning"
    ],
    excludes: [
      "Window repair"
    ],
    steps: [
      "Remove dust",
      "Clean tracks",
      "Finish"
    ],
    tools: "Brush & cleaning spray",
    time: "45 Minutes",
    price: 399,
    discount: 10,
    finalPrice: 359,
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "Balcony and Sliding Window Cleaning",
    image: "assets/balcony_window_cleaning.jfif",
    description: "Clear balcony view",
    includes: [
      "Sliding window cleaning",
      "Balcony glass cleaning",
      "Dust removal"
    ],
    excludes: [
      "High-rise rope cleaning"
    ],
    steps: [
      "Clean glass",
      "Remove dust",
      "Polish"
    ],
    tools: "Glass cleaning kit",
    time: "60 Minutes",
    price: 499,
    discount: 10,
    finalPrice: 449,
    warranty: "12 Hours support",
  ),

  CleaningService(
    name: "Grill and Exterior Cleaning",
    image: "assets/grill_exterior_cleaning.jfif",
    description: "Clean grills and outer surfaces",
    includes: [
      "Grill cleaning",
      "Exterior dust removal",
      "Surface wash"
    ],
    excludes: [
      "Painting or repair"
    ],
    steps: [
      "Remove dust",
      "Clean grills",
      "Final finish"
    ],
    tools: "Brush & pressure spray",
    time: "60 Minutes",
    price: 599,
    discount: 15,
    finalPrice: 509,
    warranty: "12 Hours support",
  ),

],
   

  /// 🧽 DEEP CLEANING
"Deep Cleaning": [

  CleaningService(
    name: "Full Home Deep Cleaning",
    image: "assets/Full Home Deep Cleaning.jfif",
    description: "Complete home transformation",
    includes: [
      "All rooms deep cleaning",
      "Floor scrubbing and mopping",
      "Kitchen and bathroom deep cleaning",
      "Glass and window cleaning",
      "Dust and dirt removal"
    ],
    excludes: [
      "Repair work",
      "Painting",
      "Electrical work"
    ],
    steps: [
      "Home inspection",
      "Deep cleaning of all rooms",
      "Sanitization",
      "Final finishing"
    ],
    tools: "Industrial machines & cleaning chemicals",
    time: "4–6 Hours",
    price: 2499,
    discount: 25,
    finalPrice: 1874,
    warranty: "24 Hours support",
  ),

  CleaningService(
    name: "Kitchen Deep Cleaning",
    image: "assets/kitchen_deep_cleaning.jfif",
    description: "Remove grease completely",
    includes: [
      "Platform deep cleaning",
      "Chimney exterior cleaning",
      "Sink and tiles cleaning",
      "Cabinet exterior cleaning",
      "Grease removal"
    ],
    excludes: [
      "Chimney repair",
      "Gas pipeline repair"
    ],
    steps: [
      "Remove grease",
      "Clean surfaces",
      "Sanitize kitchen",
      "Final check"
    ],
    tools: "Degreaser & cleaning machines",
    time: "2–3 Hours",
    price: 1299,
    discount: 20,
    finalPrice: 1039,
    warranty: "24 Hours support",
  ),

  CleaningService(
    name: "Bathroom Deep Cleaning",
    image: "assets/bathroom_deep_cleaning.jfif",
    description: "Deep hygiene cleaning",
    includes: [
      "Toilet and sink cleaning",
      "Floor and wall scrubbing",
      "Mirror and glass cleaning",
      "Sanitization"
    ],
    excludes: [
      "Plumbing repair"
    ],
    steps: [
      "Apply cleaning solution",
      "Scrub surfaces",
      "Wash and sanitize",
      "Final drying"
    ],
    tools: "Bathroom cleaning chemicals",
    time: "90 Minutes",
    price: 899,
    discount: 15,
    finalPrice: 764,
    warranty: "24 Hours support",
  ),

  CleaningService(
    name: "Move In Move Out Cleaning",
    image: "assets/move_in_move_out.jfif",
    description: "Perfect cleaning before shifting",
    includes: [
      "Full home deep cleaning",
      "Kitchen and bathroom cleaning",
      "Window and floor cleaning",
      "Dust removal"
    ],
    excludes: [
      "Furniture shifting",
      "Repair work"
    ],
    steps: [
      "Inspection",
      "Deep cleaning",
      "Sanitization",
      "Final finishing"
    ],
    tools: "Professional cleaning machines",
    time: "5–7 Hours",
    price: 2999,
    discount: 25,
    finalPrice: 2249,
    warranty: "24 Hours support",
  ),

  CleaningService(
    name: "Post Construction Cleaning",
    image: "assets/pc.jfif",
    description: "Remove construction dust",
    includes: [
      "Dust removal",
      "Floor and wall cleaning",
      "Glass cleaning",
      "Debris cleaning"
    ],
    excludes: [
      "Construction work",
      "Painting"
    ],
    steps: [
      "Remove debris",
      "Deep cleaning",
      "Dust removal",
      "Final finish"
    ],
    tools: "Heavy-duty cleaning machines",
    time: "6–8 Hours",
    price: 3999,
    discount: 30,
    finalPrice: 2799,
    warranty: "24 Hours support",
  ),

],

 /// 🏢 CORPORATE OFFICE CLEANING
"Corporate Office Cleaning": [

  CleaningService(
    name: "Office Deep Cleaning",
    image: "assets/officedp.jfif",
    description: "Clean office better productivity",
    includes: [
      "Floor deep cleaning",
      "Glass & window cleaning",
      "Workstations cleaning",
      "Cabins & meeting rooms",
      "Pantry & washroom cleaning",
      "Dusting & sanitization"
    ],
    excludes: [
      "IT equipment repair",
      "Furniture repair",
      "Electrical work"
    ],
    steps: [
      "Dusting and vacuuming",
      "Floor deep cleaning",
      "Glass and surface cleaning",
      "Sanitization"
    ],
    tools: "Industrial cleaning machines & chemicals",
    time: "3–5 Hours",
    price: 2999,
    discount: 20,
    finalPrice: 2399,
    warranty: "24 Hours support",
  ),

  CleaningService(
    name: "Workstation Cleaning",
    image: "assets/Workstation.jfif",
    description: "Clean desks and systems",
    includes: [
      "Desk cleaning",
      "Computer surface cleaning",
      "Chair cleaning",
      "Dust removal"
    ],
    excludes: [
      "Internal system repair",
      "Hardware replacement"
    ],
    steps: [
      "Dust removal",
      "Surface cleaning",
      "Sanitization",
      "Final check"
    ],
    tools: "Microfiber cloth & cleaning solution",
    time: "60 Minutes",
    price: 799,
    discount: 10,
    finalPrice: 719,
    warranty: "24 Hours support",
  ),

  CleaningService(
    name: "Cabin Cleaning",
    image: "assets/cabin.jfif",
    description: "Fresh and tidy cabins",
    includes: [
      "Table cleaning",
      "Chair cleaning",
      "Glass cleaning",
      "Dust removal"
    ],
    excludes: [
      "Furniture repair"
    ],
    steps: [
      "Dusting",
      "Surface cleaning",
      "Glass cleaning",
      "Sanitization"
    ],
    tools: "Cleaning kit & spray",
    time: "45 Minutes",
    price: 699,
    discount: 10,
    finalPrice: 629,
    warranty: "24 Hours support",
  ),

  CleaningService(
    name: "Pantry Cleaning",
    image: "assets/pantry.jfif",
    description: "Hygienic pantry space",
    includes: [
      "Shelf cleaning",
      "Sink cleaning",
      "Platform cleaning",
      "Dust removal"
    ],
    excludes: [
      "Appliance repair"
    ],
    steps: [
      "Remove dirt",
      "Clean surfaces",
      "Sanitize pantry",
      "Final check"
    ],
    tools: "Cleaning liquid & cloth",
    time: "60 Minutes",
    price: 899,
    discount: 15,
    finalPrice: 764,
    warranty: "24 Hours support",
  ),

  CleaningService(
    name: "Washroom Cleaning",
    image: "assets/office wash.jfif",
    description: "Clean office washrooms",
    includes: [
      "Toilet cleaning",
      "Sink cleaning",
      "Floor cleaning",
      "Sanitization"
    ],
    excludes: [
      "Plumbing repair"
    ],
    steps: [
      "Apply cleaning solution",
      "Scrub surfaces",
      "Wash and sanitize",
      "Dry and finish"
    ],
    tools: "Washroom cleaning chemicals",
    time: "45 Minutes",
    price: 799,
    discount: 10,
    finalPrice: 719,
    warranty: "24 Hours support",
  ),

],

  /// 🔌 ELECTRONIC CLEANING
"Electronic Cleaning": [

  CleaningService(
    name: "AC Cleaning",
    image: "assets/ac.jpg",
    description: "Improve cooling performance",
    includes: [
      "Filter cleaning",
      "Coil cleaning",
      "Dust removal",
      "Basic performance check"
    ],
    excludes: [
      "Gas refill",
      "Repair work",
      "Spare parts"
    ],
    steps: [
      "Open AC panel",
      "Clean filters and coils",
      "Remove dust and dirt",
      "Close and test AC"
    ],
    tools: "AC cleaning kit & pressure tools",
    time: "60 Minutes",
    price: 599,
    discount: 15,
    finalPrice: 509,
    warranty: "24 Hours support",
  ),

  CleaningService(
    name: "Fan Cleaning",
    image: "assets/fan.jfif",
    description: "Dust free fan cleaning",
    includes: [
      "Blade cleaning",
      "Dust removal",
      "Motor surface cleaning"
    ],
    excludes: [
      "Repair work",
      "Fan installation"
    ],
    steps: [
      "Switch off power",
      "Remove dust from blades",
      "Clean fan body",
      "Reassemble"
    ],
    tools: "Cleaning cloth & brush kit",
    time: "30 Minutes",
    price: 199,
    discount: 10,
    finalPrice: 179,
    warranty: "24 Hours support",
  ),

  CleaningService(
    name: "Refrigerator Cleaning",
    image: "assets/fridge.jfif",
    description: "Fresh and hygienic fridge",
    includes: [
      "Interior cleaning",
      "Shelf cleaning",
      "Odor removal",
      "Door rubber cleaning"
    ],
    excludes: [
      "Gas refill",
      "Repair work"
    ],
    steps: [
      "Remove shelves",
      "Clean interior",
      "Sanitize compartments",
      "Reassemble"
    ],
    tools: "Cleaning liquid & cloth",
    time: "45 Minutes",
    price: 399,
    discount: 10,
    finalPrice: 359,
    warranty: "24 Hours support",
  ),

  CleaningService(
    name: "Washing Machine Cleaning",
    image: "assets/washing machine.jfif",
    description: "Deep clean your machine",
    includes: [
      "Drum cleaning",
      "Filter cleaning",
      "Outer body cleaning"
    ],
    excludes: [
      "Repair work",
      "Spare parts"
    ],
    steps: [
      "Open machine",
      "Clean drum and filter",
      "Remove dirt",
      "Test machine"
    ],
    tools: "Machine cleaning kit",
    time: "60 Minutes",
    price: 499,
    discount: 10,
    finalPrice: 449,
    warranty: "24 Hours support",
  ),

  CleaningService(
    name: "TV and Laptop Cleaning",
    image: "assets/tv_laptop.png",
    description: "Safe electronic cleaning",
    includes: [
      "Screen cleaning",
      "Dust removal",
      "Surface cleaning"
    ],
    excludes: [
      "Repair work",
      "Internal hardware service"
    ],
    steps: [
      "Switch off device",
      "Clean screen",
      "Remove dust",
      "Final polish"
    ],
    tools: "Microfiber & electronic cleaning kit",
    time: "30 Minutes",
    price: 299,
    discount: 10,
    finalPrice: 269,
    warranty: "24 Hours support",
  ),

],

/// 📦 MONTHLY PACKAGES
"Monthly Packages": [

  CleaningService(
    name: "Basic Plan",
    image: "assets/monthly package.jpg",
    description: "Weekly basic home cleaning plan for small homes.",
    includes: [
      "4 visits/month (1 per week)",
      "Basic home cleaning (dusting + mopping)",
      "Bathroom quick cleaning (2 times/month)",
      "Kitchen surface cleaning (2 times/month)",
      "Garbage area cleaning"
    ],
    excludes: [
      "Deep cleaning",
      "Repair work",
      "Sofa cleaning",
      "Window deep cleaning"
    ],
    steps: [],
    tools: "Cleaning tools & chemicals included",
    time: "60–90 min/visit",
    price: 1499,
    discount: 20,
    finalPrice: 1199,
    warranty: "1 Month",
  ),

  CleaningService(
    name: "Standard Plan",
    image: "assets/standard.jfif",
    description: "Regular cleaning plan for medium homes with weekly maintenance.",
    includes: [
      "8 visits/month (2 per week)",
      "Complete home cleaning (dusting, mopping, surfaces)",
      "Weekly bathroom cleaning",
      "Weekly kitchen cleaning",
      "Fan & window basic cleaning (1 time/month)"
    ],
    excludes: [
      "Deep cleaning",
      "Repair work",
      "Sofa cleaning"
    ],
    steps: [],
    tools: "Cleaning tools & chemicals included",
    time: "90–120 min/visit",
    price: 2999,
    discount: 25,
    finalPrice: 2249,
    warranty: "1 Month",
  ),

  CleaningService(
    name: "Premium Plan",
    image: "assets/mc1.jpg",
    description: "Deep + regular cleaning plan for busy families.",
    includes: [
      "12 visits/month (3 per week)",
      "Full home cleaning with detailed dusting",
      "Kitchen deep cleaning (2 times/month)",
      "Bathroom deep cleaning (2 times/month)",
      "Sofa or carpet cleaning (1 time/month)",
      "Window cleaning (2 times/month)"
    ],
    excludes: [
      "Repair work",
      "Painting",
      "Civil work"
    ],
    steps: [],
    tools: "Advanced cleaning tools included",
    time: "2–3 hrs/visit",
    price: 4999,
    discount: 30,
    finalPrice: 3499,
    warranty: "1 Month",
  ),

  CleaningService(
    name: "Elite Plan",
    image: "assets/elite.jfif",
    description: "Daily premium cleaning and full home maintenance plan.",
    includes: [
      "20–24 visits/month (5–6 per week)",
      "Daily cleaning support",
      "Full home maintenance",
      "Weekly kitchen & bathroom deep cleaning",
      "Sofa/carpet cleaning (2 times/month)",
      "Window & balcony cleaning (weekly)",
      "Priority service",
      "Same-day booking"
    ],
    excludes: [
      "Repair work",
      "Civil work"
    ],
    steps: [],
    tools: "Premium tools & chemicals included",
    time: "2–4 hrs/visit",
    price: 7999,
    discount: 35,
    finalPrice: 5199,
    warranty: "1 Month",
  ),

]
};