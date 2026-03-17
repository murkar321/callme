class SalonService {
  final String name;
  final String image;
  final String time;
  final int price;
  final int discount;
  final int finalPrice;
  final String slogan;
  final String description;
  final String category;
  final List<String> includes;
  final List<String> process;

  SalonService({
    required this.name,
    required this.image,
    required this.time,
    required this.price,
    required this.discount,
    required this.finalPrice,
    required this.slogan,
    required this.description,
    required this.category,
    required this.includes,
    required this.process,
  });
}

List<String> salonCategories = [
  "Hair Cut",
  "Hair Styling",
  "Hair Treatments",
  "Hair Color",
  "Facial",
  "Makeup",
  "Manicure",
  "Pedicure",
  "Waxing",
];

List<SalonService> salonServices = [
  /// HAIR CUT
  SalonService(
    name: "Men Hair Cut",
    category: "Hair Cut",
    image: "assets/men_haircut.png",
    time: "30 minutes",
    price: 300,
    discount: 20,
    finalPrice: 240,
    slogan: "Sharp and clean professional haircut.",
    description:
        "A professional haircut designed to give men a clean, stylish, and well-groomed appearance.",
    includes: [
      "Hair consultation",
      "Professional haircut",
      "Neck cleaning",
      "Basic styling finish"
    ],
    process: [
      "Consultation with stylist",
      "Hair preparation",
      "Hair cutting and shaping",
      "Final styling"
    ],
  ),

  SalonService(
    name: "Women Hair Cut",
    category: "Hair Cut",
    image: "assets/women_haircut.png",
    time: "45 minutes",
    price: 600,
    discount: 15,
    finalPrice: 510,
    slogan: "Stylish haircut designed for your personality.",
    description:
        "A stylish haircut tailored to your personality and face shape.",
    includes: [
      "Hair consultation",
      "Hair wash",
      "Professional haircut",
      "Blow dry styling"
    ],
    process: [
      "Hair consultation",
      "Hair wash",
      "Hair cutting",
      "Styling and finishing"
    ],
  ),

  SalonService(
    name: "Kids Hair Cut",
    category: "Hair Cut",
    image: "assets/kids_haircut.png",
    time: "20 minutes",
    price: 200,
    discount: 10,
    finalPrice: 180,
    slogan: "Comfortable and stylish haircuts for kids.",
    description: "Safe and comfortable haircut specially for kids.",
    includes: [
      "Hair consultation",
      "Gentle haircut",
      "Neck cleaning",
      "Basic styling"
    ],
    process: [
      "Consultation",
      "Hair preparation",
      "Hair cutting",
      "Final styling"
    ],
  ),

  SalonService(
    name: "Hair Trim",
    category: "Hair Cut",
    image: "assets/hair_trim.png",
    time: "20 minutes",
    price: 250,
    discount: 10,
    finalPrice: 225,
    slogan: "Maintain healthy hair with a quick trim.",
    description: "Quick trim to remove split ends and maintain hair health.",
    includes: ["Hair consultation", "Hair trimming", "Basic styling"],
    process: ["Hair consultation", "Hair trimming", "Final styling"],
  ),

  /// HAIR STYLING

  SalonService(
    name: "Hair Blow Dry",
    category: "Hair Styling",
    image: "assets/blowdry.png",
    time: "30 minutes",
    price: 400,
    discount: 15,
    finalPrice: 340,
    slogan: "Smooth and voluminous hair styling.",
    description: "Professional blow dry styling for smooth hair.",
    includes: ["Hair wash", "Blow dry styling"],
    process: ["Hair wash", "Blow drying", "Final styling"],
  ),

  SalonService(
    name: "Hair Curling",
    category: "Hair Styling",
    image: "assets/hair_curling.png",
    time: "40 minutes",
    price: 700,
    discount: 20,
    finalPrice: 560,
    slogan: "Beautiful curls for special occasions.",
    description: "Professional hair curling service.",
    includes: ["Hair preparation", "Curling", "Styling"],
    process: ["Hair preparation", "Curling", "Final styling"],
  ),

  SalonService(
    name: "Hair Straightening",
    category: "Hair Styling",
    image: "assets/hair_straightening.png",
    time: "45 minutes",
    price: 800,
    discount: 15,
    finalPrice: 680,
    slogan: "Sleek and silky straight hair.",
    description: "Temporary hair straightening styling.",
    includes: ["Hair preparation", "Straightening", "Styling"],
    process: ["Hair preparation", "Hair straightening", "Final styling"],
  ),

  SalonService(
    name: "Party Hair Styling",
    category: "Hair Styling",
    image: "assets/party_hairstyle.png",
    time: "45 minutes",
    price: 900,
    discount: 20,
    finalPrice: 720,
    slogan: "Perfect hairstyle for parties and events.",
    description: "Stylish party hair look created by professionals.",
    includes: ["Hair preparation", "Styling", "Hair finishing"],
    process: ["Hair preparation", "Hair styling", "Final finishing"],
  ),

  /// HAIR TREATMENTS

  SalonService(
    name: "Hair Smoothening",
    category: "Hair Treatments",
    image: "assets/hair_smoothening.png",
    time: "2 hours",
    price: 3500,
    discount: 25,
    finalPrice: 2625,
    slogan: "Frizz free smooth hair for months.",
    description: "Professional smoothening treatment for frizz free hair.",
    includes: ["Hair wash", "Smoothening product", "Heat sealing"],
    process: ["Hair wash", "Product application", "Heat sealing"],
  ),

  SalonService(
    name: "Hair Rebonding",
    category: "Hair Treatments",
    image: "assets/hair_rebonding.png",
    time: "3 hours",
    price: 4500,
    discount: 20,
    finalPrice: 3600,
    slogan: "Permanent straight hair transformation.",
    description: "Permanent hair straightening rebonding treatment.",
    includes: ["Hair wash", "Chemical treatment", "Heat sealing"],
    process: ["Hair preparation", "Chemical application", "Heat sealing"],
  ),

  SalonService(
    name: "Hair Botox Treatment",
    category: "Hair Treatments",
    image: "assets/hair_botox.png",
    time: "90 minutes",
    price: 3000,
    discount: 20,
    finalPrice: 2400,
    slogan: "Deep repair for damaged hair.",
    description: "Hair botox treatment repairs damaged hair.",
    includes: ["Hair wash", "Botox cream application", "Heat activation"],
    process: ["Hair wash", "Cream application", "Heat sealing"],
  ),

  SalonService(
    name: "Keratin Treatment",
    category: "Hair Treatments",
    image: "assets/keratin.png",
    time: "2 hours",
    price: 4000,
    discount: 25,
    finalPrice: 3000,
    slogan: "Shiny smooth and healthy hair.",
    description: "Keratin treatment reduces frizz and adds shine.",
    includes: ["Hair wash", "Keratin product application", "Heat sealing"],
    process: [
      "Hair wash",
      "Keratin application",
      "Heat sealing",
      "Final styling"
    ],
  ),

  SalonService(
    name: "Hair Spa",
    category: "Hair Treatments",
    image: "assets/hair_spa.png",
    time: "45 minutes",
    price: 800,
    discount: 15,
    finalPrice: 680,
    slogan: "Nourish and relax your hair.",
    description: "Relaxing spa treatment for healthy hair.",
    includes: ["Hair wash", "Spa massage", "Steam treatment"],
    process: ["Hair wash", "Spa cream massage", "Steam therapy"],
  ),

  /// HAIR COLOR
  /// /// ROOT TOUCH-UP
  SalonService(
    name: "Root Touch-up",
    category: "Hair Color",
    image: "assets/root_touchup.png",
    time: "60 minutes",
    price: 1200,
    discount: 15,
    finalPrice: 1020,
    slogan: "Refresh your hair color by covering roots.",
    description:
        "A quick hair coloring service focused on covering new hair growth at the roots and maintaining a fresh look.",
    includes: [
      "Hair consultation",
      "Root color application",
      "Color processing",
      "Hair wash and basic styling"
    ],
    process: [
      "Hair consultation",
      "Root color application",
      "Color processing time",
      "Hair wash and styling"
    ],
  ),

  /// GLOBAL HAIR COLOR
  SalonService(
    name: "Global Hair Color",
    category: "Hair Color",
    image: "assets/global_hair_color.png",
    time: "2 hours",
    price: 3500,
    discount: 20,
    finalPrice: 2800,
    slogan: "Complete hair color transformation.",
    description:
        "Full hair coloring service that transforms your entire hair with a rich and vibrant shade.",
    includes: [
      "Hair consultation",
      "Full hair color application",
      "Color processing",
      "Hair wash and styling"
    ],
    process: [
      "Hair consultation",
      "Full hair color application",
      "Color development",
      "Hair wash and styling"
    ],
  ),

  /// HAIR HIGHLIGHTS
  SalonService(
    name: "Hair Highlights",
    category: "Hair Color",
    image: "assets/hair_highlights.png",
    time: "2 hours",
    price: 4000,
    discount: 20,
    finalPrice: 3200,
    slogan: "Stylish highlights for a trendy look.",
    description:
        "Professional highlight service that adds lighter strands to enhance hair dimension and style.",
    includes: [
      "Hair consultation",
      "Sectioning and highlight application",
      "Color processing",
      "Hair wash and styling"
    ],
    process: [
      "Hair consultation",
      "Hair sectioning",
      "Highlight color application",
      "Hair wash and styling"
    ],
  ),

  /// BALAYAGE
  SalonService(
    name: "Balayage",
    category: "Hair Color",
    image: "assets/balayage.png",
    time: "2.5 hours",
    price: 5000,
    discount: 20,
    finalPrice: 4000,
    slogan: "Natural blended hair color style.",
    description:
        "A hand-painted coloring technique that creates soft and natural looking color transitions.",
    includes: [
      "Hair consultation",
      "Balayage color application",
      "Color processing",
      "Hair wash and styling"
    ],
    process: [
      "Hair consultation",
      "Hand painting color technique",
      "Color development",
      "Hair wash and final styling"
    ],
  ),

  /// OMBRE HAIR COLOR
  SalonService(
    name: "Ombre Hair Color",
    category: "Hair Color",
    image: "assets/ombre_hair_color.png",
    time: "2.5 hours",
    price: 4800,
    discount: 20,
    finalPrice: 3840,
    slogan: "Trendy gradient hair color design.",
    description:
        "A gradient hair coloring technique where the hair gradually transitions from darker roots to lighter ends.",
    includes: [
      "Hair consultation",
      "Ombre color application",
      "Color processing",
      "Hair wash and styling"
    ],
    process: [
      "Hair consultation",
      "Gradient color application",
      "Color development",
      "Hair wash and styling"
    ],
  ),

  /// FACIAL

  SalonService(
    name: "Basic Facial",
    category: "Facial",
    image: "assets/basic_facial.png",
    time: "40 minutes",
    price: 700,
    discount: 15,
    finalPrice: 595,
    slogan: "Quick glow facial for everyday beauty.",
    description: "Refreshing facial for glowing skin.",
    includes: ["Face cleansing", "Face scrub", "Face massage", "Face mask"],
    process: ["Skin cleansing", "Exfoliation", "Massage", "Face pack"],
  ),

  SalonService(
    name: "Fruit Facial",
    category: "Facial",
    image: "assets/fruit_facial.png",
    time: "45 minutes",
    price: 900,
    discount: 15,
    finalPrice: 765,
    slogan: "Natural fruit extracts for glowing skin.",
    description: "Fruit facial improves skin glow.",
    includes: ["Fruit cleanser", "Fruit scrub", "Fruit mask"],
    process: ["Cleansing", "Scrubbing", "Mask application"],
  ),

  /// GOLD FACIAL
  SalonService(
    name: "Gold Facial",
    category: "Facial",
    image: "assets/gold_facial.png",
    time: "60 minutes",
    price: 1500,
    discount: 20,
    finalPrice: 1200,
    slogan: "Luxury glow treatment with gold care.",
    description:
        "A premium facial treatment that uses gold-based products to rejuvenate skin and enhance natural glow.",
    includes: [
      "Face cleansing",
      "Gold scrub exfoliation",
      "Gold facial massage",
      "Gold face mask",
      "Moisturizer application"
    ],
    process: [
      "Skin cleansing",
      "Gold scrub exfoliation",
      "Facial massage",
      "Gold mask application",
      "Final moisturizing"
    ],
  ),

  /// DIAMOND FACIAL
  SalonService(
    name: "Diamond Facial",
    category: "Facial",
    image: "assets/diamond_facial.png",
    time: "60 minutes",
    price: 2000,
    discount: 20,
    finalPrice: 1600,
    slogan: "Radiant and youthful looking skin.",
    description:
        "A luxury facial that helps remove dead skin cells and enhances skin brightness using diamond particles.",
    includes: [
      "Face cleansing",
      "Diamond scrub exfoliation",
      "Face massage",
      "Diamond mask",
      "Moisturizer"
    ],
    process: [
      "Skin cleansing",
      "Diamond exfoliation",
      "Facial massage",
      "Mask application",
      "Moisturizing"
    ],
  ),

  /// ANTI AGING FACIAL
  SalonService(
    name: "Anti Aging Facial",
    category: "Facial",
    image: "assets/anti_aging_facial.png",
    time: "60 minutes",
    price: 1800,
    discount: 20,
    finalPrice: 1440,
    slogan: "Reduce wrinkles and fine lines.",
    description:
        "A specialized facial treatment that targets wrinkles and improves skin elasticity for a youthful appearance.",
    includes: [
      "Deep cleansing",
      "Anti aging serum application",
      "Face massage",
      "Anti aging mask",
      "Moisturizer"
    ],
    process: [
      "Skin cleansing",
      "Serum application",
      "Facial massage",
      "Mask application",
      "Final moisturizing"
    ],
  ),

  /// HYDRATING FACIAL
  SalonService(
    name: "Hydrating Facial",
    category: "Facial",
    image: "assets/hydrating_facial.png",
    time: "50 minutes",
    price: 1200,
    discount: 15,
    finalPrice: 1020,
    slogan: "Deep hydration for soft glowing skin.",
    description:
        "A moisturizing facial designed to deeply hydrate dry and dull skin for a fresh glow.",
    includes: [
      "Face cleansing",
      "Hydrating serum",
      "Face massage",
      "Hydrating mask",
      "Moisturizer"
    ],
    process: [
      "Skin cleansing",
      "Hydration serum application",
      "Facial massage",
      "Hydrating mask",
      "Final moisturizing"
    ],
  ),

  /// DETAN FACIAL
  SalonService(
    name: "Detan Facial",
    category: "Facial",
    image: "assets/detan_facial.png",
    time: "45 minutes",
    price: 1000,
    discount: 15,
    finalPrice: 850,
    slogan: "Remove tan and brighten skin tone.",
    description:
        "A skin brightening facial treatment that removes sun tan and restores natural skin glow.",
    includes: [
      "Face cleansing",
      "Detan scrub",
      "Face massage",
      "Detan pack",
      "Moisturizer"
    ],
    process: [
      "Skin cleansing",
      "Scrubbing",
      "Massage",
      "Detan pack application",
      "Final moisturizing"
    ],
  ),

  /// MAKEUP

  SalonService(
    name: "Party Makeup",
    category: "Makeup",
    image: "assets/party_makeup.png",
    time: "60 minutes",
    price: 2500,
    discount: 20,
    finalPrice: 2000,
    slogan: "Glamorous look for every party.",
    description: "Professional party makeup service.",
    includes: ["Skin preparation", "Foundation", "Eye makeup", "Lip makeup"],
    process: [
      "Skin preparation",
      "Base makeup",
      "Eye makeup",
      "Final finishing"
    ],
  ),

  SalonService(
    name: "Bridal Makeup",
    category: "Makeup",
    image: "assets/bridal_makeup.png",
    time: "2 hours",
    price: 12000,
    discount: 15,
    finalPrice: 10200,
    slogan: "Perfect bridal glow for your special day.",
    description: "Luxury bridal makeup service.",
    includes: ["Skin preparation", "Foundation", "Eye makeup", "Hair styling"],
    process: [
      "Skin preparation",
      "Base makeup",
      "Eye makeup",
      "Final finishing"
    ],
  ),

  /// ENGAGEMENT MAKEUP
  SalonService(
    name: "Engagement Makeup",
    category: "Makeup",
    image: "assets/engagement_makeup.png",
    time: "90 minutes",
    price: 5000,
    discount: 15,
    finalPrice: 4250,
    slogan: "Elegant makeup for engagement ceremony.",
    description:
        "A professional makeup service designed to give you a graceful and elegant look for your engagement ceremony.",
    includes: [
      "Skin preparation",
      "Foundation and contouring",
      "Eye makeup",
      "Lip makeup",
      "Hair styling"
    ],
    process: [
      "Skin preparation",
      "Base makeup application",
      "Eye makeup styling",
      "Final finishing and setting"
    ],
  ),

  /// RECEPTION MAKEUP
  SalonService(
    name: "Reception Makeup",
    category: "Makeup",
    image: "assets/reception_makeup.png",
    time: "90 minutes",
    price: 6000,
    discount: 15,
    finalPrice: 5100,
    slogan: "Shine bright on your reception night.",
    description:
        "A glamorous makeup look specially designed for reception events to enhance your beauty and elegance.",
    includes: [
      "Skin preparation",
      "Foundation and contouring",
      "Eye makeup",
      "Lip makeup",
      "Hair styling"
    ],
    process: [
      "Skin preparation",
      "Base makeup application",
      "Eye makeup styling",
      "Final finishing and setting"
    ],
  ),

  /// LIGHT MAKEUP
  SalonService(
    name: "Light Makeup",
    category: "Makeup",
    image: "assets/light_makeup.png",
    time: "40 minutes",
    price: 1500,
    discount: 10,
    finalPrice: 1350,
    slogan: "Simple and natural everyday makeup.",
    description:
        "A light and natural makeup look perfect for daily occasions and casual events.",
    includes: [
      "Skin preparation",
      "Light foundation",
      "Simple eye makeup",
      "Lip color"
    ],
    process: [
      "Skin preparation",
      "Light base makeup",
      "Eye makeup",
      "Final finishing"
    ],
  ),

  /// SPA MANICURE
  SalonService(
    name: "Spa Manicure",
    category: "Manicure",
    image: "assets/spa_manicure.png",
    time: "45 minutes",
    price: 700,
    discount: 15,
    finalPrice: 595,
    slogan: "Relaxing manicure with spa care.",
    description:
        "A relaxing manicure treatment that nourishes hands and nails while providing a soothing spa experience.",
    includes: [
      "Nail trimming",
      "Nail shaping",
      "Cuticle cleaning",
      "Hand scrub",
      "Hand massage",
      "Nail polish"
    ],
    process: [
      "Nail cleaning",
      "Nail shaping",
      "Cuticle care",
      "Hand scrub and massage",
      "Final polish"
    ],
  ),

  /// GEL MANICURE
  SalonService(
    name: "Gel Manicure",
    category: "Manicure",
    image: "assets/gel_manicure.png",
    time: "50 minutes",
    price: 900,
    discount: 15,
    finalPrice: 765,
    slogan: "Long lasting glossy gel nails.",
    description:
        "A professional gel manicure that provides long lasting shine and durable nail color.",
    includes: [
      "Nail trimming",
      "Nail shaping",
      "Cuticle care",
      "Gel polish application",
      "UV curing"
    ],
    process: [
      "Nail cleaning",
      "Nail shaping",
      "Gel polish application",
      "UV curing",
      "Final finishing"
    ],
  ),

  /// FRENCH MANICURE
  SalonService(
    name: "French Manicure",
    category: "Manicure",
    image: "assets/french_manicure.png",
    time: "45 minutes",
    price: 800,
    discount: 10,
    finalPrice: 720,
    slogan: "Elegant classic nail style.",
    description:
        "A classic manicure style featuring natural nails with elegant white tips.",
    includes: [
      "Nail trimming",
      "Nail shaping",
      "Cuticle cleaning",
      "French polish application"
    ],
    process: [
      "Nail cleaning",
      "Nail shaping",
      "French polish application",
      "Final finishing"
    ],
  ),

  /// SPA PEDICURE
  SalonService(
    name: "Spa Pedicure",
    category: "Pedicure",
    image: "assets/spa_pedicure.png",
    time: "60 minutes",
    price: 900,
    discount: 15,
    finalPrice: 765,
    slogan: "Relaxing spa treatment for feet.",
    description:
        "A soothing pedicure that cleans, exfoliates and relaxes your feet.",
    includes: [
      "Foot soak",
      "Foot scrub",
      "Cuticle care",
      "Foot massage",
      "Nail polish"
    ],
    process: [
      "Foot soaking",
      "Scrubbing and exfoliation",
      "Nail care",
      "Foot massage",
      "Polish application"
    ],
  ),

  /// GEL PEDICURE
  SalonService(
    name: "Gel Pedicure",
    category: "Pedicure",
    image: "assets/gel_pedicure.png",
    time: "60 minutes",
    price: 1000,
    discount: 15,
    finalPrice: 850,
    slogan: "Long lasting gel finish for toes.",
    description:
        "A gel pedicure that provides durable shine and long lasting color.",
    includes: [
      "Foot soak",
      "Nail shaping",
      "Cuticle care",
      "Gel polish",
      "UV curing"
    ],
    process: [
      "Foot soaking",
      "Nail preparation",
      "Gel polish application",
      "UV curing",
      "Final finishing"
    ],
  ),

  /// FOOT SPA PEDICURE
  SalonService(
    name: "Foot Spa Pedicure",
    category: "Pedicure",
    image: "assets/foot_spa_pedicure.png",
    time: "60 minutes",
    price: 1200,
    discount: 20,
    finalPrice: 960,
    slogan: "Deep relaxation and foot care.",
    description:
        "A luxury foot spa treatment that deeply cleans and rejuvenates tired feet.",
    includes: [
      "Foot soak",
      "Foot scrub",
      "Foot mask",
      "Foot massage",
      "Nail polish"
    ],
    process: [
      "Foot soaking",
      "Scrubbing and exfoliation",
      "Mask application",
      "Foot massage",
      "Final finishing"
    ],
  ),

  /// FULL LEGS WAX
  SalonService(
    name: "Full Legs Wax",
    category: "Waxing",
    image: "assets/full_legs_wax.png",
    time: "40 minutes",
    price: 600,
    discount: 10,
    finalPrice: 540,
    slogan: "Soft and silky legs.",
    description: "Professional waxing service for smooth and hair free legs.",
    includes: [
      "Skin preparation",
      "Wax application",
      "Hair removal",
      "Soothing gel"
    ],
    process: [
      "Skin preparation",
      "Wax application",
      "Hair removal",
      "Post wax soothing care"
    ],
  ),

  /// UNDERARMS WAX
  SalonService(
    name: "Underarms Wax",
    category: "Waxing",
    image: "assets/underarms_wax.png",
    time: "15 minutes",
    price: 200,
    discount: 10,
    finalPrice: 180,
    slogan: "Quick and hygienic waxing service.",
    description: "A quick waxing treatment to remove underarm hair safely.",
    includes: [
      "Skin preparation",
      "Wax application",
      "Hair removal",
      "Soothing gel"
    ],
    process: [
      "Skin preparation",
      "Wax application",
      "Hair removal",
      "Post wax care"
    ],
  ),

  /// FACE WAX
  SalonService(
    name: "Face Wax",
    category: "Waxing",
    image: "assets/face_wax.png",
    time: "15 minutes",
    price: 250,
    discount: 10,
    finalPrice: 225,
    slogan: "Gentle removal of facial hair.",
    description: "A gentle waxing service to remove unwanted facial hair.",
    includes: [
      "Skin preparation",
      "Wax application",
      "Hair removal",
      "Soothing gel"
    ],
    process: [
      "Skin preparation",
      "Wax application",
      "Hair removal",
      "Post wax soothing care"
    ],
  ),

  /// BIKINI WAX
  SalonService(
    name: "Bikini Wax",
    category: "Waxing",
    image: "assets/bikini_wax.png",
    time: "30 minutes",
    price: 1200,
    discount: 15,
    finalPrice: 1020,
    slogan: "Professional and hygienic intimate waxing.",
    description:
        "A professional waxing service designed for hygienic and safe intimate hair removal.",
    includes: [
      "Skin preparation",
      "Wax application",
      "Hair removal",
      "Skin soothing treatment"
    ],
    process: [
      "Skin preparation",
      "Wax application",
      "Hair removal",
      "Post wax soothing care"
    ],
  ),
];
