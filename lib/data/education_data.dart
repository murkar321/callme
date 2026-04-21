
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
/// 🔹 Basic Digital Marketing
EducationService(
  id: "DM_1",
  name: "Basic Digital Marketing Course",
  category: "IT & Software Courses",
  image: "assets/digital1.png",

  description:
      "Learn the fundamentals of digital marketing including social media, content creation, and basic promotion strategies.",

  includes: [
    "Digital Marketing Introduction",
    "Social Media Marketing (Facebook, Instagram)",
    "Basic Content Creation",
    "Canva Designing (Basic)",
    "Email Marketing (Basics)",
    "WhatsApp Marketing",
    "Blogging Basics"
  ],

  excludes: [
    "Advanced Ads & SEO",
    "Freelancing Training"
  ],

  steps: [
    "Marketing Basics Learning",
    "Social Media Practice",
    "Content Creation",
    "Campaign Setup Practice"
  ],

  tools: "Canva, Mailchimp",
  duration: "2 Months",

  price: 12000,
  discount: 2000,
  finalPrice: 10000,

  warranty: "Basic Marketing & Promotion Skills",
),

/// 🔹 Advance Digital Marketing
EducationService(
  id: "DM_2",
  name: "Advance Digital Marketing Course",
  category: "IT & Software Courses",
  image: "assets/digital2.png",

  description:
      "Advanced course covering complete digital marketing strategy, ads, SEO, website creation, and freelancing skills.",

  includes: [
    "Complete Digital Marketing Strategy",
    "Social Media Ads (Facebook, Instagram)",
    "Search Engine Optimization (SEO)",
    "Search Engine Marketing (Google Ads)",
    "Website Creation (WordPress)",
    "Content Marketing Strategy",
    "Affiliate Marketing",
    "Freelancing & Client Handling"
  ],

  excludes: [
    "Agency-Level Scaling Training"
  ],

  steps: [
    "Strategy Learning",
    "Ads & SEO Training",
    "Website Development",
    "Live Project Practice",
    "Freelancing Setup"
  ],

  tools: "Google Ads, Google Analytics, WordPress, Canva",
  duration: "4 Months",

  price: 30000,
  discount: 5000,
  finalPrice: 25000,

  warranty: "Job Ready Skills & Freelancing Support",
),

/// Graphic Desiging
/// 🔹 Basic Graphic Design (DTP)
EducationService(
  id: "DESIGN_1",
  name: "Basic Graphic Design (DTP)",
  category: "IT & Software Courses",
  image: "assets/graphic2.png",

  description:
      "Learn basic graphic designing and desktop publishing (DTP) tools for printing and small business needs.",

  includes: [
    "Adobe Photoshop (Basic)",
    "CorelDRAW",
    "PageMaker / Canva (Basic)",
    "Visiting Card Design",
    "Banner & Poster Design",
    "Pamphlet / Flyer Design",
    "Basic Photo Editing",
    "Printing Setup (DTP Work)"
  ],

  excludes: [
    "Advanced Branding & UI Design",
    "Freelancing Training"
  ],

  steps: [
    "Software Basics Training",
    "Design Practice (Cards, Banners)",
    "Photo Editing Practice",
    "Printing Setup Learning"
  ],

  tools: "Photoshop, CorelDRAW, Canva",
  duration: "3 Months",

  price: 15000,
  discount: 3000,
  finalPrice: 12000,

  warranty: "Basic Graphic & Printing Skills",
),

/// 🔹 Advance Graphic Design
EducationService(
  id: "DESIGN_2",
  name: "Advance Graphic Design + Job Ready",
  category: "IT & Software Courses",
  image: "assets/graphic3.png",

  description:
      "Professional graphic design course covering branding, social media creatives, UI basics, and freelancing skills.",

  includes: [
    "Adobe Photoshop (Advance)",
    "Adobe Illustrator",
    "CorelDRAW",
    "Canva (Pro Level)",
    "Figma (Basic UI Design)",
    "Logo & Branding Design",
    "Social Media Creatives",
    "Ads Design (Instagram / Facebook)",
    "Photo Manipulation",
    "Packaging Design",
    "Basic UI Design",
    "Live Project Work"
  ],

  excludes: [
    "Advanced UI/UX Specialization"
  ],

  steps: [
    "Advanced Software Training",
    "Design Projects",
    "Portfolio Creation",
    "Freelancing Guidance",
    "Interview Preparation"
  ],

  tools: "Photoshop, Illustrator, Figma, Canva",
  duration: "6 Months",

  price: 35000,
  discount: 7000,
  finalPrice: 28000,

  warranty: "Job Assistance & Freelancing Support",
), 

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
/// 🔹 Basic Beautician Package
EducationService(
  id: "BEAUTY_1",
  name: "Beautician Course (Basic Package)",
  category: "Beauty & Makeup Courses",
  image: "assets/beauti1.png",

  description:
      "Beginner-level course covering essential parlour skills to start small earning or basic work.",

  includes: [
    "Threading, Waxing, Cleanup",
    "Basic Facials",
    "Simple Hairstyles",
    "Basic Makeup (Day/Party Look)",
    "Grooming Basics"
  ],

  excludes: [
    "Advanced Skin Treatments",
    "Bridal Makeup"
  ],

  steps: [
    "Basic Training",
    "Practice Sessions",
    "Client Handling Basics"
  ],

  tools: "Basic Parlour Kit, Practice Material",
  duration: "1–2 Months",

  price: 30000,
  discount: 10000,
  finalPrice: 20000,

  warranty: "Parlour Basics + Small Earning Start",
),

/// 🔹 Advanced Beautician Package
EducationService(
  id: "BEAUTY_2",
  name: "Beautician Course (Advanced Package)",
  category: "Beauty & Makeup Courses",
  image: "assets/beauti2.png",

  description:
      "Intermediate to professional course covering makeup, hair styling, and salon-level skills.",

  includes: [
    "Skincare + Advanced Facials",
    "Hair Cutting & Styling",
    "Makeup Techniques",
    "Mehendi + Grooming",
    "Manicure, Pedicure, Nail Art",
    "Salon Hygiene & Client Handling"
  ],

  excludes: [
    "Advanced Bridal HD Makeup",
    "Business Setup Training"
  ],

  steps: [
    "Skill Training",
    "Hands-on Practice",
    "Salon Techniques",
    "Client Practice"
  ],

  tools: "Professional Kits, Practice Setup",
  duration: "3–6 Months",

  price: 80000,
  discount: 20000,
  finalPrice: 60000,

  warranty: "Job Ready Salon Skills",
),

/// 🔹 Premium Beautician Package
EducationService(
  id: "BEAUTY_3",
  name: "Beautician Course (Premium Package)",
  category: "Beauty & Makeup Courses",
  image: "assets/beauti3.png",

  description:
      "Complete professional course including bridal makeup, advanced treatments, and salon business training.",

  includes: [
    "Bridal Makeup (HD, Airbrush Basics)",
    "Party & Fashion Makeup",
    "Advanced Hairstyling",
    "Advanced Skin Treatments",
    "Spa & Salon Management",
    "Live Client Practice",
    "Portfolio Creation",
    "Business Setup Training"
  ],

  excludes: [
    "International Certification"
  ],

  steps: [
    "Advanced Training",
    "Live Practice",
    "Portfolio Building",
    "Business Training"
  ],

  tools: "Advanced Makeup Kits, Salon Setup",
  duration: "6–12 Months",

  price: 200000,
  discount: 40000,
  finalPrice: 160000,

  warranty: "Own Salon + High Income Career Guidance",
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
/// 🔹 Aviation Basic Package
EducationService(
  id: "AVIATION_1",
  name: "Aviation Course (Basic Package)",
  category: "Aviation Courses",
  image: "assets/aviation_basic.png",

  description:
      "Starter course to understand aviation industry basics, grooming, and communication skills.",

  includes: [
    "Aviation Basics Introduction",
    "Grooming & Personality Development",
    "Basic Communication Skills (English)",
    "Confidence Building Sessions",
    "Air Hostess Role Understanding"
  ],

  excludes: [
    "Advanced Interview Preparation",
    "Placement Assistance"
  ],

  steps: [
    "Basic Training Sessions",
    "Grooming Practice",
    "Communication Training",
    "Confidence Development"
  ],

  tools: "Training Notes, Grooming Kit Guidance",
  duration: "3 Months",

  price: 45000,
  discount: 5000,
  finalPrice: 40000,

  warranty: "Basic Aviation Knowledge",
),

/// 🔹 Aviation Standard Package
EducationService(
  id: "AVIATION_2",
  name: "Aviation Course (Standard Package)",
  category: "Aviation Courses",
  image: "assets/aviation_standard.png",

  description:
      "Most popular course designed to make students job-ready for airline interviews.",

  includes: [
    "Everything in Basic Package",
    "Advanced English Communication",
    "Interview Preparation & Mock Interviews",
    "Cabin Crew Training Modules",
    "Resume Building + Soft Skills",
    "Group Discussion Practice"
  ],

  excludes: [
    "International Placement Support"
  ],

  steps: [
    "Advanced Communication Training",
    "Interview Practice",
    "Cabin Crew Modules",
    "Mock Interviews"
  ],

  tools: "Mock Interview Setup, Training Material",
  duration: "6 Months",

  price: 85000,
  discount: 10000,
  finalPrice: 75000,

  warranty: "Interview & Job Readiness",
),

/// 🔹 Aviation Premium Package
EducationService(
  id: "AVIATION_3",
  name: "Aviation Course (Premium Package)",
  category: "Aviation Courses",
  image: "assets/aviation_premium.png",

  description:
      "Professional aviation training with international preparation, simulation, and placement support.",

  includes: [
    "Everything in Standard Package",
    "Airline Grooming Masterclass",
    "International Airline Preparation",
    "Cabin Crew Simulation Training",
    "Internship / Placement Assistance",
    "Personality Transformation Program",
    "Visa & Overseas Job Guidance"
  ],

  excludes: [
    "Guaranteed International Placement"
  ],

  steps: [
    "Professional Training",
    "Simulation Practice",
    "Internship Training",
    "Placement Preparation"
  ],

  tools: "Simulation Lab, Grooming Kit, Training Material",
  duration: "9–12 Months",

  price: 150000,
  discount: 20000,
  finalPrice: 130000,

  warranty: "Placement Assistance & Career Guidance",
),

/// Dance Class 
/// 🔹 Basic Dance
EducationService(
  id: "DANCE_1",
  name: "Basic Dance Course (Beginner Level)",
  category: "Dance & Music Courses",
  image: "assets/basic dance.png",

  description:
      "Beginner-friendly dance course covering basic steps, rhythm, and simple choreography for all age groups.",

  includes: [
    "Dance Basics (Body Movement, Rhythm, Timing)",
    "Basic Bollywood & Freestyle Steps",
    "Warm-up & Stretching Techniques",
    "Simple Choreography",
    "Facial Expressions & Energy Control",
    "Basic Fitness & Flexibility Training"
  ],

  excludes: [
    "Advanced Choreography",
    "Stage Performance Training"
  ],

  steps: [
    "Warm-up Sessions",
    "Basic Step Practice",
    "Routine Practice",
    "Group Dance Training"
  ],

  tools: "Music System, Practice Studio",
  duration: "2–3 Months",

  price: 12000,
  discount: 4000,
  finalPrice: 8000,

  warranty: "Basic Dance Skills Development",
),

/// 🔹 Advance Dance
EducationService(
  id: "DANCE_2",
  name: "Advance Dance Course (Professional Level)",
  category: "Dance & Music Courses",
  image: "assets/advance dance.png",

  description:
      "Professional dance training with multiple styles, stage performance, and choreography skills.",

  includes: [
    "Advanced Choreography",
    "Multiple Dance Styles (Bollywood, Hip-Hop, Contemporary)",
    "Stage Performance Techniques",
    "Freestyle & Creativity Development",
    "Partner Dance Basics",
    "Expression & Storytelling",
    "Fitness & Stamina Building"
  ],

  excludes: [
    "International Certification (optional)"
  ],

  steps: [
    "Advanced Training Sessions",
    "Choreography Practice",
    "Performance Training",
    "Competition Preparation"
  ],

  tools: "Studio, Music System, Performance Setup",
  duration: "4–6 Months",

  price: 30000,
  discount: 8000,
  finalPrice: 22000,

  warranty: "Stage Performance & Career Guidance",
),

/// Music Class
/// 🔹 Basic Music
EducationService(
  id: "MUSIC_1",
  name: "Basic Music Course (Beginner Level)",
  category: "Dance & Music Courses",
  image: "assets/basic_music.png",

  description:
      "Learn music fundamentals including vocal training, rhythm, and basic instrumental introduction.",

  includes: [
    "Music Basics (Swar, Sur, Taal)",
    "Basic Vocal Training",
    "Alankar Practice",
    "Simple Songs (Bollywood / Bhajan)",
    "Rhythm Understanding",
    "Instrumental Introduction (Keyboard / Harmonium)"
  ],

  excludes: [
    "Advanced Classical Training"
  ],

  steps: [
    "Basic Theory Learning",
    "Voice Practice (Riyaaz)",
    "Song Practice",
    "Group Singing Sessions"
  ],

  tools: "Harmonium, Keyboard, Notes",
  duration: "3–4 Months",

  price: 15000,
  discount: 5000,
  finalPrice: 10000,

  warranty: "Basic Singing & Music Skills",
),

/// 🔹 Advance Music
EducationService(
  id: "MUSIC_2",
  name: "Advance Music Course (Professional Level)",
  category: "Dance & Music Courses",
  image: "assets/advance_music.png",

  description:
      "Advanced music training including classical techniques, stage performance, and recording skills.",

  includes: [
    "Advanced Vocal Training",
    "Classical Music (Raag, Alaap, Taan)",
    "Voice Control & Modulation",
    "Stage Performance Skills",
    "Song Recording Techniques",
    "Karaoke & Mic Handling",
    "Instrumental Training (Optional)"
  ],

  excludes: [
    "International Certification"
  ],

  steps: [
    "Advanced Vocal Practice",
    "Live Performance Training",
    "Studio Recording",
    "Solo Practice Sessions"
  ],

  tools: "Studio Setup, Instruments, Recording Tools",
  duration: "6–12 Months",

  price: 40000,
  discount: 10000,
  finalPrice: 30000,

  warranty: "Performance Opportunities & Certification",
),

/// Mobile Repairing
/// 🔹 Basic Mobile Repairing
EducationService(
  id: "MOB_1",
  name: "Basic Mobile Repairing Course (Beginner Level)",
  category: "Technical Courses",
  image: "assets/mobile_basic.png",

  description:
      "Learn the fundamentals of mobile repairing including hardware basics, common faults, and basic software handling.",

  includes: [
    "Mobile Repairing Introduction (Android Basics)",
    "Tools & Equipment Usage",
    "Mobile Opening & Assembling",
    "Display (Screen) Replacement",
    "Battery & Charging Jack Repair",
    "Speaker, Mic & Camera Issues",
    "Basic Software (Reset, Flashing)",
    "Safety & Handling Techniques"
  ],

  excludes: [
    "Chip-Level Repairing",
    "Advanced Software Unlocking"
  ],

  steps: [
    "Basic Theory Learning",
    "Tool Handling Practice",
    "Mobile Disassembly & Assembly",
    "Fault Finding Practice"
  ],

  tools: "Repair Toolkit, Practice Devices",
  duration: "2–3 Months",

  price: 18000,
  discount: 6000,
  finalPrice: 12000,

  warranty: "Basic Mobile Repairing Skills",
),

/// 🔹 Advance Mobile Repairing
EducationService(
  id: "MOB_2",
  name: "Advance Mobile Repairing Course (Professional Level)",
  category: "Technical Courses",
  image: "assets/mobile_advance.png",

  description:
      "Professional-level mobile repairing course covering chip-level work, advanced troubleshooting, and real-device practice.",

  includes: [
    "Complete Hardware + Software Repairing",
    "Chip-Level Repairing (IC Work)",
    "Soldering & Rework Station Usage",
    "Motherboard Fault Finding",
    "Water Damage Repairing",
    "Advanced Flashing & Unlocking",
    "Dead Phone Repair",
    "Network Issue Solving",
    "iPhone & Android Repair Basics"
  ],

  excludes: [
    "Brand-Specific Certification"
  ],

  steps: [
    "Advanced Hardware Training",
    "Chip-Level Practice",
    "Fault Diagnosis",
    "Real Device Repairing"
  ],

  tools: "Soldering Station, Multimeter, Repair Tools",
  duration: "4–6 Months",

  price: 40000,
  discount: 10000,
  finalPrice: 30000,

  warranty: "Job Assistance & Shop Setup Guidance",
),


];
