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
  final List<String>? features;
  final String? about; // ← new: short description shown in detail page

  SubService({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.rating,
    required this.discount,
    this.features,
    this.about,
  });

  get description => null;
}

List<CivilService> civilServices = [

  // ────────────────────────────────────────────────────────────
  // 🏗️ NEW BUILD
  // ────────────────────────────────────────────────────────────
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
        about: "End-to-end construction of your dream home — from foundation laying to final finishing — with quality materials and skilled engineers.",
        features: [
          "Foundation & Structural Work",
          "Brick / Block Masonry",
          "RCC Roof Slab",
          "Plaster & Waterproofing",
          "Electrical & Plumbing Roughing",
          "Flooring & Wall Tiles",
          "Doors & Window Frames",
          "Final Paint & Finishing",
        ],
      ),
      SubService(
        id: "commercial",
        name: "Commercial Building Construction",
        image: "assets/Commercial Building Construction.jpg",
        price: "₹1800+/sq.ft",
        rating: 4.6,
        discount: 12,
        about: "Professional construction of offices, shops, and commercial complexes with structural integrity and modern finishes.",
        features: [
          "Structural Design & Planning",
          "RCC Framework",
          "Brickwork & Plastering",
          "Commercial-Grade Flooring",
          "MEP (Mechanical, Electrical, Plumbing)",
          "Glazing & Façade Work",
          "Fire Safety Provisions",
          "Final Handover & Inspection",
        ],
      ),
      SubService(
        id: "villa",
        name: "Bungalow / Villa Construction",
        image: "assets/bunglow.jpg",
        price: "₹2500+/sq.ft",
        rating: 4.8,
        discount: 15,
        about: "Luxury bungalow and villa construction with premium materials, landscaping provision, and designer interiors.",
        features: [
          "Architectural Design Support",
          "Premium Foundation & Structure",
          "Staircase & Terrace",
          "Swimming Pool Provision",
          "Modular Kitchen & Wardrobes",
          "Premium Flooring (Marble / Vitrified)",
          "Landscaping & Compound Wall",
          "Smart Home Wiring Ready",
        ],
      ),
      SubService(
        id: "apartment",
        name: "Apartment / Flat Construction",
        image: "assets/under construct.jpg",
        price: "₹2000+/sq.ft",
        rating: 4.4,
        discount: 8,
        about: "Multi-storey apartment construction with modern amenities, common area development, and lift provisions.",
        features: [
          "Multi-Storey RCC Structure",
          "Lift & Staircase Core",
          "Common Area Development",
          "Individual Flat Plastering",
          "Electrical Wiring Per Flat",
          "Plumbing & Drainage Per Flat",
          "Compound & Parking",
          "Handover Finishing",
        ],
      ),
      SubService(
        id: "toilet",
        name: "Toilet Construction",
        image: "assets/toilet_construct.jpg",
        price: "₹50,000+",
        rating: 4.3,
        discount: 5,
        about: "New toilet block construction with waterproofing, sanitary fittings, ventilation, and tiling — fully ready to use.",
        features: [
          "Masonry & Structural Work",
          "Waterproofing Treatment",
          "Wall & Floor Tiling",
          "Sanitary Ware Installation",
          "Plumbing & Drainage",
          "Ventilation Provision",
          "Door & Fitting",
        ],
      ),
    ],
  ),

  // ────────────────────────────────────────────────────────────
  // 🔨 RENOVATION
  // ────────────────────────────────────────────────────────────
  CivilService(
    id: "renovation",
    name: "Renovation",
    image: "assets/renovation.jpg",
    subServices: [
      SubService(
        id: "basic",
        name: "Basic Package",
        image: "assets/basic civil.jpg",
        price: "₹1200 – ₹2800/sq.ft",
        rating: 4.2,
        discount: 10,
        about: "Essential repairs and touch-ups to refresh your space without a full overhaul.",
        features: [
          "Cracks & Plaster Work",
          "Basic Wall Painting",
          "Minor Crack Repair",
          "Basic Plumbing Repair",
          "Basic Electrical Repair",
          "Simple Bathroom Repair",
        ],
      ),
      SubService(
        id: "standard",
        name: "Standard Package",
        image: "assets/standard civil.jpg",
        price: "₹1200 – ₹1800/sq.ft",
        rating: 4.5,
        discount: 12,
        about: "A comprehensive mid-range renovation covering painting, tiling, plumbing, and electrical upgrades.",
        features: [
          "Full Interior Painting + Putty",
          "Tiles Replacement (selected areas)",
          "Bathroom Renovation (new fittings)",
          "Electrical Wiring Upgrade",
          "Plumbing Replacement",
        ],
      ),
      SubService(
        id: "premium",
        name: "Premium Package",
        image: "assets/premium civil.jpg",
        price: "₹1800 – ₹3000+/sq.ft",
        rating: 4.8,
        discount: 18,
        about: "Full luxury renovation with designer finishes, modular kitchen, false ceiling, and complete MEP overhaul.",
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

  // ────────────────────────────────────────────────────────────
  // 🎨 PAINTING
  // ────────────────────────────────────────────────────────────
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
        about: "Transform your interiors with smooth, even coats of premium paint — walls, ceilings, and designer textures included.",
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
        about: "Weather-resistant exterior painting that protects your building and keeps it looking fresh for years.",
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

  // ────────────────────────────────────────────────────────────
  // 🪚 CARPENTRY & FABRICATION
  // ────────────────────────────────────────────────────────────
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
        about: "Custom-made wooden furniture crafted to your space and style — beds, sofas, wardrobes, and more.",
        features: [
          "Custom Bed Design & Build",
          "Sofa Frame & Upholstery",
          "Wardrobe with Sliding / Hinged Doors",
          "Study Table & Shelving",
          "Polish & Lacquer Finishing",
          "Delivery & Installation",
        ],
      ),
      SubService(
        id: "modular",
        name: "Modular Kitchen Work",
        image: "assets/modular kitchen.jfif",
        price: "₹1,50,000+",
        rating: 4.7,
        discount: 15,
        about: "Full modular kitchen design and installation with premium shutters, hardware, and countertop fitting.",
        features: [
          "Layout Design & Planning",
          "Base & Wall Cabinets",
          "Premium Shutters (Acrylic / PU / Laminate)",
          "Countertop Fitting (Granite / Quartz)",
          "Soft-Close Hinges & Drawer Channels",
          "Sink & Chimney Cut-Out",
          "Electrical Point Provision",
          "Final Finishing & Cleaning",
        ],
      ),
      SubService(
        id: "doors",
        name: "Door & Window Installation",
        image: "assets/window install.jfif",
        price: "₹8000+",
        rating: 4.3,
        discount: 10,
        about: "Supply and installation of wooden, UPVC, or aluminium doors and windows with proper sealing and hardware.",
        features: [
          "Frame Fixing & Alignment",
          "Door Shutter Installation",
          "Window Frame & Glass Fitting",
          "Lock, Handle & Hinge Fitting",
          "Waterproof Sealant Application",
          "Grills / Mosquito Net Option",
        ],
      ),
      SubService(
        id: "repair",
        name: "Wooden Repair Work",
        image: "assets/door install.jfif",
        price: "₹2000+",
        rating: 4.2,
        discount: 5,
        about: "Expert repair of damaged wooden furniture, doors, windows, and fixtures — restored to like-new condition.",
        features: [
          "Door / Window Alignment Fix",
          "Crack & Joint Repair",
          "Polish & Finish Touch-Up",
          "Hinge / Lock Replacement",
          "Termite Treatment (if needed)",
          "Wardrobe Repair & Adjustment",
        ],
      ),
      SubService(
        id: "metal",
        name: "Metal Fabrication",
        image: "assets/metal fabric.jfif",
        price: "₹7000+",
        rating: 4.5,
        discount: 12,
        about: "Custom steel and iron fabrication for grills, gates, railings, and structural metal work.",
        features: [
          "Custom Grill Design & Welding",
          "Main Gate Fabrication",
          "Staircase Railing",
          "Window Safety Grills",
          "Anti-Rust Primer Coat",
          "Final Paint / Powder Coating",
        ],
      ),
    ],
  ),

  // ────────────────────────────────────────────────────────────
  // ⚡ ELECTRICAL
  // ────────────────────────────────────────────────────────────
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
        about: "Complete new electrical wiring for homes and offices using ISI-certified wires with proper conduit laying.",
        features: [
          "Conduit / Concealed Wiring",
          "ISI-Certified Wire Supply",
          "MCB & Distribution Board",
          "Earthing Setup",
          "Point-wise Wiring (Light, Fan, AC)",
          "Testing & Safety Check",
        ],
      ),
      SubService(
        id: "replacement",
        name: "Old Wiring Replacement",
        image: "assets/old wire.jfif",
        price: "₹4000+",
        rating: 4.4,
        discount: 10,
        about: "Safe removal of outdated wiring and full replacement with modern insulated cables and updated switchboards.",
        features: [
          "Old Wire Removal",
          "New Conduit Laying",
          "Updated MCB Panel",
          "Earthing Check & Fix",
          "All Points Re-Wired",
          "Overload Protection Setup",
        ],
      ),
      SubService(
        id: "switch",
        name: "Switch Board Installation",
        image: "assets/switch board.jfif",
        price: "₹1500+",
        rating: 4.3,
        discount: 8,
        about: "Installation of modular switch boards, sockets, and MCBs with proper earthing and neat concealed wiring.",
        features: [
          "Modular Switch Board Fitting",
          "Socket & Switch Installation",
          "MCB / RCCB Fitting",
          "Fan Regulator Installation",
          "Earthing Connection",
          "Proper Labeling of Points",
        ],
      ),
      SubService(
        id: "light",
        name: "Light & Fan Installation",
        image: "assets/light fan.jfif",
        price: "₹800+",
        rating: 4.2,
        discount: 5,
        about: "Quick and safe installation of ceiling fans, LED lights, chandeliers, and exhaust fans.",
        features: [
          "Ceiling Fan Fitting & Balancing",
          "LED / CFL Light Fitting",
          "Chandelier / Pendant Hanging",
          "Exhaust Fan Installation",
          "Dimmer Switch Connection",
          "Wiring Connection & Testing",
        ],
      ),
      SubService(
        id: "ups",
        name: "Inverter / UPS Setup",
        image: "assets/ups.jfif",
        price: "₹5000+",
        rating: 4.6,
        discount: 12,
        about: "Professional inverter and UPS installation with battery setup, wiring, and load calculation.",
        features: [
          "Inverter / UPS Placement",
          "Battery Connection & Setup",
          "Load Calculation",
          "Dedicated Wiring for Backup Points",
          "Changeover Switch Fitting",
          "Testing & Demo",
        ],
      ),
      SubService(
        id: "fault",
        name: "Fault Repair & Maintenance",
        image: "assets/fault repair.jfif",
        price: "₹500+",
        rating: 4.3,
        discount: 5,
        about: "Fast diagnosis and repair of electrical faults — short circuits, tripping MCBs, dead points, and more.",
        features: [
          "Fault Diagnosis",
          "Short Circuit Repair",
          "Tripping MCB Fix",
          "Dead Point Restoration",
          "Socket / Switch Replacement",
          "Earthing Fault Repair",
        ],
      ),
    ],
  ),

  // ────────────────────────────────────────────────────────────
  // 🚿 PLUMBING
  // ────────────────────────────────────────────────────────────
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
        about: "Supply and installation of CPVC / PVC pipes for water supply and drainage with leak-proof joints.",
        features: [
          "Pipe Layout Planning",
          "CPVC / PVC Pipe Supply",
          "Concealed / Surface Laying",
          "Joint Sealing & Testing",
          "Old Pipe Replacement",
          "Pressure Testing",
        ],
      ),
      SubService(
        id: "leak",
        name: "Water Leakage Fixing",
        image: "assets/tap leak.jpeg",
        price: "₹800+",
        rating: 4.3,
        discount: 5,
        about: "Expert detection and repair of water leakages in pipes, walls, roofs, and bathroom fittings.",
        features: [
          "Leakage Source Detection",
          "Pipe Joint Repair",
          "Tap / Valve Replacement",
          "Wall Leakage Sealing",
          "Waterproofing Treatment",
          "Post-Fix Testing",
        ],
      ),
      SubService(
        id: "tank",
        name: "Tank Installation",
        image: "assets/premium tank.jfif",
        price: "₹3000+",
        rating: 4.5,
        discount: 10,
        about: "Overhead and underground water tank installation with inlet, outlet, overflow, and ball valve fittings.",
        features: [
          "Tank Placement & Support Structure",
          "Inlet & Outlet Pipe Connection",
          "Overflow Pipe Setup",
          "Ball Valve / Float Valve Fitting",
          "Tank Cleaning (if replacement)",
          "Testing & Commissioning",
        ],
      ),
      SubService(
        id: "bath",
        name: "Bathroom & Kitchen Plumbing",
        image: "assets/shower repair.jfif",
        price: "₹2500+",
        rating: 4.4,
        discount: 10,
        about: "Complete bathroom and kitchen plumbing — from new fittings to full pipeline layout for renovations.",
        features: [
          "WC / Commode Fitting",
          "Wash Basin Installation",
          "Shower & Mixer Fitting",
          "Kitchen Sink Connection",
          "Hot & Cold Water Lines",
          "Drain & Trap Setup",
        ],
      ),
      SubService(
        id: "motor",
        name: "Motor Installation",
        image: "assets/adavnced tank.jfif",
        price: "₹4000+",
        rating: 4.5,
        discount: 12,
        about: "Water pump and motor installation with suction pipe, delivery pipe, and pressure testing.",
        features: [
          "Pump Selection Guidance",
          "Suction & Delivery Pipe Laying",
          "Motor Base Fixing",
          "Electrical Connection",
          "Pressure Switch Setup",
          "Testing & Demo",
        ],
      ),
      SubService(
        id: "drain",
        name: "Drainage Cleaning",
        image: "assets/kitchen drain.jpg",
        price: "₹1000+",
        rating: 4.2,
        discount: 5,
        about: "Professional drainage unblocking and cleaning using high-pressure jetting and rodding tools.",
        features: [
          "Blockage Identification",
          "High-Pressure Jetting",
          "Manual Rodding",
          "Drain Cover Inspection",
          "Grease Trap Cleaning",
          "Post-Clean Flow Test",
        ],
      ),
    ],
  ),
];

