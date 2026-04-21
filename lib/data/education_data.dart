
class EducationService {
  final String id;
  final String name;
  final String category;
  final String image;

  final String description;

  final List<String> includes;
  final List<String> excludes;
  final List<String> steps;

  final String tools;
  final String duration;

  final int price;
  final int discount;
  final int finalPrice;

  final String warranty;

  EducationService({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.description,
    required this.includes,
    required this.excludes,
    required this.steps,
    required this.tools,
    required this.duration,
    required this.price,
    required this.discount,
    required this.finalPrice,
    required this.warranty,
  });

  /// ✅ FIX (this was wrong earlier)
  String get mainCategory => category;
}

final List<EducationService> educationServices = [

  /// 🎓 ACADEMIC CLASSES

  EducationService(
    id: "AC_1",
    name: "1st to 5th (Primary Foundation)",
    category: "Academic Classes",
    image: "assets/1st to 5th.png",
    description: "Build strong basics with activity-based learning",

    includes: [
      "All subjects (Maths, English, EVS, Hindi)",
      "Basic reading & writing skills",
      "Homework help",
      "Activity-based learning",
      "Weekly tests"
    ],

    excludes: [
      "Advanced competitive exam preparation"
    ],

    steps: [
      "Concept explanation",
      "Practice worksheets",
      "Weekly tests",
      "Performance tracking"
    ],

    tools: "Books, Worksheets, Activity Kits",
    duration: "1 Year (April–March)",

    price: 35000,
    discount: 20,
    finalPrice: 28000,

    warranty: "Academic support throughout course",
  ),

  EducationService(
    id: "AC_2",
    name: "6th to 8th (Middle School)",
    category: "Academic Classes",
    image: "assets/6th to 8th.png",
    description: "Concept building and subject strengthening",

    includes: [
      "Maths, Science, English, SST",
      "Concept building sessions",
      "Weekly tests",
      "Doubt solving",
      "Notes & revision sessions"
    ],

    excludes: [
      "Board-level exam preparation"
    ],

    steps: [
      "Concept teaching",
      "Practice sessions",
      "Doubt clearing",
      "Weekly assessment"
    ],

    tools: "Notes, Practice Papers, Digital Content",
    duration: "1 Year",

    price: 40000,
    discount: 20,
    finalPrice: 32000,

    warranty: "Full academic year support",
  ),

  EducationService(
    id: "AC_3",
    name: "9th to 10th (Board Preparation)",
    category: "Academic Classes",
    image: "assets/9th to 10th.png",
    description: "Complete board exam preparation with test series",

    includes: [
      "Full syllabus coverage",
      "Board exam preparation",
      "Test series & previous papers",
      "Extra classes before exams",
      "Personal doubt sessions"
    ],

    excludes: [
      "Entrance exam coaching (JEE/NEET)"
    ],

    steps: [
      "Syllabus completion",
      "Revision cycles",
      "Test series",
      "Final exam preparation"
    ],

    tools: "Previous Papers, Test Series, Notes",
    duration: "1 Year",

    price: 60000,
    discount: 20,
    finalPrice: 48000,

    warranty: "Support till board exams",
  ),

  EducationService(
    id: "AC_4",
    name: "11th to 12th (Senior Secondary)",
    category: "Academic Classes",
    image: "assets/11th to 12th.png",
    description: "Stream-based preparation (Science/Commerce/Arts)",

    includes: [
      "Stream-specific subjects",
      "Concept clarity sessions",
      "Revision & test series",
      "Doubt solving",
      "Career guidance support"
    ],

    excludes: [
      "Full JEE/NEET coaching (separate package)"
    ],

    steps: [
      "Concept teaching",
      "Advanced problem solving",
      "Regular tests",
      "Final revision"
    ],

    tools: "Reference Books, Test Series, Notes",
    duration: "1–2 Years",

    price: 100000,
    discount: 20,
    finalPrice: 80000,

    warranty: "Full course academic support",
  ),
  
/// MSC-IT Courses
  EducationService(
    id: "MSC_1",
    name: "Basic MS-CIT",
    category: "MS-CIT Courses",
    image: "assets/msc1.jpeg",
    description: "Computer basics & MS Office",

    includes: [
      "MS Word, Excel",
      "Internet basics",
      "Email"
    ],
    excludes: [],
    steps: ["Basics", "Practice"],
    tools: "MS Office",
    duration: "2–4 Months",

    price: 6000,
    discount: 10,
    finalPrice: 5400,

    warranty: "Certificate support",
  ),

  EducationService(
    id: "MSC_2",
    name: "Standard MS-CIT",
    category: "MS-CIT Courses",
    image:"assets/msc2.jpeg",
    description: "Full MS-CIT course",

    includes: [
      "Computer fundamentals",
      "Lab sessions",
      "Exam"
    ],
    excludes: [],
    steps: ["Training"],
    tools: "MS Office",
    duration: "3–6 Months",

    price: 6200,
    discount: 5,
    finalPrice: 5900,

    warranty: "Certification",
  ),

  EducationService(
    id: "MSC_3",
    name: "MS-CIT + Advanced",
    category: "MS-CIT Courses",
    image: "assets/msc3.jpeg",
    description: "MS-CIT + extra skills",

    includes: [
      "Advanced Excel",
      "Typing",
      "Basic Tally"
    ],
    excludes: [],
    steps: ["Training", "Practice"],
    tools: "MS Office",
    duration: "4–8 Months",

    price: 30000,
    discount: 20,
    finalPrice: 24000,

    warranty: "Skill support",
  ),

  EducationService(
    id: "MSC_4",
    name: "Job-Oriented MS-CIT",
    category: "MS-CIT Courses",
    image: "assets/msc4.jpeg",
    description: "Office job training",

    includes: [
      "Data entry",
      "Typing",
      "Resume prep"
    ],
    excludes: [],
    steps: ["Practice", "Interview prep"],
    tools: "MS Office",
    duration: "3–6 Months",

    price: 25000,
    discount: 20,
    finalPrice: 20000,

    warranty: "Job guidance",
  ),


/// Software Enginerring
EducationService(
  id: "PROG_1",
  name: "Programming & Software Course (Basic)",
  category: "Software & Programming",
  image: "assets/programming_basic.png",

  description:
      "Learn computer fundamentals, MS Office, internet basics, and introduction to programming for beginners.",

  includes: [
    "Computer Fundamentals",
    "MS Office (Word, Excel, PowerPoint)",
    "Internet & Email Basics",
    "Introduction to Programming",
    "Basic HTML & CSS"
  ],

  excludes: [
    "Advanced Programming Languages",
    "Live Project Work"
  ],

  steps: [
    "Basic Computer Training",
    "Office Tools Practice",
    "Internet Usage Training",
    "Intro to Coding",
    "Mini Practice Tasks"
  ],

  tools: "Computer Lab, Notes, Practice Files",
  duration: "3 Months",

  price: 12000,
  discount: 2000,
  finalPrice: 10000,

  warranty: "Basic Computer & Software Skills",
),
EducationService(
  id: "PROG_2",
  name: "Programming & Software Course (Advance)",
  category: "Software & Programming",
  image: "assets/programming_advance.png",

  description:
      "Advanced programming course covering multiple languages, web development, and real-world project experience.",

  includes: [
    "C & C++ Programming",
    "Core Java / Python",
    "HTML, CSS, JavaScript",
    "Database (MySQL)",
    "Basic App / Web Development",
    "Live Project Work"
  ],

  excludes: [
    "Specialized Frameworks (optional extra)"
  ],

  steps: [
    "Programming Fundamentals",
    "Language Training (C/C++/Java/Python)",
    "Web Development Basics",
    "Database Integration",
    "Live Project Development"
  ],

  tools: "Code Editor, IDEs, Project Work",
  duration: "6 Months",

  price: 30000,
  discount: 5000,
  finalPrice: 25000,

  warranty: "Job Assistance & Interview Preparation",
),

/// Data Science
  EducationService(
    id: "DS_1",
    name: "Basic Data Science Course",
    category: "Data Science",
    image: "assets/data1.png",
    description: "Beginner course for data handling and Python basics",

    includes: [
      "Excel basics",
      "Introduction to data science",
      "Basic statistics",
      "Python basics"
    ],
    excludes: ["Machine learning"],
    steps: ["Basics", "Practice", "Mini tasks"],
    tools: "Excel, Python",
    duration: "2–4 Months",

    price: 50000,
    discount: 40,
    finalPrice: 30000,

    warranty: "Basic training support",
  ),

 
  EducationService(
    id: "DS_2",
    name: "Certificate in Data Science",
    category: "Data Science",
    image: "assets/data2.png",
    description: "Foundation course for data analysis",

    includes: [
      "Python for data analysis",
      "SQL basics",
      "Data visualization",
      "Pandas, NumPy"
    ],
    excludes: [],
    steps: ["Training", "Practice", "Assignments"],
    tools: "Python, SQL",
    duration: "3–6 Months",

    price: 80000,
    discount: 30,
    finalPrice: 56000,

    warranty: "Course certificate",
  ),

 
  EducationService(
    id: "DS_3",
    name: "Diploma in Data Science",
    category: "Data Science",
    image: "assets/data3.png",
    description: "Job-ready data analyst training",

    includes: [
      "Python + R",
      "Machine learning basics",
      "Power BI / Tableau",
      "Projects"
    ],
    excludes: [],
    steps: ["Training", "Projects", "Case studies"],
    tools: "Python, Power BI",
    duration: "6–12 Months",

    price: 150000,
    discount: 30,
    finalPrice: 105000,

    warranty: "Project support",
  ),

  EducationService(
    id: "DS_4",
    name: "Advanced Data Science Course",
    category: "Data Science",
    image: "assets/data4.png",
    description: "Professional AI & machine learning course",

    includes: [
      "Machine Learning",
      "Deep Learning intro",
      "Big Data basics",
      "Advanced Python"
    ],
    excludes: [],
    steps: ["Advanced training", "Projects", "Portfolio"],
    tools: "Python, ML tools",
    duration: "8–18 Months",

    price: 250000,
    discount: 20,
    finalPrice: 200000,

    warranty: "Career support",
  ),

 
  EducationService(
    id: "DS_5",
    name: "Specialized Data Courses",
    category: "Data Science",
    image: "assets/data5.png",
    description: "Skill-based courses like Analytics, ML, AI",

    includes: [
      "Data Analytics",
      "Machine Learning",
      "AI basics",
      "Business analytics"
    ],
    excludes: [],
    steps: ["Skill training", "Practice"],
    tools: "Excel, Python",
    duration: "2–6 Months",

    price: 80000,
    discount: 25,
    finalPrice: 60000,

    warranty: "Skill support",
  ),


/// Networking
  EducationService(
    id: "NW_1",
    name: "Basic Networking",
    category: "Networking",
    image: "assets/network1.png",
    description: "Networking fundamentals",

    includes: [
      "LAN, WAN",
      "IP basics",
      "Devices"
    ],
    excludes: [],
    steps: ["Theory", "Practice"],
    tools: "Networking tools",
    duration: "2–4 Months",

    price: 40000,
    discount: 25,
    finalPrice: 30000,

    warranty: "Basic support",
  ),

  EducationService(
    id: "NW_2",
    name: "Certificate in Networking",
    category: "Networking",
    image: "assets/network2.png",
    description: "CCNA basics",

    includes: [
      "Routing & switching",
      "Networking fundamentals"
    ],
    excludes: [],
    steps: ["Training", "Labs"],
    tools: "Cisco tools",
    duration: "3–6 Months",

    price: 60000,
    discount: 20,
    finalPrice: 48000,

    warranty: "Lab support",
  ),

  EducationService(
    id: "NW_3",
    name: "Diploma in Networking",
    category: "Networking",
    image: "assets/network3.png",
    description: "Hardware + networking",

    includes: [
      "CCNA + MCSA",
      "Troubleshooting"
    ],
    excludes: [],
    steps: ["Training", "Practice"],
    tools: "Networking hardware",
    duration: "6–12 Months",

    price: 120000,
    discount: 25,
    finalPrice: 90000,

    warranty: "Job support",
  ),

  EducationService(
    id: "NW_4",
    name: "Advanced Networking",
    category: "Networking",
    image: "assets/network4.png",
    description: "Professional networking",

    includes: [
      "CCNP",
      "Security basics",
      "Cloud intro"
    ],
    excludes: [],
    steps: ["Advanced training"],
    tools: "Cisco tools",
    duration: "8–12 Months",

    price: 200000,
    discount: 25,
    finalPrice: 150000,

    warranty: "Career support",
  ),

  EducationService(
    id: "NW_5",
    name: "Specialized Networking",
    category: "Networking",
    image: "assets/network5.png",
    description: "Cybersecurity, cloud",

    includes: [
      "Ethical hacking",
      "Cloud networking"
    ],
    excludes: [],
    steps: ["Skill training"],
    tools: "Security tools",
    duration: "2–6 Months",

    price: 80000,
    discount: 25,
    finalPrice: 60000,

    warranty: "Skill support",
  ),

/// Digital Marketing
/// Graphic Desiging 

/// Government Courses
/// 🔹 MPSC
EducationService(
  id: "GOV_1",
  name: "MPSC Preparation Course",
  category: "Government Exam Courses",
  image: "assets/MPSC.png",

  description:
      "Comprehensive preparation for Maharashtra Public Service Commission exams including Prelims and Mains.",

  includes: [
    "Prelims & Mains Syllabus",
    "General Studies (History, Polity, Geography)",
    "Current Affairs",
    "CSAT Preparation",
    "Mock Tests & Analysis"
  ],

  excludes: [
    "Interview Guidance (optional extra)"
  ],

  steps: [
    "Concept Learning",
    "Subject-wise Preparation",
    "Mock Test Practice",
    "Performance Analysis"
  ],

  tools: "Study Material, Test Series, Notes",
  duration: "6–12 Months",

  price: 60000,
  discount: 20000,
  finalPrice: 40000,

  warranty: "Guidance for State Government Exams",
),

/// 🔹 UPSC
EducationService(
  id: "GOV_2",
  name: "UPSC Preparation Course",
  category: "Government Exam Courses",
  image: "assets/UPSC.png",

  description:
      "Complete training for UPSC Civil Services including IAS, IPS with Prelims, Mains, and Interview preparation.",

  includes: [
    "IAS Prelims, Mains & Interview",
    "NCERT + Advanced Subjects",
    "Essay Writing Practice",
    "Current Affairs (In-depth)",
    "Personality Development"
  ],

  excludes: [
    "Optional Subject Coaching (extra cost)"
  ],

  steps: [
    "Foundation Course",
    "Advanced Subject Training",
    "Answer Writing Practice",
    "Interview Preparation"
  ],

  tools: "Books, Notes, Mock Interviews",
  duration: "1–2 Years",

  price: 150000,
  discount: 30000,
  finalPrice: 120000,

  warranty: "Interview & Career Guidance",
),

/// 🔹 Railway
EducationService(
  id: "GOV_3",
  name: "Railway (RRB) Preparation",
  category: "Government Exam Courses",
  image: "assets/RRB.png",

  description:
      "Preparation course for Railway Recruitment Board exams with focus on aptitude and technical subjects.",

  includes: [
    "Mathematics & Reasoning",
    "General Awareness",
    "Technical Subjects",
    "Previous Year Papers",
    "Online Test Series"
  ],

  excludes: [
    "Advanced Technical Coaching (optional)"
  ],

  steps: [
    "Basic Concept Training",
    "Practice Sessions",
    "Previous Papers Solving",
    "Online Mock Tests"
  ],

  tools: "Practice Sets, Test Series",
  duration: "3–6 Months",

  price: 30000,
  discount: 10000,
  finalPrice: 20000,

  warranty: "Railway Exam Guidance",
),

/// 🔹 Banking
EducationService(
  id: "GOV_4",
  name: "Banking (IBPS / SBI) Preparation",
  category: "Government Exam Courses",
  image: "assets/SBI.png",

  description:
      "Complete course for banking exams like IBPS and SBI with aptitude, reasoning, and interview preparation.",

  includes: [
    "Quantitative Aptitude",
    "Reasoning Ability",
    "English Language",
    "Computer Awareness",
    "Interview Preparation"
  ],

  excludes: [
    "Advanced Interview Coaching (optional)"
  ],

  steps: [
    "Concept Building",
    "Speed Practice",
    "Mock Exams",
    "Interview Preparation"
  ],

  tools: "Mock Tests, Study Material",
  duration: "4–8 Months",

  price: 40000,
  discount: 10000,
  finalPrice: 30000,

  warranty: "Banking Career Guidance",
),

/// 🔹 SSC
EducationService(
  id: "GOV_5",
  name: "SSC & Government Exams Preparation",
  category: "Government Exam Courses",
  image: "assets/SSC.png",

  description:
      "Preparation for SSC exams like CGL, CHSL, GD with focus on core subjects and practice.",

  includes: [
    "SSC CGL, CHSL, GD Syllabus",
    "Maths, Reasoning & English",
    "General Knowledge",
    "Mock Tests & Practice Sets"
  ],

  excludes: [
    "Department-specific training"
  ],

  steps: [
    "Concept Learning",
    "Practice Sessions",
    "Mock Tests",
    "Revision"
  ],

  tools: "Notes, Practice Papers",
  duration: "4–8 Months",

  price: 35000,
  discount: 8000,
  finalPrice: 27000,

  warranty: "Central Government Exam Guidance",
),

/// Beautician Courses
EducationService(
  id: "BEAUTY_1",
  name: "Basic Beautician Course (Starter Package)",
  category: "Beautician Courses",
  image: "assets/basic beauti.png",
  description: "Beginner level course for starting beauty career",

  includes: [
    "Threading, waxing, cleanup",
    "Basic facials",
    "Simple hairstyles",
    "Basic makeup (day/party look)"
  ],

  excludes: [
    "Advanced makeup & skin treatments"
  ],

  steps: [
    "Basic training sessions",
    "Hands-on practice",
    "Client handling basics",
    "Final assessment"
  ],

  tools: "Basic salon tools & kits",
  duration: "1–2 Months",

  price: 30000,
  discount: 20,
  finalPrice: 24000,

  warranty: "Basic training support",
),

EducationService(
  id: "BEAUTY_2",
  name: "Certificate Course (Beauty & Makeup)",
  category: "Beautician Courses",
  image: "assets/beauti course.jpg",
  description: "Intermediate beauty and makeup course",

  includes: [
    "Skincare & facials",
    "Hair cutting & styling basics",
    "Makeup techniques",
    "Mehendi & grooming basics"
  ],

  excludes: [
    "Bridal & advanced makeup"
  ],

  steps: [
    "Theory sessions",
    "Practical training",
    "Practice on models",
    "Evaluation"
  ],

  tools: "Makeup kits, Hair tools",
  duration: "2–4 Months",

  price: 50000,
  discount: 20,
  finalPrice: 40000,

  warranty: "Practice support included",
),

EducationService(
  id: "BEAUTY_3",
  name: "Diploma in Beauty Parlour (Professional Package)",
  category: "Beautician Courses",
  image: "assets/professional beauti.jfif",
  description: "Complete professional salon training course",

  includes: [
    "Advanced facials & skin treatments",
    "Hair cutting, coloring & styling",
    "Makeup (bridal + party)",
    "Manicure, pedicure, nail art",
    "Salon hygiene & client handling"
  ],

  excludes: [
    "Business setup training"
  ],

  steps: [
    "Professional training",
    "Hands-on practice",
    "Client interaction",
    "Certification"
  ],

  tools: "Salon equipment, Professional kits",
  duration: "4–8 Months",

  price: 80000,
  discount: 20,
  finalPrice: 64000,

  warranty: "Job support guidance",
),

EducationService(
  id: "BEAUTY_4",
  name: "Advanced / Bridal Makeup Course",
  category: "Beautician Courses",
  image: "assets/bridal makeup.jfif",
  description: "Specialized course for bridal and fashion makeup",

  includes: [
    "Bridal makeup (HD, airbrush basics)",
    "Party & fashion makeup",
    "Bridal hairstyling",
    "Portfolio creation"
  ],

  excludes: [
    "Basic beginner training"
  ],

  steps: [
    "Advanced techniques",
    "Live model practice",
    "Portfolio building",
    "Final certification"
  ],

  tools: "Advanced makeup kits",
  duration: "2–6 Months",

  price: 100000,
  discount: 20,
  finalPrice: 80000,

  warranty: "Career guidance support",
),

EducationService(
  id: "BEAUTY_5",
  name: "Master / Pro Salon Course (Full Package)",
  category: "Beautician Courses",
  image: "assets/advaced beauti.jfif",
  description: "Complete salon career course with business training",

  includes: [
    "Full beauty + hair + makeup training",
    "Advanced skin treatments",
    "Spa & salon management",
    "Live client practice",
    "Business setup training"
  ],

  excludes: [
    "Short-term crash training"
  ],

  steps: [
    "Complete training modules",
    "Hands-on practice",
    "Client handling",
    "Business training"
  ],

  tools: "Full professional salon setup",
  duration: "6–12 Months",

  price: 200000,
  discount: 20,
  finalPrice: 160000,

  warranty: "Full career support",
),


/// Paramedical Courses
EducationService(
  id: "PM_1",
  name: "Diploma in Medical Lab Technician (DMLT)",
  category: "Paramedical Courses",
  image: "assets/dmlt.jpg",

  description:
      "Learn diagnostic testing, lab procedures, and medical equipment handling.",

  includes: [
    "Blood & Urine Testing",
    "Lab Equipment Handling",
    "Practical Lab Training",
    "Certification Support",
    "Job Assistance"
  ],

  excludes: [
    "Advanced medical specialization"
  ],

  steps: [
    "Theory classes",
    "Lab practical training",
    "Assessment tests",
    "Final certification"
  ],

  tools: "Lab Kits, Testing Equipment, Study Materials",
  duration: "12 Months",

  price: 55000,
  discount: 0,
  finalPrice: 55000,

  warranty: "Placement assistance provided",
),

EducationService(
  id: "PM_2",
  name: "Diploma in Operation Theatre Technician (OTT)",
  category: "Paramedical Courses",
  image: "assets/ott.jpg",

  description:
      "Train for assisting in surgeries, handling OT equipment, and patient care.",

  includes: [
    "Surgery Assistance Training",
    "OT Equipment Handling",
    "Patient Care Basics",
    "Hospital Exposure",
    "Certification"
  ],

  excludes: [
    "Doctor-level surgical training"
  ],

  steps: [
    "Concept learning",
    "OT practical training",
    "Live observation",
    "Final assessment"
  ],

  tools: "OT Equipment, Surgical Tools, Study Notes",
  duration: "12 Months",

  price: 60000,
  discount: 0,
  finalPrice: 60000,

  warranty: "Internship support available",
),

EducationService(
  id: "PM_3",
  name: "Diploma in X-Ray Technician",
  category: "Paramedical Courses",
  image: "assets/xray.jpg",

  description:
      "Learn radiology basics and X-ray machine handling for diagnostics.",

  includes: [
    "Radiology Basics",
    "X-Ray Machine Handling",
    "Safety Procedures",
    "Practical Training",
    "Certification"
  ],

  excludes: [
    "Advanced radiology specialization"
  ],

  steps: [
    "Theory sessions",
    "Machine training",
    "Practice sessions",
    "Certification"
  ],

  tools: "X-Ray Equipment, Lab Access, Notes",
  duration: "12 Months",

  price: 70000,
  discount: 0,
  finalPrice: 70000,

  warranty: "Job guidance support",
),

EducationService(
  id: "PM_4",
  name: "Diploma in Nursing Assistant",
  category: "Paramedical Courses",
  image: "assets/nursing.jpg",

  description:
      "Basic healthcare training including patient care and hospital duties.",

  includes: [
    "Patient Care Training",
    "First Aid",
    "Hospital Duties",
    "Practical Sessions",
    "Certification"
  ],

  excludes: [
    "Registered nurse qualification"
  ],

  steps: [
    "Basic theory",
    "Practical training",
    "Hospital exposure",
    "Final exam"
  ],

  tools: "Medical Kits, Notes, Practice Sessions",
  duration: "6–12 Months",

  price: 45000,
  discount: 0,
  finalPrice: 45000,

  warranty: "Placement support available",
),

EducationService(
  id: "PM_5",
  name: "Diploma in ECG Technician",
  category: "Paramedical Courses",
  image: "assets/ecg.jpg",

  description:
      "Learn ECG machine usage and heart monitoring techniques.",

  includes: [
    "ECG Machine Training",
    "Heart Monitoring", 
    "Practical Sessions",
    "Certification",
    "Job Assistance"
  ],

  excludes: [
    "Advanced cardiology training"
  ],

  steps: [
    "Concept learning",
    "Machine practice",
    "Patient monitoring",
    "Final test"
  ],

  tools: "ECG Machine, Study Material",
  duration: "6 Months",

  price: 35000,
  discount: 0,
  finalPrice: 35000,

  warranty: "Clinic placement support",
),

EducationService(
  id: "PM_6",
  name: "Diploma in Pharmacy Assistant",
  category: "Paramedical Courses",
  image: "assets/pharmacy.jpg",

  description:
      "Learn medicine handling, billing, and medical store management.",

  includes: [
    "Medicine Knowledge",
    "Billing System",
    "Store Management",
    "Customer Handling",
    "Certification"
  ],

  excludes: [
    "Pharmacist license (D.Pharm required)"
  ],

  steps: [
    "Theory training",
    "Store handling practice",
    "Billing training",
    "Final certification"
  ],

  tools: "Billing Software, Notes, Practical Training",
  duration: "6–12 Months",

  price: 50000,
  discount: 0,
  finalPrice: 50000,

  warranty: "Medical store job assistance",
),



/// English Speaking Courses
EducationService(
  id: "ENG_1",
  name: "Basic English Speaking Course",
  category: "English Speaking Courses",
  image: "assets/basic_english.png",

  description:
      "Beginner-friendly course to build basic English speaking, grammar, and daily communication skills.",

  includes: [
    "Basic Grammar (Tenses, Sentence Formation)",
    "Daily Use Sentences",
    "Vocabulary Building",
    "Basic Conversation Practice",
    "Introduction Speaking"
  ],

  excludes: [
    "Advanced Communication Training"
  ],

  steps: [
    "Grammar Basics",
    "Sentence Practice",
    "Vocabulary Sessions",
    "Speaking Practice"
  ],

  tools: "Notes, Practice Sheets, Speaking Sessions",
  duration: "1–2 Months",

  price: 8000,
  discount: 3000,
  finalPrice: 5000,

  warranty: "Basic Communication Improvement",
),

/// 🔹 Intermediate English
EducationService(
  id: "ENG_2",
  name: "Intermediate English Speaking Course",
  category: "English Speaking Courses",
  image: "assets/inter_english.png",

  description:
      "Improve fluency, confidence, and real-life communication through interactive sessions.",

  includes: [
    "Spoken Fluency Improvement",
    "Group Discussion Practice",
    "Confidence Building",
    "Pronunciation Training",
    "Situational Conversations"
  ],

  excludes: [
    "Advanced Corporate Training"
  ],

  steps: [
    "Fluency Practice",
    "Group Discussions",
    "Pronunciation Training",
    "Confidence Sessions"
  ],

  tools: "Audio Practice, Group Activities",
  duration: "2–3 Months",

  price: 15000,
  discount: 4000,
  finalPrice: 11000,

  warranty: "Fluency & Confidence Development",
),

/// 🔹 Advanced English
EducationService(
  id: "ENG_3",
  name: "Advanced / Professional English Course",
  category: "English Speaking Courses",
  image: "assets/advanced_english.png",

  description:
      "Professional-level English training for interviews, public speaking, and corporate communication.",

  includes: [
    "Public Speaking Skills",
    "Interview Preparation",
    "Presentation Skills",
    "Accent Training",
    "Business Communication"
  ],

  excludes: [
    "Foreign Language Training"
  ],

  steps: [
    "Advanced Communication Training",
    "Public Speaking Practice",
    "Interview Preparation",
    "Corporate Communication"
  ],

  tools: "Mock Interviews, Presentation Practice",
  duration: "3–6 Months",

  price: 30000,
  discount: 8000,
  finalPrice: 22000,

  warranty: "Professional Communication Skills",
),

 
/// Air Hostess
/// Dance Class
/// Music Class
/// Mobile Repairing


];
