class CivilService {
  final String id;
  final String name;
  final String image;
  final List<SubService> subServices;

  CivilService({
    required this.id,
    required this.name,
    required this.image,
    required this.subServices,
  });

  get category => null;
}

class SubService {
  final String id;
  final String name;
  final String image;
  final String price;
  final double rating;
  final int discount;
  final List<String>? features; // 🔥 IMPORTANT

  SubService({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.rating,
    required this.discount,
    this.features,
  });

  get description => null;
}

/// 🔥 MAIN DATA
List<CivilService> civilServices = [

  /// 🏗️ NEW BUILD
  CivilService(
    id: "new_build",
    name: "New Build",
    image: "assets/civil.jpeg",
    subServices: [
      SubService(
        id: "residential",
        name: "Residential House Construction",
        image: "assets/civil.jpeg",
        price: "₹1500+/sq.ft",
        rating: 4.5,
        discount: 10,
      ),
      SubService(
        id: "commercial",
        name: "Commercial Building Construction",
        image: "assets/civil.jpeg",
        price: "₹1800+/sq.ft",
        rating: 4.6,
        discount: 12,
      ),
      SubService(
        id: "villa",
        name: "Bungalow / Villa Construction",
        image: "assets/civil.jpeg",
        price: "₹2500+/sq.ft",
        rating: 4.8,
        discount: 15,
      ),
      SubService(
        id: "apartment",
        name: "Apartment / Flat Construction",
        image: "assets/civil.jpeg",
        price: "₹2000+/sq.ft",
        rating: 4.4,
        discount: 8,
      ),
      SubService(
        id: "toilet",
        name: "Toilet Construction",
        image: "assets/civil.jpeg",
        price: "₹50,000+",
        rating: 4.3,
        discount: 5,
      ),
    ],
  ),

  /// 🔨 RENOVATION (FULL FEATURES)
  CivilService(
    id: "renovation",
    name: "Renovation",
    image: "assets/civil.jpeg",
    subServices: [

      /// 💰 BASIC
      SubService(
        id: "basic",
        name: "Basic Package",
        image: "assets/civil.jpeg",
        price: "₹1200 – ₹2800/sq.ft",
        rating: 4.2,
        discount: 10,
        features: [
          "Cracks & Plaster Work",
          "Basic Wall Painting",
          "Minor Crack Repair",
          "Basic Plumbing Repair",
          "Basic Electrical Repair",
          "Simple Bathroom Repair",
        ],
      ),

      /// ⭐ STANDARD
      SubService(
        id: "standard",
        name: "Standard Package",
        image: "assets/civil.jpeg",
        price: "₹1200 – ₹1800/sq.ft",
        rating: 4.5,
        discount: 12,
        features: [
          "Full Interior Painting + Putty",
          "Tiles Replacement (selected areas)",
          "Bathroom Renovation (new fittings)",
          "Electrical Wiring Upgrade",
          "Plumbing Replacement",
        ],
      ),

      /// 💎 PREMIUM
      SubService(
        id: "premium",
        name: "Premium Package",
        image: "assets/civil.jpeg",
        price: "₹1800 – ₹3000+/sq.ft",
        rating: 4.8,
        discount: 18,
        features: [
          "Designer Wall Finish",
          "Full Flooring (Tiles/Marble)",
          "Modular Kitchen",
          "False Ceiling",
          "Complete Electrical & Plumbing",
          "Waterproofing",
        ],
      ),
    ],
  ),

  /// 🎨 PAINTING
  CivilService(
    id: "painting",
    name: "Painting",
    image: "assets/civil.jpeg",
    subServices: [
      SubService(
        id: "interior",
        name: "Interior Painting",
        image: "assets/civil.jpeg",
        price: "₹25/sq.ft",
        rating: 4.6,
        discount: 10,
        features: [
          "Wall Cleaning",
          "Crack Filling",
          "Putty Application",
          "Sanding",
          "Wall Painting",
          "Ceiling Painting",
          "Texture / Designer Finish",
          "Stencil Work",
        ],
      ),
      SubService(
        id: "exterior",
        name: "Exterior Painting",
        image: "assets/civil.jpeg",
        price: "₹30/sq.ft",
        rating: 4.5,
        discount: 12,
        features: [
          "Wall Cleaning",
          "Crack Repair",
          "Putty & Surface Prep",
          "Exterior Painting",
          "Weatherproof Coating",
          "Waterproof Paint",
          "Elevation Finish",
        ],
      ),
    ],
  ),

  /// 🪚 CARPENTRY
  CivilService(
    id: "carpentry",
    name: "Carpentry & Fabrication",
    image: "assets/civil.jpeg",
    subServices: [
      SubService(
        id: "furniture",
        name: "Furniture Making",
        image: "assets/civil.jpeg",
        price: "₹5000+",
        rating: 4.4,
        discount: 8,
        features: [
          "Bed",
          "Sofa",
          "Wardrobe",
        ],
      ),
      SubService(
        id: "modular",
        name: "Modular Kitchen Work",
        image: "assets/civil.jpeg",
        price: "₹1,50,000+",
        rating: 4.7,
        discount: 15,
      ),
      SubService(
        id: "doors",
        name: "Door & Window Installation",
        image: "assets/civil.jpeg",
        price: "₹8000+",
        rating: 4.3,
        discount: 10,
      ),
      SubService(
        id: "repair",
        name: "Wooden Repair Work",
        image: "assets/civil.jpeg",
        price: "₹2000+",
        rating: 4.2,
        discount: 5,
      ),
      SubService(
        id: "metal",
        name: "Metal Fabrication",
        image: "assets/civil.jpeg",
        price: "₹7000+",
        rating: 4.5,
        discount: 12,
        features: [
          "Grill",
          "Gate",
          "Railing",
        ],
      ),
    ],
  ),

  /// ⚡ ELECTRICAL
  CivilService(
    id: "electrical",
    name: "Electrical",
    image: "assets/civil.jpeg",
    subServices: [
      SubService(
        id: "wiring",
        name: "New Wiring Installation",
        image: "assets/civil.jpeg",
        price: "₹3000+",
        rating: 4.5,
        discount: 10,
      ),
      SubService(
        id: "replacement",
        name: "Old Wiring Replacement",
        image: "assets/civil.jpeg",
        price: "₹4000+",
        rating: 4.4,
        discount: 10,
      ),
      SubService(
        id: "switch",
        name: "Switch Board Installation",
        image: "assets/civil.jpeg",
        price: "₹1500+",
        rating: 4.3,
        discount: 8,
      ),
      SubService(
        id: "light",
        name: "Light & Fan Installation",
        image: "assets/civil.jpeg",
        price: "₹800+",
        rating: 4.2,
        discount: 5,
      ),
      SubService(
        id: "ups",
        name: "Inverter / UPS Setup",
        image: "assets/civil.jpeg",
        price: "₹5000+",
        rating: 4.6,
        discount: 12,
      ),
      SubService(
        id: "fault",
        name: "Fault Repair & Maintenance",
        image: "assets/civil.jpeg",
        price: "₹500+",
        rating: 4.3,
        discount: 5,
      ),
    ],
  ),

  /// 🚿 PLUMBING
  CivilService(
    id: "plumbing",
    name: "Plumbing",
    image: "assets/civil.jpeg",
    subServices: [
      SubService(
        id: "pipe",
        name: "Pipe Installation & Repair",
        image: "assets/civil.jpeg",
        price: "₹2000+",
        rating: 4.4,
        discount: 10,
      ),
      SubService(
        id: "leak",
        name: "Water Leakage Fixing",
        image: "assets/civil.jpeg",
        price: "₹800+",
        rating: 4.3,
        discount: 5,
      ),
      SubService(
        id: "tank",
        name: "Tank Installation",
        image: "assets/civil.jpeg",
        price: "₹3000+",
        rating: 4.5,
        discount: 10,
      ),
      SubService(
        id: "bath",
        name: "Bathroom & Kitchen Plumbing",
        image: "assets/civil.jpeg",
        price: "₹2500+",
        rating: 4.4,
        discount: 10,
      ),
      SubService(
        id: "motor",
        name: "Motor Installation",
        image: "assets/civil.jpeg",
        price: "₹4000+",
        rating: 4.5,
        discount: 12,
      ),
      SubService(
        id: "drain",
        name: "Drainage Cleaning",
        image: "assets/civil.jpeg",
        price: "₹1000+",
        rating: 4.2,
        discount: 5,
      ),
    ],
  ),
];