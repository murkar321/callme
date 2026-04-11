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
    image: "assets/house-construction-service.jpg",
    subServices: [
      SubService(
        id: "residential",
        name: "Residential House Construction",
        image: "assets/house-construction-service.jpg",
        price: "₹1500+/sq.ft",
        rating: 4.5,
        discount: 10,
      ),
      SubService(
        id: "commercial",
        name: "Commercial Building Construction",
        image: "assets/Commercial Building Construction.jpg",
        price: "₹1800+/sq.ft",
        rating: 4.6,
        discount: 12,
      ),
      SubService(
        id: "villa",
        name: "Bungalow / Villa Construction",
        image: "assets/bunglow.jpg",
        price: "₹2500+/sq.ft",
        rating: 4.8,
        discount: 15,
      ),
      SubService(
        id: "apartment",
        name: "Apartment / Flat Construction",
        image: "assets/under construct.jpg",
        price: "₹2000+/sq.ft",
        rating: 4.4,
        discount: 8,
      ),
      SubService(
        id: "toilet",
        name: "Toilet Construction",
        image: "assets/toilet_construct.jpg",
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
    image: "assets/renovation.jpg",
    subServices: [

      /// 💰 BASIC
      SubService(
        id: "basic",
        name: "Basic Package",
        image: "assets/basic civil.jpg",
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
        image: "assets/standard civil.jpg",
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
        image: "assets/premium civil.jpg",
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
    image: "assets/paint1.jpg",
    subServices: [
      SubService(
        id: "interior",
        name: "Interior Painting",
        image: "assets/intpaint.jpg",
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
        image: "assets/expaint.jpg",
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
    image: "assets/window install.jfif",
    subServices: [
      SubService(
        id: "furniture",
        name: "Furniture Making",
        image: "assets/furniture1.jfif",
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
        image: "assets/modular kitchen.jfif",
        price: "₹1,50,000+",
        rating: 4.7,
        discount: 15,
      ),
      SubService(
        id: "doors",
        name: "Door & Window Installation",
        image: "assets/window install.jfif",
        price: "₹8000+",
        rating: 4.3,
        discount: 10,
      ),
      SubService(
        id: "repair",
        name: "Wooden Repair Work",
        image: "assets/door install.jfif",
        price: "₹2000+",
        rating: 4.2,
        discount: 5,
      ),
      SubService(
        id: "metal",
        name: "Metal Fabrication",
        image: "assets/metal fabric.jfif",
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
    image: "assets/switch board.jfif",
    subServices: [
      SubService(
        id: "wiring",
        name: "New Wiring Installation",
        image: "assets/new wire.jfif",
        price: "₹3000+",
        rating: 4.5,
        discount: 10,
      ),
      SubService(
        id: "replacement",
        name: "Old Wiring Replacement",
        image: "assets/old wire.jfif",
        price: "₹4000+",
        rating: 4.4,
        discount: 10,
      ),
      SubService(
        id: "switch",
        name: "Switch Board Installation",
        image: "assets/switch board.jfif",
        price: "₹1500+",
        rating: 4.3,
        discount: 8,
      ),
      SubService(
        id: "light",
        name: "Light & Fan Installation",
        image: "assets/light fan.jfif",
        price: "₹800+",
        rating: 4.2,
        discount: 5,
      ),
      SubService(
        id: "ups",
        name: "Inverter / UPS Setup",
        image: "assets/ups.jfif",
        price: "₹5000+",
        rating: 4.6,
        discount: 12,
      ),
      SubService(
        id: "fault",
        name: "Fault Repair & Maintenance",
        image: "assets/fault repair.jfif",
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
    image: "assets/pipe join.jpeg",
    subServices: [
      SubService(
        id: "pipe",
        name: "Pipe Installation & Repair",
        image: 'assets/plumber fix.png',
        price: "₹2000+",
        rating: 4.4,
        discount: 10,
      ),
      SubService(
        id: "leak",
        name: "Water Leakage Fixing",
        image: "assets/tap leak.jpeg",
        price: "₹800+",
        rating: 4.3,
        discount: 5,
      ),
      SubService(
        id: "tank",
        name: "Tank Installation",
        image: "assets/premium tank.jfif",
        price: "₹3000+",
        rating: 4.5,
        discount: 10,
      ),
      SubService(
        id: "bath",
        name: "Bathroom & Kitchen Plumbing",
        image: "assets/shower repair.jfif",
        price: "₹2500+",
        rating: 4.4,
        discount: 10,
      ),
      SubService(
        id: "motor",
        name: "Motor Installation",
        image: "assets/adavnced tank.jfif",
        price: "₹4000+",
        rating: 4.5,
        discount: 12,
      ),
      SubService(
        id: "drain",
        name: "Drainage Cleaning",
        image: "assets/kitchen drain.jpg",
        price: "₹1000+",
        rating: 4.2,
        discount: 5,
      ),
    ],
  ),
];