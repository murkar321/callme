class EducationService {
  final String id; // ✅ ADDED (important)
  final String name;
  final String category;
  final String image;
  final String duration;
  final int price;
  final int discount;
  final int finalPrice;
  final String description;

  EducationService({
    required this.id, // ✅ REQUIRED
    required this.name,
    required this.category,
    required this.image,
    required this.duration,
    required this.price,
    required this.discount,
    required this.finalPrice,
    required this.description,
  });

  get mainCategory => null;
}


final List<EducationService> educationServices = [

  /// =========================
  /// 🎓 ACADEMIC CLASSES
  /// =========================
  EducationService(
    id: "AC_1",
    name: "1st to 5th (Primary Foundation)",
    category: "Academic Classes",
    image: "assets/Education.jpg",
    duration: "1 Year",
    price: 5000,
    discount: 20,
    finalPrice: 4000,
    description:
        "All subjects (Maths, English, EVS, Hindi), reading-writing skills, homework help, activity learning, weekly tests.\nFees: ₹1,500–₹5,000/month",
  ),

  EducationService(
    id: "AC_2",
    name: "6th to 8th (Middle School)",
    category: "Academic Classes",
    image: "assets/Education.jpg",
    duration: "1 Year",
    price: 7000,
    discount: 20,
    finalPrice: 5600,
    description:
        "Maths, Science, English, SST, concept building, weekly tests, doubt solving.\nFees: ₹3,000–₹7,000/month",
  ),

  EducationService(
    id: "AC_3",
    name: "8th to 10th (Board Prep)",
    category: "Academic Classes",
    image: "assets/Education.jpg",
    duration: "1 Year",
    price: 10000,
    discount: 20,
    finalPrice: 8000,
    description:
        "Full syllabus, board prep, test series, previous papers, extra classes.\nFees: ₹4,000–₹10,000/month",
  ),

  EducationService(
    id: "AC_4",
    name: "11th to 12th (Senior Secondary)",
    category: "Academic Classes",
    image: "assets/Education.jpg",
    duration: "1-2 Years",
    price: 10000,
    discount: 15,
    finalPrice: 8500,
    description:
        "Science/Commerce/Arts streams, advanced preparation.\nJEE/NEET packages available.\nFees: ₹4,000–₹10,000/month",
  ),

  /// =========================
  /// 💻 COMPUTER COURSES
  /// =========================
  EducationService(
    id: "CC_1",
    name: "MS-CIT Course",
    category: "Computer Courses",
    image: "assets/Education.jpg",
    duration: "3-6 Months",
    price: 6200,
    discount: 5,
    finalPrice: 5900,
    description:
        "MS Office, internet, typing, digital literacy.\nFees: ₹4,500–₹6,200",
  ),

  EducationService(
    id: "CC_2",
    name: "Software Development",
    category: "Computer Courses",
    image: "assets/Education.jpg",
    duration: "6-12 Months",
    price: 150000,
    discount: 20,
    finalPrice: 120000,
    description:
        "Frontend, Backend, Database, projects, full stack training.\nFees: ₹50,000–₹1.5L",
  ),

  EducationService(
    id: "CC_3",
    name: "Graphic Design & Video Editing",
    category: "Computer Courses",
    image: "assets/Education.jpg",
    duration: "3-6 Months",
    price: 70000,
    discount: 15,
    finalPrice: 60000,
    description:
        "Photoshop, Illustrator, Premiere Pro, motion basics.\nFees: ₹20,000–₹70,000",
  ),

  EducationService(
    id: "CC_4",
    name: "Hardware & Networking",
    category: "Computer Courses",
    image: "assets/Education.jpg",
    duration: "6-12 Months",
    price: 120000,
    discount: 20,
    finalPrice: 96000,
    description:
        "CCNA basics, networking, troubleshooting, labs.\nFees: ₹40,000–₹1.2L",
  ),

  EducationService(
    id: "CC_5",
    name: "Digital Marketing",
    category: "Computer Courses",
    image: "assets/Education.jpg",
    duration: "4-8 Months",
    price: 80000,
    discount: 15,
    finalPrice: 68000,
    description:
        "SEO, Ads, Social Media, Analytics.\nFees: ₹25,000–₹80,000",
  ),

  EducationService(
    id: "CC_6",
    name: "Data Science",
    category: "Computer Courses",
    image: "assets/Education.jpg",
    duration: "6-12 Months",
    price: 150000,
    discount: 20,
    finalPrice: 120000,
    description:
        "Python, ML basics, analytics, visualization.\nFees: ₹50,000–₹1.5L",
  ),

  /// =========================
  /// 🏥 PARAMEDICAL COURSES
  /// =========================
  EducationService(
    id: "PM_1",
    name: "Basic Paramedical",
    category: "Paramedical Courses",
    image: "assets/Education.jpg",
    duration: "3-6 Months",
    price: 40000,
    discount: 10,
    finalPrice: 36000,
    description:
        "First aid, patient care, medical basics.\nFees: ₹10,000–₹40,000",
  ),

  EducationService(
    id: "PM_2",
    name: "Diploma in Paramedical",
    category: "Paramedical Courses",
    image: "assets/Education.jpg",
    duration: "1-2 Years",
    price: 150000,
    discount: 20,
    finalPrice: 120000,
    description:
        "Lab, radiology, hospital training.\nFees: ₹50,000–₹1.5L",
  ),

  /// =========================
  /// 🏛 GOVERNMENT COURSES
  /// =========================
  EducationService(
    id: "GC_1",
    name: "Government Exam Coaching",
    category: "Government Courses",
    image: "assets/Education.jpg",
    duration: "6-12 Months",
    price: 30000,
    discount: 10,
    finalPrice: 27000,
    description:
        "SSC, Banking, MPSC preparation.\nFees: ₹15,000–₹40,000",
  ),

  /// =========================
  /// 🎵 MUSIC CLASSES
  /// =========================
  EducationService(
    id: "MC_1",
    name: "Music Classes",
    category: "Music Classes",
    image: "assets/Education.jpg",
    duration: "3-6 Months",
    price: 5000,
    discount: 10,
    finalPrice: 4500,
    description:
        "Singing, instruments training.\nFocus: Hobby + skill",
  ),

  /// =========================
  /// 💄 SALON & PARLOUR COURSES
  /// =========================
  EducationService(
    id: "SP_1",
    name: "Basic Beautician",
    category: "Salon & Parlour",
    image: "assets/Education.jpg",
    duration: "1-2 Months",
    price: 30000,
    discount: 10,
    finalPrice: 27000,
    description:
        "Threading, waxing, basic makeup.\nFees: ₹10,000–₹30,000",
  ),

  EducationService(
    id: "SP_2",
    name: "Diploma in Beauty Parlour",
    category: "Salon & Parlour",
    image: "assets/Education.jpg",
    duration: "4-8 Months",
    price: 80000,
    discount: 15,
    finalPrice: 68000,
    description:
        "Advanced facials, hair, makeup.\nFees: ₹25,000–₹80,000",
  ),

  EducationService(
    id: "SP_3",
    name: "Advanced Bridal Makeup",
    category: "Salon & Parlour",
    image: "assets/Education.jpg",
    duration: "2-6 Months",
    price: 100000,
    discount: 20,
    finalPrice: 80000,
    description:
        "Bridal makeup, hairstyling.\nFees: ₹30,000–₹1L",
  ),

  /// =========================
  /// 💃 DANCE CLASSES
  /// =========================
  EducationService(
    id: "DC_1",
    name: "Dance Classes",
    category: "Dance Classes",
    image: "assets/Education.jpg",
    duration: "3-6 Months",
    price: 5000,
    discount: 10,
    finalPrice: 4500,
    description:
        "Hip-hop, freestyle, classical.\nFocus: Skill + hobby",
  ),

  /// =========================
  /// 📱 MOBILE REPAIRING
  /// =========================
  EducationService(
    id: "MR_1",
    name: "Mobile Repairing Training",
    category: "Mobile Repairing",
    image: "assets/Education.jpg",
    duration: "2-4 Months",
    price: 40000,
    discount: 10,
    finalPrice: 36000,
    description:
        "Hardware + software repair.\nFees: ₹20,000–₹60,000",
  ),
];