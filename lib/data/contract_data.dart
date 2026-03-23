import '../models/service_product.dart';

Map<String, List<ServiceProduct>> civilContractData = {

  /// 1️⃣ Construction & Renovation Services
  "Construction & Renovation Services": [

    ServiceProduct(
      id: "residential_construction",
      name: "Residential Construction",
      category: "Construction & Renovation Services",
      price: 20,
      imagePath: "assets/civil.png",
      slogan: "Sapno ka ghar, perfect execution ke saath.",
      description:
          "Complete house construction from foundation to finishing with quality materials and timely delivery.", service: '',
    ),

    ServiceProduct(
      id: "commercial_construction",
      name: "Commercial Construction",
      category: "Construction & Renovation Services",
      price: 25,
      imagePath: "assets/civil.png",
      slogan: "Strong structure for your growing business.",
      description:
          "Construction of shops, offices, and commercial buildings with modern design and durability.", service: '',
    ),

    ServiceProduct(
      id: "renovation",
      name: "Renovation",
      category: "Construction & Renovation Services",
      price: 15,
      imagePath: "assets/civil.png",
      slogan: "Purane ko naye jaisa banaye.",
      description:
          "Repair, redesign, and upgrading of spaces to improve look and functionality.", service: '',
    ),

    ServiceProduct(
      id: "structural_work",
      name: "Structural Work",
      category: "Construction & Renovation Services",
      price: 30,
      imagePath: "assets/civil.png",
      slogan: "Har structure me strength aur safety.",
      description:
          "RCC work including columns, beams, slabs, and foundation ensuring long-term durability.", service: '',
    ),

    ServiceProduct(
      id: "turnkey_projects",
      name: "Turnkey Projects",
      category: "Construction & Renovation Services",
      price: 28,
      imagePath: "assets/civil.png",
      slogan: "Planning se possession tak, sab hum sambhale.",
      description:
          "Complete project handling from planning to final handover.", service: '',
    ),
  ],

  /// 2️⃣ Masonry Work
  "Masonry Work": [

    ServiceProduct(
      id: "brickwork",
      name: "Brickwork",
      category: "Masonry Work",
      price: 12,
      imagePath: "assets/civil.png",
      slogan: "Strong walls, strong foundation.",
      description:
          "Construction of durable brick walls with proper alignment and finishing.", service: '',
    ),

    ServiceProduct(
      id: "blockwork",
      name: "Blockwork",
      category: "Masonry Work",
      price: 13,
      imagePath: "assets/civil.png",
      slogan: "Lightweight but strong construction.",
      description:
          "AAC and concrete block wall construction for modern buildings.", service: '',
    ),

    ServiceProduct(
      id: "plastering",
      name: "Plastering",
      category: "Masonry Work",
      price: 14,
      imagePath: "assets/civil.png",
      slogan: "Smooth finish, perfect walls.",
      description:
          "Wall and ceiling plastering for smooth and paint-ready surfaces.", service: '',
    ),

    ServiceProduct(
      id: "wall_construction",
      name: "Wall Construction",
      category: "Masonry Work",
      price: 16,
      imagePath: "assets/civil.png",
      slogan: "Har diwar majboot aur seedhi.",
      description:
          "Internal and external wall construction as per layout.", service: '',
    ),

    ServiceProduct(
      id: "compound_wall_work",
      name: "Compound Wall Work",
      category: "Masonry Work",
      price: 18,
      imagePath: "assets/civil.png",
      slogan: "Security aur boundary ka perfect solution.",
      description:
          "Boundary wall construction for safety and privacy.", service: '',
    ),
  ],

  /// 3️⃣ Flooring Services
  "Flooring Services": [

    ServiceProduct(
      id: "tile_flooring",
      name: "Tile Flooring",
      category: "Flooring Services",
      price: 18,
      imagePath: "assets/civil.png",
      slogan: "Har kadam par elegance.",
      description:
          "Installation of tiles with proper leveling and finishing.", service: '',
    ),

    ServiceProduct(
      id: "marble_flooring",
      name: "Marble Flooring",
      category: "Flooring Services",
      price: 22,
      imagePath: "assets/civil.png",
      slogan: "Luxury feel har jagah.",
      description:
          "Premium marble installation for stylish interiors.", service: '',
    ),

    ServiceProduct(
      id: "granite_flooring",
      name: "Granite Flooring",
      category: "Flooring Services",
      price: 23,
      imagePath: "assets/civil.png",
      slogan: "Strong and stylish flooring.",
      description:
          "Durable granite flooring with long-lasting finish.", service: '',
    ),

    ServiceProduct(
      id: "concrete_flooring",
      name: "Concrete Flooring",
      category: "Flooring Services",
      price: 17,
      imagePath: "assets/civil.png",
      slogan: "Tough floors for tough use.",
      description:
          "Concrete flooring for industrial and basic use.", service: '',
    ),

    ServiceProduct(
      id: "floor_polishing",
      name: "Floor Polishing",
      category: "Flooring Services",
      price: 15,
      imagePath: "assets/civil.png",
      slogan: "Bring back the shine.",
      description:
          "Polishing to enhance smoothness and shine of floors.", service: '',
    ),
  ],

  /// 4️⃣ Painting Services
  "Painting Services": [

    ServiceProduct(
      id: "interior_painting",
      name: "Interior Painting",
      category: "Painting Services",
      price: 14,
      imagePath: "assets/civil.png",
      slogan: "Ghar ko de naya rang aur feel.",
      description:
          "High-quality interior painting with smooth and clean finish.", service: '',
    ),

    ServiceProduct(
      id: "exterior_painting",
      name: "Exterior Painting",
      category: "Painting Services",
      price: 16,
      imagePath: "assets/civil.png",
      slogan: "Har mausam me protection.",
      description:
          "Weather-resistant painting for outer walls.", service: '',
    ),

    ServiceProduct(
      id: "waterproof_painting",
      name: "Waterproof Painting",
      category: "Painting Services",
      price: 18,
      imagePath: "assets/civil.png",
      slogan: "Leakage ko bolo goodbye.",
      description:
          "Special coating to prevent seepage and dampness.", service: '',
    ),

    ServiceProduct(
      id: "texture_painting",
      name: "Texture Painting",
      category: "Painting Services",
      price: 20,
      imagePath: "assets/civil.png",
      slogan: "Walls with style.",
      description:
          "Designer textures for modern and attractive walls.", service: '',
    ),

    ServiceProduct(
      id: "wall_putty_work",
      name: "Wall Putty Work",
      category: "Painting Services",
      price: 12,
      imagePath: "assets/civil.png",
      slogan: "Perfect base, perfect paint.",
      description:
          "Surface preparation for smooth and long-lasting paint.", service: '',
    ),
  ],

  /// 5️⃣ Plumbing Work
  "Plumbing Work": [

    ServiceProduct(
      id: "pipe_fitting",
      name: "Pipe Fitting",
      category: "Plumbing Work",
      price: 13,
      imagePath: "assets/civil.png",
      slogan: "Perfect flow, no tension.",
      description:
          "Installation of water supply and drainage pipelines.", service: '',
    ),

    ServiceProduct(
      id: "bathroom_fitting",
      name: "Bathroom Fitting",
      category: "Plumbing Work",
      price: 17,
      imagePath: "assets/civil.png",
      slogan: "Complete bathroom solutions.",
      description:
          "Installation of all bathroom fittings and fixtures.", service: '',
    ),

    ServiceProduct(
      id: "water_tank_installation",
      name: "Water Tank Installation",
      category: "Plumbing Work",
      price: 19,
      imagePath: "assets/civil.png",
      slogan: "Safe water storage setup.",
      description:
          "Installation of overhead and underground tanks.", service: '',
    ),

    ServiceProduct(
      id: "drainage_work",
      name: "Drainage Work",
      category: "Plumbing Work",
      price: 15,
      imagePath: "assets/civil.png",
      slogan: "No blockage, smooth drainage.",
      description:
          "Proper drainage system setup.", service: '',
    ),

    ServiceProduct(
      id: "leak_repair",
      name: "Leak Repair",
      category: "Plumbing Work",
      price: 12,
      imagePath: "assets/civil.png",
      slogan: "Choti problem ka quick solution.",
      description:
          "Fast detection and repair of leaks.", service: '',
    ),
  ],

  /// 6️⃣ Electrical Work
  "Electrical Work": [

    ServiceProduct(
      id: "wiring_installation",
      name: "Wiring Installation",
      category: "Electrical Work",
      price: 18,
      imagePath: "assets/civil.png",
      slogan: "Safe wiring, safe life.",
      description: "Complete electrical wiring setup.", service: '',
    ),

    ServiceProduct(
      id: "lighting_setup",
      name: "Lighting Setup",
      category: "Electrical Work",
      price: 16,
      imagePath: "assets/civil.png",
      slogan: "Brighten your space.",
      description:
          "Installation of decorative and functional lights.", service: '',
    ),

    ServiceProduct(
      id: "switchboard_installation",
      name: "Switchboard Installation",
      category: "Electrical Work",
      price: 14,
      imagePath: "assets/civil.png",
      slogan: "Control in your hands.",
      description: "Setup of switches and panels.", service: '',
    ),

    ServiceProduct(
      id: "electrical_repair",
      name: "Electrical Repair",
      category: "Electrical Work",
      price: 13,
      imagePath: "assets/civil.png",
      slogan: "Fix it fast, fix it right.",
      description:
          "Troubleshooting electrical issues.", service: '',
    ),

    ServiceProduct(
      id: "power_backup_setup",
      name: "Power Backup Setup",
      category: "Electrical Work",
      price: 20,
      imagePath: "assets/civil.png",
      slogan: "Light kabhi band nahi hogi.",
      description:
          "Installation of inverter and backup systems.", service: '',
    ),
  ],

  /// 7️⃣ Carpentry Work
  "Carpentry Work": [

    ServiceProduct(
      id: "door_installation",
      name: "Door Installation",
      category: "Carpentry Work",
      price: 15,
      imagePath: "assets/civil.png",
      slogan: "Strong doors, safe homes.",
      description:
          "Installation of wooden and designer doors.", service: '',
    ),

    ServiceProduct(
      id: "window_installation",
      name: "Window Installation",
      category: "Carpentry Work",
      price: 14,
      imagePath: "assets/civil.png",
      slogan: "Fresh air, perfect fit.",
      description:
          "Proper fitting of windows.", service: '',
    ),

    ServiceProduct(
      id: "furniture_work",
      name: "Furniture Work",
      category: "Carpentry Work",
      price: 19,
      imagePath: "assets/civil.png",
      slogan: "Custom furniture, perfect style.",
      description:
          "Designing and making furniture as per needs.", service: '',
    ),

    ServiceProduct(
      id: "modular_kitchen_setup",
      name: "Modular Kitchen Setup",
      category: "Carpentry Work",
      price: 25,
      imagePath: "assets/civil.png",
      slogan: "Smart kitchen, smart living.",
      description:
          "Installation of modern modular kitchens.", service: '',
    ),

    ServiceProduct(
      id: "wood_polishing",
      name: "Wood Polishing",
      category: "Carpentry Work",
      price: 13,
      imagePath: "assets/civil.png",
      slogan: "Shine that lasts.",
      description:
          "Polishing wooden surfaces for better finish.", service: '',
    ),
  ],

  /// 8️⃣ Demolition Services
  "Demolition Services": [

    ServiceProduct(
      id: "building_demolition",
      name: "Building Demolition",
      category: "Demolition Services",
      price: 30,
      imagePath: "assets/civil.png",
      slogan: "Safe removal, new beginning.",
      description:
          "Complete dismantling of structures safely.", service: '',
    ),

    ServiceProduct(
      id: "wall_removal",
      name: "Wall Removal",
      category: "Demolition Services",
      price: 18,
      imagePath: "assets/civil.png",
      slogan: "Redesign made easy.",
      description:
          "Breaking and removing walls.", service: '',
    ),

    ServiceProduct(
      id: "debris_cleaning",
      name: "Debris Cleaning",
      category: "Demolition Services",
      price: 12,
      imagePath: "assets/civil.png",
      slogan: "Clean site, ready for work.",
      description:
          "Removal of construction waste.", service: '',
    ),

    ServiceProduct(
      id: "site_clearing",
      name: "Site Clearing",
      category: "Demolition Services",
      price: 16,
      imagePath: "assets/civil.png",
      slogan: "Clear land, clear start.",
      description:
          "Preparing land for new construction.", service: '',
    ),
  ],

  /// 9️⃣ Waterproofing Services
  "Waterproofing Services": [

    ServiceProduct(
      id: "terrace_waterproofing",
      name: "Terrace Waterproofing",
      category: "Waterproofing Services",
      price: 22,
      imagePath: "assets/civil.png",
      slogan: "Roof leakage ka permanent solution.",
      description:
          "Waterproofing for rooftops.", service: '',
    ),

    ServiceProduct(
      id: "bathroom_waterproofing",
      name: "Bathroom Waterproofing",
      category: "Waterproofing Services",
      price: 20,
      imagePath: "assets/civil.png",
      slogan: "No seepage, no stress.",
      description:
          "Waterproofing for wet areas.", service: '',
    ),

    ServiceProduct(
      id: "wall_seepage_treatment",
      name: "Wall Seepage Treatment",
      category: "Waterproofing Services",
      price: 18,
      imagePath: "assets/civil.png",
      slogan: "Damp walls ko bye bye.",
      description:
          "Treatment of moisture and damp walls.", service: '',
    ),

    ServiceProduct(
      id: "crack_filling",
      name: "Crack Filling",
      category: "Waterproofing Services",
      price: 12,
      imagePath: "assets/civil.png",
      slogan: "Har crack ka solution.",
      description:
          "Sealing cracks to prevent leakage.", service: '',
    ),
  ],

  /// 🔟 Fabrication Work
  "Fabrication Work": [

    ServiceProduct(
      id: "metal_fabrication",
      name: "Metal Fabrication",
      category: "Fabrication Work",
      price: 23,
      imagePath: "assets/civil.png",
      slogan: "Strong metal, perfect design.",
      description:
          "Custom metal structure work.", service: '',
    ),

    ServiceProduct(
      id: "gate_and_grill_work",
      name: "Gate and Grill Work",
      category: "Fabrication Work",
      price: 21,
      imagePath: "assets/civil.png",
      slogan: "Security with style.",
      description:
          "Installation of gates and grills.", service: '',
    ),

    ServiceProduct(
      id: "railing_installation",
      name: "Railing Installation",
      category: "Fabrication Work",
      price: 19,
      imagePath: "assets/civil.png",
      slogan: "Safety with elegance.",
      description:
          "Installation of railings for stairs and balconies.", service: '',
    ),

    ServiceProduct(
      id: "shed_construction",
      name: "Shed Construction",
      category: "Fabrication Work",
      price: 24,
      imagePath: "assets/civil.png",
      slogan: "Strong sheds for every need.",
      description:
          "Construction of sheds for parking and storage.", service: '',
    ),
  ],
};