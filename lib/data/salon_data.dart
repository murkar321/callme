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

  /// MEN HAIR CUT
  SalonService(
    name: "Men Hair Cut",
    category: "Hair Cut",
    image: "assets/salon.png",
    time: "30 min",
    price: 300,
    discount: 20,
    finalPrice: 240,
    slogan: "Sharp and clean professional haircut.",
    description:
        "A professional haircut designed to give men a clean, stylish, and well-groomed appearance. Our expert stylists help choose the best haircut based on face shape and hair type.",
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

  /// WOMEN HAIR CUT
  SalonService(
    name: "Women Hair Cut",
    category: "Hair Cut",
    image: "assets/salon.png",
    time: "45 min",
    price: 600,
    discount: 15,
    finalPrice: 510,
    slogan: "Stylish haircut designed for your personality.",
    description:
        "A stylish haircut tailored to your personality and face shape. Our stylists create modern and elegant looks suitable for everyday styling.",
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

  /// HAIR SPA
  SalonService(
    name: "Hair Spa",
    category: "Hair Treatments",
    image: "assets/salon.png",
    time: "45 min",
    price: 800,
    discount: 15,
    finalPrice: 680,
    slogan: "Nourish and relax your hair.",
    description:
        "A nourishing hair treatment that repairs damaged hair, improves scalp health, and restores shine and softness.",
    includes: [
      "Hair analysis",
      "Hair wash",
      "Hair spa cream massage",
      "Steam treatment",
      "Hair mask",
      "Final rinse and styling"
    ],
    process: [
      "Hair and scalp analysis",
      "Hair wash",
      "Hair spa cream massage",
      "Steam therapy",
      "Hair mask application"
    ],
  ),

  /// KERATIN TREATMENT
  SalonService(
    name: "Keratin Treatment",
    category: "Hair Treatments",
    image: "assets/salon.png",
    time: "2 hours",
    price: 4000,
    discount: 25,
    finalPrice: 3000,
    slogan: "Shiny smooth and healthy hair.",
    description:
        "A smoothing hair treatment that reduces frizz and adds shine. It makes hair smooth, manageable, and healthy looking.",
    includes: [
      "Hair consultation",
      "Deep cleansing wash",
      "Keratin product application",
      "Heat sealing process",
      "Final styling"
    ],
    process: [
      "Hair wash",
      "Keratin application",
      "Heat sealing with straightener",
      "Final styling"
    ],
  ),

  /// BASIC FACIAL
  SalonService(
    name: "Basic Facial",
    category: "Facial",
    image: "assets/salon.png",
    time: "40 min",
    price: 700,
    discount: 15,
    finalPrice: 595,
    slogan: "Quick glow facial for everyday beauty.",
    description:
        "A refreshing facial treatment that cleanses the skin, removes impurities, and improves skin glow.",
    includes: [
      "Face cleansing",
      "Face scrub",
      "Face massage",
      "Face mask",
      "Moisturizer application"
    ],
    process: [
      "Skin cleansing",
      "Exfoliation with scrub",
      "Face massage",
      "Face pack application"
    ],
  ),

  /// BRIDAL MAKEUP
  SalonService(
    name: "Bridal Makeup",
    category: "Makeup",
    image: "assets/salon.png",
    time: "2 hours",
    price: 12000,
    discount: 15,
    finalPrice: 10200,
    slogan: "Perfect bridal glow for your special day.",
    description:
        "Professional bridal makeup designed to give the bride a flawless and radiant appearance on her wedding day.",
    includes: [
      "Skin preparation",
      "Foundation and contouring",
      "Eye makeup",
      "Lip makeup",
      "Hair styling"
    ],
    process: [
      "Skin preparation",
      "Base makeup",
      "Eye makeup",
      "Final finishing and setting"
    ],
  ),

  /// BASIC MANICURE
  SalonService(
    name: "Basic Manicure",
    category: "Manicure",
    image: "assets/salon.png",
    time: "30 min",
    price: 400,
    discount: 10,
    finalPrice: 360,
    slogan: "Clean and polished nails.",
    description:
        "A simple nail care treatment that cleans, shapes, and beautifies the nails and hands.",
    includes: [
      "Nail trimming",
      "Nail shaping",
      "Cuticle cleaning",
      "Hand massage",
      "Nail polish"
    ],
    process: [
      "Nail cleaning",
      "Nail shaping",
      "Cuticle care",
      "Hand massage and polish"
    ],
  ),

  /// BASIC PEDICURE
  SalonService(
    name: "Basic Pedicure",
    category: "Pedicure",
    image: "assets/salon.png",
    time: "40 min",
    price: 500,
    discount: 10,
    finalPrice: 450,
    slogan: "Clean and refreshed feet.",
    description:
        "A relaxing treatment for feet that cleans, exfoliates, and improves foot hygiene and comfort.",
    includes: [
      "Foot soak",
      "Foot scrub",
      "Cuticle care",
      "Foot massage",
      "Nail polish"
    ],
    process: [
      "Foot soaking",
      "Scrubbing and cleaning",
      "Nail care",
      "Foot massage"
    ],
  ),

  /// FULL ARMS WAX
  SalonService(
    name: "Full Arms Wax",
    category: "Waxing",
    image: "assets/salon.png",
    time: "30 min",
    price: 400,
    discount: 10,
    finalPrice: 360,
    slogan: "Smooth and hair free arms.",
    description:
        "A waxing service that removes unwanted hair from the arms, leaving the skin smooth and soft.",
    includes: [
      "Skin preparation",
      "Wax application",
      "Hair removal",
      "Skin soothing gel"
    ],
    process: [
      "Skin preparation",
      "Wax application",
      "Hair removal",
      "Post wax soothing care"
    ],
  ),
];