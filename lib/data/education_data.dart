
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
  
  /// =========================
// Computer Courses
  /// =========================
  /// 
  
  EducationService(
    id: "MSC_1",
    name: "Basic MS-CIT",
    category: "MS-CIT",
    image: "assets/Education.jpg",
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
    category: "MS-CIT",
    image: "assets/Education.jpg",
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
    category: "MS-CIT",
    image: "assets/Education.jpg",
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
    category: "MS-CIT",
    image: "assets/Education.jpg",
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


  // 🟢 BASIC
  EducationService(
    id: "SE_1",
    name: "Basic Coding Course",
    category: "Software Engineering",
    image: "assets/Education.jpg",
    description: "Start coding with basic programming & web fundamentals",

    includes: [
      "Python / C / Java basics",
      "HTML, CSS",
      "Logic building",
      "Small projects"
    ],
    excludes: ["Advanced frameworks"],
    steps: ["Basics", "Practice", "Mini projects"],
    tools: "Python, C, HTML, CSS",
    duration: "3–6 Months",

    price: 50000,
    discount: 40,
    finalPrice: 30000,

    warranty: "Basic coding support",
  ),

  // 📘 CERTIFICATE / DIPLOMA
  EducationService(
    id: "SE_2",
    name: "Diploma in Software Engineering",
    category: "Software Engineering",
    image: "assets/Education.jpg",
    description: "Core programming + database + development basics",

    includes: [
      "C, C++, Java",
      "SQL database",
      "Software development basics",
      "Practical projects"
    ],
    excludes: [],
    steps: ["Theory", "Practice", "Projects"],
    tools: "C++, Java, SQL",
    duration: "1–2 Years",

    price: 120000,
    discount: 25,
    finalPrice: 90000,

    warranty: "Project support",
  ),

  // 🚀 ADVANCED
  EducationService(
    id: "SE_3",
    name: "Full Stack Development Course",
    category: "Software Engineering",
    image: "assets/Education.jpg",
    description: "Frontend + backend + database full training",

    includes: [
      "HTML, CSS, JavaScript, React",
      "Node.js / Python backend",
      "MongoDB / SQL",
      "Git, APIs",
      "Live projects"
    ],
    excludes: [],
    steps: ["Frontend", "Backend", "Projects"],
    tools: "React, Node.js, MongoDB",
    duration: "6–12 Months",

    price: 150000,
    discount: 30,
    finalPrice: 105000,

    warranty: "Portfolio + job prep",
  ),

  // 🔥 JOB ORIENTED
  EducationService(
    id: "SE_4",
    name: "Software Engineering Bootcamp",
    category: "Software Engineering",
    image: "assets/Education.jpg",
    description: "Fast-track job-ready training with interviews",

    includes: [
      "Full stack + DSA",
      "Mock interviews",
      "Resume building",
      "Real-world projects"
    ],
    excludes: [],
    steps: ["Training", "Projects", "Interview prep"],
    tools: "Full Stack + DSA",
    duration: "4–9 Months",

    price: 200000,
    discount: 25,
    finalPrice: 150000,

    warranty: "Placement guidance",
  ),

  // 🎯 SPECIALIZED
  EducationService(
    id: "SE_5",
    name: "Specialized Software Courses",
    category: "Software Engineering",
    image: "assets/Education.jpg",
    description: "Skill-based courses like Web, App, Testing, UI/UX",

    includes: [
      "Web development",
      "App development",
      "Software testing",
      "UI/UX design basics"
    ],
    excludes: [],
    steps: ["Skill training", "Practice", "Projects"],
    tools: "Varies by skill",
    duration: "2–6 Months",

    price: 60000,
    discount: 30,
    finalPrice: 42000,

    warranty: "Skill-based support",
  ),



  // 🟢 BASIC
  EducationService(
    id: "DS_1",
    name: "Basic Data Science Course",
    category: "Data Science",
    image: "assets/Education.jpg",
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

  // 📘 CERTIFICATE
  EducationService(
    id: "DS_2",
    name: "Certificate in Data Science",
    category: "Data Science",
    image: "assets/Education.jpg",
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

  // 🚀 DIPLOMA
  EducationService(
    id: "DS_3",
    name: "Diploma in Data Science",
    category: "Data Science",
    image: "assets/Education.jpg",
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

  // 🔥 ADVANCED
  EducationService(
    id: "DS_4",
    name: "Advanced Data Science Course",
    category: "Data Science",
    image: "assets/Education.jpg",
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

  // 🎯 SPECIALIZED
  EducationService(
    id: "DS_5",
    name: "Specialized Data Courses",
    category: "Data Science",
    image: "assets/Education.jpg",
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


  EducationService(
    id: "DM_1",
    name: "Basic Digital Marketing",
    category: "Digital Marketing",
    image: "assets/Education.jpg",
    description: "Introduction to digital marketing",

    includes: [
      "Social media marketing",
      "Basic SEO",
      "Content creation"
    ],
    excludes: [],
    steps: ["Learning", "Practice"],
    tools: "Social media tools",
    duration: "2–4 Months",

    price: 40000,
    discount: 25,
    finalPrice: 30000,

    warranty: "Basic support",
  ),


  EducationService(
    id: "NW_1",
    name: "Basic Networking",
    category: "Networking",
    image: "assets/Education.jpg",
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
    image: "assets/Education.jpg",
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
    image: "assets/Education.jpg",
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
    image: "assets/Education.jpg",
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
    image: "assets/Education.jpg",
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


  EducationService(
    id: "DM_2",
    name: "Diploma in Digital Marketing",
    category: "Digital Marketing",
    image: "assets/Education.jpg",
    description: "Complete marketing foundation",

    includes: [
      "SEO, SEM",
      "Email marketing",
      "Analytics tools"
    ],
    excludes: [],
    steps: ["Training", "Practice"],
    tools: "Google tools",
    duration: "4–8 Months",

    price: 80000,
    discount: 30,
    finalPrice: 56000,

    warranty: "Certificate support",
  ),

  EducationService(
    id: "DM_3",
    name: "Advanced Digital Marketing",
    category: "Digital Marketing",
    image: "assets/Education.jpg",
    description: "Professional marketing course",

    includes: [
      "Advanced SEO",
      "Google Ads",
      "Social media ads",
      "Affiliate marketing"
    ],
    excludes: [],
    steps: ["Training", "Projects"],
    tools: "Ads tools",
    duration: "6–12 Months",

    price: 150000,
    discount: 25,
    finalPrice: 112500,

    warranty: "Project support",
  ),

  EducationService(
    id: "DM_4",
    name: "Marketing Bootcamp",
    category: "Digital Marketing",
    image: "assets/Education.jpg",
    description: "Fast-track job course",

    includes: [
      "Live campaigns",
      "Freelancing training",
      "Interview prep"
    ],
    excludes: [],
    steps: ["Practice", "Projects"],
    tools: "Live tools",
    duration: "3–6 Months",

    price: 200000,
    discount: 25,
    finalPrice: 150000,

    warranty: "Placement support",
  ),

  EducationService(
    id: "DM_5",
    name: "Specialized Marketing Skills",
    category: "Digital Marketing",
    image: "assets/Education.jpg",
    description: "SEO, Ads, content writing",

    includes: [
      "SEO",
      "Google Ads",
      "Content writing"
    ],
    excludes: [],
    steps: ["Skill training"],
    tools: "Marketing tools",
    duration: "1–3 Months",

    price: 50000,
    discount: 20,
    finalPrice: 40000,

    warranty: "Skill support",
  ),

  
  /// =========================
  /// Graphic Design + Video Editing Courses 
// 🎨 1. Basic Course
EducationService(
  id: "GD_1",
  name: "Basic Graphic Design + Video Editing",
  category: "Graphic Design & Video Editing",
  image: "assets/Education.jpg",
  description: "Starter course for beginners to learn design and basic editing.",

  includes: [
    "Photoshop basics (poster, banner)",
    "Canva + social media posts",
    "Basic video editing (cut, trim, reels)",
    "Mobile + PC editing tools",
    "Simple projects (YouTube shorts, posters)"
  ],

  excludes: [
    "Advanced motion graphics",
    "Professional-level editing"
  ],

  steps: [
    "Design basics learning",
    "Practice on simple projects",
    "Editing practice",
    "Final mini projects"
  ],

  tools: "Photoshop, Canva, Mobile Editing Apps",
  duration: "2–3 Months",

  price: 40000,
  discount: 50,
  finalPrice: 20000,

  warranty: "Basic skill training support",
),

// 📘 2. Certificate Course
EducationService(
  id: "GD_2",
  name: "Certificate in Graphic Design + Video Editing",
  category: "Graphic Design & Video Editing",
  image: "assets/Education.jpg",
  description: "Foundation course covering design tools and video editing.",

  includes: [
    "Adobe Photoshop & Illustrator",
    "Premiere Pro basics",
    "Motion graphics introduction",
    "Logo design + branding",
    "YouTube video editing"
  ],

  excludes: [
    "Advanced animation",
    "High-end cinematic editing"
  ],

  steps: [
    "Software training",
    "Design practice",
    "Video editing projects",
    "Portfolio basics"
  ],

  tools: "Photoshop, Illustrator, Premiere Pro",
  duration: "3–6 Months",

  price: 70000,
  discount: 40,
  finalPrice: 42000,

  warranty: "Course completion certificate",
),

// 🎬 3. Diploma Course
EducationService(
  id: "GD_3",
  name: "Diploma in Graphic Design + Video Editing",
  category: "Graphic Design & Video Editing",
  image: "assets/Education.jpg",
  description: "Professional training with advanced tools and live projects.",

  includes: [
    "Full Adobe Creative Suite",
    "Advanced Premiere Pro + After Effects",
    "Branding + advertising design",
    "Motion graphics + animation basics",
    "Portfolio + live projects"
  ],

  excludes: [
    "Hollywood-level VFX training"
  ],

  steps: [
    "Advanced software training",
    "Real-world project work",
    "Portfolio building",
    "Final assessment"
  ],

  tools: "Photoshop, Illustrator, Premiere Pro, After Effects",
  duration: "6–12 Months",

  price: 150000,
  discount: 30,
  finalPrice: 105000,

  warranty: "Professional course support",
),

// 🚀 4. Advanced Course
EducationService(
  id: "GD_4",
  name: "Advanced Creative Media Course",
  category: "Graphic Design & Video Editing",
  image: "assets/Education.jpg",
  description: "High-level career training with client projects and internships.",

  includes: [
    "Advanced motion graphics",
    "Cinematic video editing",
    "UI creatives + campaigns",
    "Client projects + internships",
    "Freelancing + placement support"
  ],

  excludes: [
    "Film school degree certification"
  ],

  steps: [
    "Advanced editing training",
    "Client-based assignments",
    "Internship experience",
    "Placement preparation"
  ],

  tools: "After Effects, Premiere Pro, Advanced Design Tools",
  duration: "8–18 Months",

  price: 200000,
  discount: 25,
  finalPrice: 150000,

  warranty: "Placement & career support",
),

// 🔥 5. Short Courses
EducationService(
  id: "GD_5",
  name: "Specialized Short Courses",
  category: "Graphic Design & Video Editing",
  image: "assets/Education.jpg",
  description: "Quick skill-based courses for fast freelancing income.",

  includes: [
    "Instagram reels editing",
    "YouTube editing",
    "Logo design",
    "Thumbnail design",
    "Canva + mobile editing mastery"
  ],

  excludes: [
    "Full software training",
    "Long-term projects"
  ],

  steps: [
    "Skill-focused training",
    "Practice tasks",
    "Quick project execution",
    "Freelancing guidance"
  ],

  tools: "Canva, Mobile Apps, Basic Editing Software",
  duration: "1–3 Months",

  price: 40000,
  discount: 50,
  finalPrice: 20000,

  warranty: "Short-term skill support",
),


// Pramedical Courses
/// 🏥 PARAMEDICAL COURSES
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

  
  /// =========================
  /// 🏛️ GOVERNMENT JOB PREPARATION

EducationService(
  id: "GOV_1",
  name: "Entry Level Package (Railway + Police + Army)",
  category: "Government Exam Preparation",
  image: "assets/government.jpg",
  description: "Fast-track preparation for entry-level government jobs",

  includes: [
    "GK + Reasoning + Maths basics",
    "Physical training guidance",
    "Mock tests & exam practice",
    "Previous year questions"
  ],

  excludes: [
    "Advanced officer-level preparation"
  ],

  steps: [
    "Basic concept learning",
    "Daily practice",
    "Mock tests",
    "Final revision"
  ],

  tools: "Study material, Test series",
  duration: "3–9 Months",

  price: 25000,
  discount: 20,
  finalPrice: 20000,

  warranty: "Exam preparation support",
),

EducationService(
  id: "GOV_2",
  name: "Banking Package (Clerk + PO)",
  category: "Government Exam Preparation",
  image: "assets/government.jpg",
  description: "Preparation for banking sector exams",

  includes: [
    "Quantitative Aptitude",
    "Reasoning & English",
    "Computer knowledge",
    "Mock interviews"
  ],

  excludes: [
    "UPSC/MPSC syllabus"
  ],

  steps: [
    "Concept building",
    "Practice sessions",
    "Mock tests",
    "Interview preparation"
  ],

  tools: "Books, Online tests",
  duration: "6–12 Months",

  price: 50000,
  discount: 20,
  finalPrice: 40000,

  warranty: "Interview guidance support",
),

EducationService(
  id: "GOV_3",
  name: "State Level Package (MPSC)",
  category: "Government Exam Preparation",
  image: "assets/government.jpg",
  description: "Complete preparation for MPSC exams",

  includes: [
    "Prelims & Mains syllabus",
    "History, Geography, Polity",
    "Current Affairs",
    "Answer writing practice"
  ],

  excludes: [
    "UPSC level preparation"
  ],

  steps: [
    "Syllabus coverage",
    "Answer writing",
    "Mock tests",
    "Revision"
  ],

  tools: "Notes, Test series",
  duration: "12–24 Months",

  price: 100000,
  discount: 20,
  finalPrice: 80000,

  warranty: "Full exam preparation support",
),

EducationService(
  id: "GOV_4",
  name: "National Level Package (UPSC IAS/IPS)",
  category: "Government Exam Preparation",
  image: "assets/government.jpg",
  description: "Advanced preparation for UPSC civil services",

  includes: [
    "Prelims + Mains + Interview",
    "Full GS syllabus",
    "Essay & optional subject",
    "Mock interviews"
  ],

  excludes: [
    "Short-term crash preparation"
  ],

  steps: [
    "Concept mastery",
    "Answer writing",
    "Test series",
    "Interview preparation"
  ],

  tools: "Advanced study material",
  duration: "1–3 Years",

  price: 250000,
  discount: 20,
  finalPrice: 200000,

  warranty: "Complete guidance till interview",
),

EducationService(
  id: "GOV_5",
  name: "Crash Fast Track Package",
  category: "Government Exam Preparation",
  image: "assets/government.jpg",
  description: "Quick preparation for first attempt",

  includes: [
    "Basic GK & Reasoning",
    "Daily test practice",
    "Previous year papers",
    "Quick revision"
  ],

  excludes: [
    "Detailed syllabus coverage"
  ],

  steps: [
    "Quick concept revision",
    "Daily tests",
    "Practice papers",
    "Final revision"
  ],

  tools: "Practice papers, Test series",
  duration: "3–6 Months",

  price: 15000,
  discount: 20,
  finalPrice: 12000,

  warranty: "Short-term support",
),

  /// =========================
  /// 💄 SALON & PARLOUR COURSES
  /// =========================
 /// 💄 BEAUTICIAN / SALON COURSES

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
  /// =========================
  /// 💃 DANCE CLASSES
  /// =========================
 /// 💃 DANCE CLASSES

EducationService(
  id: "DANCE_1",
  name: "Bollywood Dance (Most Popular)",
  category: "Dance Classes",
  image: "assets/dance.jpg",
  description: "Fun Bollywood-style dance for beginners and events",

  includes: [
    "Basic to advanced Bollywood moves",
    "Choreography for songs",
    "Weekly practice sessions",
    "Performance training"
  ],

  excludes: [
    "Classical dance training"
  ],

  steps: [
    "Basic steps learning",
    "Routine practice",
    "Choreography building",
    "Final performance"
  ],

  tools: "Music system, Studio space",
  duration: "1–6 Months",

  price: 24000,
  discount: 20,
  finalPrice: 19200,

  warranty: "Practice & performance support",
),

EducationService(
  id: "DANCE_2",
  name: "Hip-Hop Dance",
  category: "Dance Classes",
  image: "assets/dance.jpg",
  description: "Urban freestyle and stage performance dance",

  includes: [
    "Hip-hop fundamentals",
    "Freestyle training",
    "Stage performance skills",
    "Group choreography"
  ],

  excludes: [
    "Classical techniques"
  ],

  steps: [
    "Basic groove training",
    "Freestyle practice",
    "Routine creation",
    "Performance"
  ],

  tools: "Music system, Practice space",
  duration: "2–6 Months",

  price: 30000,
  discount: 20,
  finalPrice: 24000,

  warranty: "Skill improvement support",
),

EducationService(
  id: "DANCE_3",
  name: "Contemporary Dance",
  category: "Dance Classes",
  image: "assets/dance.jpg",
  description: "Expressive dance with flexibility and storytelling",

  includes: [
    "Body flexibility training",
    "Expression techniques",
    "Stage choreography",
    "Performance training"
  ],

  excludes: [
    "Hip-hop freestyle training"
  ],

  steps: [
    "Stretching & basics",
    "Movement practice",
    "Routine choreography",
    "Final showcase"
  ],

  tools: "Studio, Music setup",
  duration: "3–6 Months",

  price: 36000,
  discount: 20,
  finalPrice: 28800,

  warranty: "Performance guidance",
),

EducationService(
  id: "DANCE_4",
  name: "Classical Dance (Kathak / Bharatanatyam)",
  category: "Dance Classes",
  image: "assets/dance.jpg",
  description: "Traditional Indian dance training with certification",

  includes: [
    "Classical techniques",
    "Theory + practical training",
    "Exam preparation",
    "Stage performance"
  ],

  excludes: [
    "Modern dance styles"
  ],

  steps: [
    "Basic steps training",
    "Theory learning",
    "Practice routines",
    "Stage performance"
  ],

  tools: "Traditional music, Costume guidance",
  duration: "6–12 Months",

  price: 30000,
  discount: 20,
  finalPrice: 24000,

  warranty: "Training + certification support",
),

EducationService(
  id: "DANCE_5",
  name: "Lavani Dance (Maharashtrian Folk)",
  category: "Dance Classes",
  image: "assets/dance.jpg",
  description: "Energetic folk dance for cultural performances",

  includes: [
    "Lavani steps & expressions",
    "Stage performance training",
    "Costume & styling guidance",
    "Folk choreography"
  ],

  excludes: [
    "Classical certification"
  ],

  steps: [
    "Basic steps",
    "Expression practice",
    "Routine choreography",
    "Performance"
  ],

  tools: "Music system, Costume guidance",
  duration: "2–6 Months",

  price: 25000,
  discount: 20,
  finalPrice: 20000,

  warranty: "Performance support",
),

EducationService(
  id: "DANCE_6",
  name: "Zumba / Dance Fitness",
  category: "Dance Classes",
  image: "assets/dance.jpg",
  description: "Fun dance workout for fitness and weight loss",

  includes: [
    "Daily/weekly sessions",
    "Cardio dance routines",
    "Fitness tracking",
    "Group workouts"
  ],

  excludes: [
    "Professional choreography"
  ],

  steps: [
    "Warm-up",
    "Dance workout",
    "Cool down",
    "Fitness tracking"
  ],

  tools: "Music system, Open space",
  duration: "Monthly Subscription",

  price: 18000,
  discount: 20,
  finalPrice: 14400,

  warranty: "Ongoing fitness support",
),

EducationService(
  id: "DANCE_7",
  name: "Wedding / Event Choreography",
  category: "Dance Classes",
  image: "assets/dance.jpg",
  description: "Short-term choreography for weddings and events",

  includes: [
    "Custom choreography",
    "Song selection help",
    "Daily practice sessions",
    "Final performance prep"
  ],

  excludes: [
    "Long-term training"
  ],

  steps: [
    "Song selection",
    "Step creation",
    "Practice sessions",
    "Final rehearsal"
  ],

  tools: "Music system, Studio",
  duration: "10 Days – 1 Month",

  price: 15000,
  discount: 20,
  finalPrice: 12000,

  warranty: "Performance completion support",
),


/// 🎵 MUSIC CLASSES

EducationService(
  id: "MUSIC_1",
  name: "Basic Starter Music Package",
  category: "Music Classes",
  image: "assets/music.jpg",
  description: "Beginner level foundation for singing & instruments",

  includes: [
    "Basic singing (sur, taal, breathing)",
    "Guitar basics",
    "Keyboard basics",
    "Tabla introduction",
    "Music theory basics"
  ],

  excludes: [
    "Advanced performance training"
  ],

  steps: [
    "Basics learning",
    "Practice sessions",
    "Simple songs",
    "Assessment"
  ],

  tools: "Instruments, practice setup",
  duration: "1–3 Months",

  price: 15000,
  discount: 20,
  finalPrice: 12000,

  warranty: "Practice support",
),

EducationService(
  id: "MUSIC_2",
  name: "Regular Music Training Package",
  category: "Music Classes",
  image: "assets/music.jpg",
  description: "Intermediate training across vocals and instruments",

  includes: [
    "Vocal training (riyaaz)",
    "Guitar/Keyboard intermediate",
    "Tabla rhythms",
    "Drums basics",
    "Song performance"
  ],

  excludes: [
    "Professional stage training"
  ],

  steps: [
    "Skill building",
    "Practice routines",
    "Song learning",
    "Performance"
  ],

  tools: "Instruments, studio setup",
  duration: "3–6 Months",

  price: 30000,
  discount: 20,
  finalPrice: 24000,

  warranty: "Skill improvement support",
),

EducationService(
  id: "MUSIC_3",
  name: "Advanced Performer Package",
  category: "Music Classes",
  image: "assets/music.jpg",
  description: "Professional training for stage and studio performance",

  includes: [
    "Advanced vocal training",
    "Guitar solos & fingerstyle",
    "Keyboard arrangements",
    "Tabla advanced taals",
    "Drum kit training",
    "Live band performance"
  ],

  excludes: [
    "Beginner basics"
  ],

  steps: [
    "Advanced practice",
    "Performance training",
    "Live sessions",
    "Final showcase"
  ],

  tools: "Studio instruments",
  duration: "6–12 Months",

  price: 60000,
  discount: 20,
  finalPrice: 48000,

  warranty: "Performance support",
),

EducationService(
  id: "MUSIC_4",
  name: "Crash Course (Fast Learning)",
  category: "Music Classes",
  image: "assets/music.jpg",
  description: "Quick preparation for performances and events",

  includes: [
    "2–3 songs preparation",
    "Basic instrument playing",
    "Rhythm basics",
    "Stage confidence"
  ],

  excludes: [
    "Long-term training"
  ],

  steps: [
    "Quick learning",
    "Daily practice",
    "Song preparation",
    "Final performance"
  ],

  tools: "Basic instruments",
  duration: "1–2 Months",

  price: 12000,
  discount: 20,
  finalPrice: 9600,

  warranty: "Short-term support",
),

EducationService(
  id: "MUSIC_5",
  name: "Instrument Combo (Guitar + Keyboard / Tabla + Drums)",
  category: "Music Classes",
  image: "assets/music.jpg",
  description: "Focused training on selected instruments",

  includes: [
    "Dual instrument training",
    "Practice routines",
    "Performance basics",
    "Skill improvement"
  ],

  excludes: [
    "Full vocal training"
  ],

  steps: [
    "Instrument basics",
    "Practice",
    "Song playing",
    "Evaluation"
  ],

  tools: "Selected instruments",
  duration: "3–6 Months",

  price: 20000,
  discount: 20,
  finalPrice: 16000,

  warranty: "Practice support",
),

EducationService(
  id: "MUSIC_6",
  name: "Private 1-to-1 Music Coaching",
  category: "Music Classes",
  image: "assets/music.jpg",
  description: "Personalized music training with fast improvement",

  includes: [
    "Customized training",
    "Vocal + instruments",
    "Recording practice",
    "Audition preparation"
  ],

  excludes: [
    "Group classes"
  ],

  steps: [
    "Skill assessment",
    "Personal plan",
    "Practice sessions",
    "Progress tracking"
  ],

  tools: "Studio + instruments",
  duration: "Flexible",

  price: 25000,
  discount: 20,
  finalPrice: 20000,

  warranty: "Personal mentorship support",
),

];
