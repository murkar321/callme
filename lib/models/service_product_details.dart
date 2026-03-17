import '../models/service_product.dart';

// Master data for all services and their subcategories
final Map<String, Map<String, List<ServiceProduct>>> serviceProducts = {
  // 📸 PHOTOGRAPHY
  'Photography': {
    'Album': [
      ServiceProduct(
        name: 'Single Photo Half Day',
        price: 250,
        imagePath: 'assets/a1.jpg',
        description:
            'A half-day single photo session perfect for solo portraits or quick shoots.',
      ),
      ServiceProduct(
        name: 'Children Photo Full Day',
        price: 500,
        imagePath: 'assets/a2.jpg',
        description:
            'Full-day children photography service capturing fun and candid moments.',
      ),
      ServiceProduct(
        name: 'Single Photo Half Day',
        price: 250,
        imagePath: 'assets/a3.jpg',
        description:
            'Professional indoor or outdoor photo session lasting half a day.',
      ),
      ServiceProduct(
        name: 'Children Photo Full Day',
        price: 500,
        imagePath: 'assets/a4.jpg',
        description:
            'A full-day children’s shoot with props and creative lighting setups.',
      ),
    ],
    'Wedding': [
      ServiceProduct(
        name: 'Wedding Photography',
        price: 10000,
        imagePath: 'assets/w1.jpg',
        description:
            'Full-day wedding photography with candid and traditional shots.',
      ),
      ServiceProduct(
        name: 'Pre Wedding Shoot',
        price: 5000,
        imagePath: 'assets/w2.jpg',
        description:
            'Creative outdoor pre-wedding shoot with location guidance.',
      ),
      ServiceProduct(
        name: 'Wedding Photography',
        price: 10000,
        imagePath: 'assets/w3.jpg',
        description:
            'Premium wedding coverage with photo editing and digital album.',
      ),
      ServiceProduct(
        name: 'Pre Wedding Shoot',
        price: 5000,
        imagePath: 'assets/w4.jpg',
        description:
            'Romantic pre-wedding session with cinematic photography style.',
      ),
    ],
    'Event': [
      ServiceProduct(
        name: 'Event Photography',
        price: 5000,
        imagePath: 'assets/event.jpg',
        description: 'Photography coverage for events, functions, or launches.',
      ),
      ServiceProduct(
        name: 'Corporate Event',
        price: 7000,
        imagePath: 'assets/e1.jpg',
        description:
            'Professional photography for corporate meetings, expos, and seminars.',
      ),
      ServiceProduct(
        name: 'House Event',
        price: 9000,
        imagePath: 'assets/e2.jpg',
        description: 'Event photography for private functions and home events.',
      ),
      ServiceProduct(
        name: 'Wedding Event',
        price: 8000,
        imagePath: 'assets/e3.jpg',
        description:
            'Capture wedding-related events such as receptions or mehendi.',
      ),
      ServiceProduct(
        name: 'College Event',
        price: 1000,
        imagePath: 'assets/e4.jpg',
        description:
            'Budget-friendly photography for college events and fests.',
      ),
    ],
    'Birthday': [
      ServiceProduct(
        name: 'Birthday Shoot Half Day',
        price: 1000,
        imagePath: 'assets/bi1.jpg',
        description:
            'Half-day birthday shoot including decorations and cake-cutting.',
      ),
      ServiceProduct(
        name: 'Birthday Shoot Full Day',
        price: 2000,
        imagePath: 'assets/bi2.jpg',
        description:
            'Full-day birthday photography covering preparation to celebrations.',
      ),
      ServiceProduct(
        name: 'Birthday Shoot Half Day',
        price: 1000,
        imagePath: 'assets/bi3.jpg',
        description: 'Indoor/outdoor birthday shoot for kids or adults.',
      ),
      ServiceProduct(
        name: 'Birthday Shoot Full Day',
        price: 2000,
        imagePath: 'assets/bi4.jpg',
        description: 'Candid birthday photography with props and lighting.',
      ),
      ServiceProduct(
        name: 'Birthday Shoot Full Day',
        price: 2000,
        imagePath: 'assets/bi5.jpg',
        description: 'Professional full-day birthday photo session.',
      ),
    ],
    'Baby Shower': [
      ServiceProduct(
        name: 'Baby Shower Photography',
        price: 3000,
        imagePath: 'assets/bs1.jpg',
        description: 'Beautiful maternity and baby shower photography.',
      ),
      ServiceProduct(
        name: 'Baby Shower Photography',
        price: 5000,
        imagePath: 'assets/bs2.jpg',
        description: 'Full-event coverage for baby shower celebrations.',
      ),
      ServiceProduct(
        name: 'Baby Shower Photography',
        price: 10000,
        imagePath: 'assets/bs3.jpg',
        description: 'Premium baby shower photoshoot with creative backdrops.',
      ),
    ],
  },

  // 🧹 CLEANING
  'Cleaning': {
    'Kitchen Cleaning': [
      ServiceProduct(
        name: 'Cleaning',
        price: 1200,
        imagePath: 'assets/k1.jpg',
        description:
            'Complete kitchen cleaning service with deep sanitization.',
      ),
      ServiceProduct(
        name: 'Cleaning',
        price: 500,
        imagePath: 'assets/k2.jpg',
        description: 'Quick kitchen surface cleaning for daily maintenance.',
      ),
      ServiceProduct(
        name: 'Cleaning',
        price: 1200,
        imagePath: 'assets/k6.jpg',
        description: 'Oil stain and exhaust fan cleaning included.',
      ),
      ServiceProduct(
        name: 'Cleaning',
        price: 500,
        imagePath: 'assets/k4.jpg',
        description: 'Basic kitchen sink and platform cleaning.',
      ),
      ServiceProduct(
        name: 'Cleaning',
        price: 1200,
        imagePath: 'assets/k5.jpg',
        description: 'Full kitchen cleaning with appliances wipe-down.',
      ),
    ],
    'Bathroom Cleaning': [
      ServiceProduct(
        name: 'Cleaning',
        price: 1200,
        imagePath: 'assets/bc1.jpg',
        description: 'Deep bathroom cleaning with disinfectants.',
      ),
      ServiceProduct(
        name: 'Cleaning',
        price: 500,
        imagePath: 'assets/bc2.jpg',
        description: 'Quick washroom cleaning for daily upkeep.',
      ),
      ServiceProduct(
        name: 'Cleaning',
        price: 1200,
        imagePath: 'assets/bc3.jpg',
        description: 'Tiles and commode deep cleaning included.',
      ),
      ServiceProduct(
        name: 'Cleaning',
        price: 500,
        imagePath: 'assets/bc4.jpg',
        description: 'Surface-level bathroom cleaning in 30 minutes.',
      ),
    ],
    'Floor Cleaning': [
      ServiceProduct(
        name: 'Office Floor',
        price: 2000,
        imagePath: 'assets/f1.jpg',
        description:
            'Office floor cleaning using industrial vacuum and polish.',
      ),
      ServiceProduct(
        name: 'Home Floor',
        price: 1200,
        imagePath: 'assets/f2.jpg',
        description:
            'Home floor cleaning with disinfectants and shine treatment.',
      ),
      ServiceProduct(
        name: 'Mall Floor',
        price: 1000,
        imagePath: 'assets/f3.jpg',
        description: 'Large area cleaning using scrubber-dryer machines.',
      ),
      ServiceProduct(
        name: 'Shops Floor',
        price: 800,
        imagePath: 'assets/f4.jpg',
        description: 'Quick cleaning and mopping for retail spaces.',
      ),
    ],
    'Electronics Cleaning': [
      ServiceProduct(
        name: 'Fans',
        price: 2000,
        imagePath: 'assets/fan.jpg',
        description: 'Dust removal and fan motor cleaning service.',
      ),
      ServiceProduct(
        name: 'Fridge',
        price: 1200,
        imagePath: 'assets/fridge.jpg',
        description: 'Complete fridge interior and exterior cleaning.',
      ),
      ServiceProduct(
        name: 'Coolers',
        price: 500,
        imagePath: 'assets/cooler.jpg',
        description: 'Cooler water tank and pads cleaning for better cooling.',
      ),
      ServiceProduct(
        name: 'Air Conditioners',
        price: 500,
        imagePath: 'assets/ac.jpg',
        description: 'AC indoor and outdoor unit cleaning using jet spray.',
      ),
    ],
  },

  // 🔨 CARPENTER
  'Carpenter': {
    'Bed & Bedroom': [
      ServiceProduct(
        name: 'Bed Making',
        price: 6000,
        imagePath: 'assets/be1.jpg',
        description: 'Custom-made wooden bed according to size and design.',
      ),
      ServiceProduct(
        name: 'Room Making',
        price: 8500,
        imagePath: 'assets/be2.jpg',
        description: 'Complete room carpentry work including wardrobes.',
      ),
      ServiceProduct(
        name: 'Bed Making',
        price: 7987,
        imagePath: 'assets/be3.jpg',
        description: 'Solid wood bed design with finishing options.',
      ),
      ServiceProduct(
        name: 'Room Making',
        price: 8900,
        imagePath: 'assets/be1.jpg',
        description: 'Bedroom carpentry with shelves and dressing table setup.',
      ),
    ],
    'Mandir': [
      ServiceProduct(
        name: 'Mandir Making',
        price: 600,
        imagePath: 'assets/mandir.jpg',
        description: 'Compact mandir design in MDF or teak wood.',
      ),
      ServiceProduct(
        name: 'Mandir Making',
        price: 1000,
        imagePath: 'assets/man1.jfif',
        description: 'Customized pooja mandir for homes with carvings.',
      ),
      ServiceProduct(
        name: 'Mandir Making',
        price: 5000,
        imagePath: 'assets/man2.jfif',
        description: 'Large wooden mandir with intricate artwork.',
      ),
      ServiceProduct(
        name: 'Mandir Making',
        price: 9500,
        imagePath: 'assets/man3.jfif',
        description: 'Temple-style mandir for home interiors.',
      ),
      ServiceProduct(
        name: 'Mandir Making',
        price: 800,
        imagePath: 'assets/man4.jfif',
        description: 'Budget-friendly compact pooja mandir.',
      ),
    ],
    'Tv Unit': [
      ServiceProduct(
        name: 'Tv Unit Making',
        price: 600,
        imagePath: 'assets/tv.jpg',
        description: 'Wall-mounted or cabinet-style TV unit designs.',
      ),
      ServiceProduct(
        name: 'Tv Unit Making',
        price: 600,
        imagePath: 'assets/tv1.jpg',
        description: 'Modern TV cabinet with storage shelves.',
      ),
      ServiceProduct(
        name: 'Tv Unit Making',
        price: 600,
        imagePath: 'assets/tv2.jpg',
        description: 'Customized TV unit with laminate finish.',
      ),
      ServiceProduct(
        name: 'Tv Unit Making',
        price: 600,
        imagePath: 'assets/tv3.jpg',
        description: 'Minimalist wall-mounted entertainment unit.',
      ),
      ServiceProduct(
        name: 'Tv Unit Making',
        price: 600,
        imagePath: 'assets/tv4.jpg',
        description: 'Premium wooden TV stand with drawers.',
      ),
    ],
  },

 // 👕 LAUNDRY
'Laundry': {

  /// 🔹 DRY CLEANING
  'Dry Cleaning': [
    ServiceProduct(
      name: 'Shirt Dry Cleaning',
      price: 120,
      imagePath: 'assets/shirt.jpg',
      description: 'Professional dry cleaning for shirts with stain removal.',
      time: '48 Hours',
      discount: 10,
      slogan: 'Professional dry cleaning for shirts.',
      includes: [
        'Deep stain removal',
        'Premium fabric care',
        'Safe chemical cleaning',
        'Professional finishing',
      ],
    ),
    ServiceProduct(
      name: 'Suit Dry Cleaning',
      price: 350,
      imagePath: 'assets/blazzer.jpg',
      description: 'Premium cleaning service for formal suits.',
      time: '72 Hours',
      discount: 15,
      slogan: 'Premium cleaning for formal suits.',
      includes: [
        'Luxury fabric care',
        'Deep stain removal',
        'Shape retention',
        'Professional finishing',
      ],
    ),
    ServiceProduct(
      name: 'Saree Dry Cleaning',
      price: 250,
      imagePath: 'assets/saree.jpg',
      description: 'Safe cleaning for delicate sarees with color protection.',
      time: '72 Hours',
      discount: 12,
      slogan: 'Safe dry cleaning for delicate sarees.',
      includes: [
        'Color protection',
        'Fabric-safe cleaning',
        'Soft finishing',
        'Premium care',
      ],
    ),
    ServiceProduct(
      name: 'Curtain Dry Cleaning',
      price: 220,
      imagePath: 'assets/curtain.jpg',
      description: 'Professional dry cleaning for curtains.',
      time: '72 Hours',
      discount: 10,
      slogan: 'Deep cleaning for large fabrics.',
      includes: [
        'Dust removal',
        'Fabric protection',
        'Odor removal',
        'Fresh finish',
      ],
    ),
  ],

  /// 🔹 IRONING
  'Ironing': [
    ServiceProduct(
      name: 'Shirt Ironing',
      price: 15,
      imagePath: 'assets/ironing.jpg',
      description: 'Crisp and wrinkle-free shirt ironing.',
      time: 'Same Day',
      discount: 5,
      slogan: 'Crisp and wrinkle-free shirts.',
      includes: [
        'Smooth finish',
        'Fabric-safe heat',
        'Neat folding',
      ],
    ),
    ServiceProduct(
      name: 'Pant Ironing',
      price: 20,
      imagePath: 'assets/pant.jpg',
      description: 'Perfectly pressed pants.',
      time: 'Same Day',
      discount: 5,
      slogan: 'Perfectly pressed pants.',
      includes: [
        'Sharp crease',
        'Wrinkle-free',
        'Professional finish',
      ],
    ),
    ServiceProduct(
      name: 'Saree Ironing',
      price: 40,
      imagePath: 'assets/saree.jpg',
      description: 'Smooth and neat saree ironing.',
      time: 'Same Day',
      discount: 8,
      slogan: 'Smooth and neat saree ironing.',
      includes: [
        'Delicate handling',
        'Even pressing',
        'No fabric damage',
      ],
    ),
    ServiceProduct(
      name: 'Dress Ironing',
      price: 30,
      imagePath: 'assets/dress.jpg',
      description: 'Wrinkle-free dresses.',
      time: 'Same Day',
      discount: 5,
      slogan: 'Wrinkle-free dresses every time.',
      includes: [
        'Soft pressing',
        'Neat finish',
        'Quick service',
      ],
    ),
  ],

  /// 🔹 CURTAIN CLEANING
  'Curtain Cleaning': [
    ServiceProduct(
      name: 'Window Curtain Cleaning',
      price: 120,
      imagePath: 'assets/curtain.jpg',
      description: 'Dust-free curtain cleaning.',
      time: '48 Hours',
      discount: 10,
      slogan: 'Dust-free and fresh curtains.',
      includes: [
        'Deep dust removal',
        'Fabric-safe wash',
        'Fresh fragrance',
      ],
    ),
    ServiceProduct(
      name: 'Heavy Curtain Cleaning',
      price: 200,
      imagePath: 'assets/curtain.jpg',
      description: 'Deep cleaning for heavy curtains.',
      time: '72 Hours',
      discount: 12,
      slogan: 'Deep cleaning for heavy curtains.',
      includes: [
        'Heavy fabric care',
        'Stain removal',
        'Odor removal',
      ],
    ),
    ServiceProduct(
      name: 'Dry Curtain Cleaning',
      price: 220,
      imagePath: 'assets/curtain.jpg',
      description: 'Dry cleaning for curtains.',
      time: '72 Hours',
      discount: 10,
      slogan: 'Professional curtain dry cleaning.',
      includes: [
        'No water damage',
        'Color protection',
        'Premium finish',
      ],
    ),
  ],

  'Shoe Cleaning': [
  ServiceProduct(
    name: 'Sports Shoe Cleaning',
    price: 150,
    imagePath: 'assets/shoe.jpg',
    description:
        'Deep cleaning for sports shoes with stain and odor removal.',
    time: '48 Hours',
    discount: 10,
    slogan: 'Restore the freshness of sports shoes.',
    includes: [
      'Dirt and stain removal',
      'Odor cleaning',
      'Deep washing process',
      'Proper drying'
    ],
    process: [
      'Step 1: Inspection',
      'Step 2: Cleaning',
      'Step 3: Drying',
      'Step 4: Final check'
    ],
  ),

  ServiceProduct(
    name: 'Leather Shoe Cleaning',
    price: 200,
    imagePath: 'assets/leather.jpg',
    description:
        'Premium cleaning service for leather shoes with special care.',
    time: '48 Hours',
    discount: 12,
    slogan: 'Premium care for leather shoes.',
    includes: [
      'Dirt removal',
      'Leather-safe cleaning',
      'Odor treatment',
      'Proper drying'
    ],
    process: [
      'Step 1: Inspection',
      'Step 2: Leather-safe cleaning',
      'Step 3: Conditioning',
      'Step 4: Drying'
    ],
  ),

  ServiceProduct(
    name: 'Sneaker Cleaning',
    price: 180,
    imagePath: 'assets/shoe.jpg',
    description:
        'Deep cleaning for sneakers to maintain style and hygiene.',
    time: '48 Hours',
    discount: 10,
    slogan: 'Deep cleaning for trendy sneakers.',
    includes: [
      'Stain removal',
      'Odor cleaning',
      'Deep wash',
      'Drying'
    ],
    process: [
      'Step 1: Inspection',
      'Step 2: Cleaning',
      'Step 3: Drying',
      'Step 4: Finishing'
    ],
  ),
],

  /// 🔹 BEDSHEET CLEANING
  'Bedsheet Cleaning': [
    ServiceProduct(
      name: 'Single Bedsheet Cleaning',
      price: 80,
      imagePath: 'assets/sheets.jpg',
      description: 'Hygienic bedsheet cleaning.',
      time: '24 Hours',
      discount: 8,
      slogan: 'Fresh and hygienic bedsheets.',
      includes: [
        'Hygienic wash',
        'Soft fabric care',
        'Proper drying',
      ],
    ),
    ServiceProduct(
      name: 'Double Bedsheet Cleaning',
      price: 120,
      imagePath: 'assets/sheets.jpg',
      description: 'Soft and clean bedsheets.',
      time: '24 Hours',
      discount: 10,
      slogan: 'Soft and clean double bedsheets.',
      includes: [
        'Deep cleaning',
        'Soft finish',
        'Fresh fragrance',
      ],
    ),
    ServiceProduct(
      name: 'Bedsheet Deep Cleaning',
      price: 180,
      imagePath: 'assets/sheets.jpg',
      description: 'Deep hygienic cleaning.',
      time: '48 Hours',
      discount: 12,
      slogan: 'Deep hygienic cleaning for bedsheets.',
      includes: [
        'Bacteria removal',
        'Deep stain cleaning',
        'Premium wash',
      ],
    ),
  ],
},
  
  
// 🚰 PLUMBING
'Plumbing': {

  /// 🔹 PIPE REPAIR
  'Pipe Repair': [
    ServiceProduct(
      name: 'Pipe Leakage Repair',
      price: 400,
      imagePath: 'assets/pipe_repair.jpg',
      description: 'Fix leaking pipes and restore smooth water flow.',
      time: '30-60 mins',
      discount: 15,
      slogan: 'Quick fix for leaking pipes.',
      includes: [
        'Pipe inspection',
        'Leak detection',
        'Repair work',
        'Testing',
      ],
      process: [
        'Inspection',
        'Problem identification',
        'Repair',
        'Testing',
      ],
    ),
    ServiceProduct(
      name: 'Broken Pipe Fix',
      price: 600,
      imagePath: 'assets/tap_install.jpg',
      description: 'Repair damaged pipes efficiently.',
      time: '45-90 mins',
      discount: 20,
      slogan: 'Reliable pipe repair solution.',
      includes: [
        'Damage inspection',
        'Pipe fixing',
        'Seal testing',
      ],
      process: [
        'Inspect damage',
        'Repair pipe',
        'Test flow',
      ],
    ),
    ServiceProduct(
      name: 'Pipe Replacement',
      price: 1200,
      imagePath: 'assets/tap_install.jpg',
      description: 'Complete pipe replacement service.',
      time: '60-90 mins',
      discount: 20,
      slogan: 'Long-lasting pipe replacement.',
      includes: [
        'Old pipe removal',
        'New pipe installation',
        'Testing',
      ],
      process: [
        'Remove old pipe',
        'Install new pipe',
        'Testing',
      ],
    ),
  ],

  /// 🔹 LEAKAGE FIX
  'Leakage Fix': [
    ServiceProduct(
      name: 'Kitchen Pipe Leakage Fix',
      price: 400,
      imagePath: 'assets/kitchen.jpg',
      description: 'Stop kitchen leakage instantly.',
      time: '40-60 mins',
      discount: 10,
      slogan: 'Quick kitchen leak solution.',
      includes: [
        'Leak detection',
        'Seal fixing',
        'Testing',
      ],
      process: [
        'Detect leak',
        'Fix leakage',
        'Testing',
      ],
    ),
    ServiceProduct(
      name: 'Bathroom Leakage Fix',
      price: 450,
      imagePath: 'assets/bathroom.jpg',
      description: 'Fix bathroom pipe leakages.',
      time: '40-60 mins',
      discount: 12,
      slogan: 'Bathroom leak repair experts.',
      includes: [
        'Inspection',
        'Leak fixing',
        'Testing',
      ],
    ),
  ],

  /// 🔹 TAP INSTALLATION
  'Tap Installation': [
    ServiceProduct(
      name: 'New Tap Installation',
      price: 300,
      imagePath: 'assets/tap_install.jpg',
      description: 'Install new taps professionally.',
      time: '20-40 mins',
      discount: 10,
      slogan: 'Smooth tap installation.',
      includes: [
        'Tap fitting',
        'Connection setup',
        'Testing',
      ],
    ),
    ServiceProduct(
      name: 'Tap Replacement',
      price: 350,
      imagePath: 'assets/pipe_repair.jpg',
      description: 'Replace old taps easily.',
      time: '20-40 mins',
      discount: 12,
      slogan: 'Upgrade your tap easily.',
      includes: [
        'Remove old tap',
        'Install new tap',
        'Testing',
      ],
    ),
  ],

  /// 🔹 DRAIN CLEANING
  'Drain Cleaning': [
    ServiceProduct(
      name: 'Kitchen Drain Cleaning',
      price: 400,
      imagePath: 'assets/cleaning.png',
      description: 'Remove kitchen blockages.',
      time: '45-60 mins',
      discount: 10,
      slogan: 'Clog-free kitchen drains.',
      includes: [
        'Drain cleaning',
        'Block removal',
        'Pipe flushing',
      ],
    ),
    ServiceProduct(
      name: 'Blocked Drain Fix',
      price: 600,
      imagePath: 'assets/drain.jpg',
      description: 'Clear heavy blockages.',
      time: '60 mins',
      discount: 15,
      slogan: 'Heavy blockage solution.',
      includes: [
        'Inspection',
        'Cleaning',
        'Testing',
      ],
    ),
  ],

  /// 🔹 BATHROOM REPAIR
  'Bathroom Repair': [
    ServiceProduct(
      name: 'Shower Repair',
      price: 400,
      imagePath: 'assets/bathroom.jpg',
      description: 'Fix shower issues quickly.',
      time: '40-60 mins',
      discount: 10,
      slogan: 'Quick shower repair.',
      includes: [
        'Inspection',
        'Repair',
        'Testing',
      ],
    ),
    ServiceProduct(
      name: 'Bathroom Pipe Repair',
      price: 600,
      imagePath: 'assets/tap.jpg',
      description: 'Repair bathroom pipes.',
      time: '45-60 mins',
      discount: 15,
      slogan: 'Reliable bathroom repair.',
      includes: [
        'Pipe repair',
        'Leak fix',
        'Testing',
      ],
    ),
  ],

  /// 🔹 TOILET REPAIR
  'Toilet Repair': [
    ServiceProduct(
      name: 'Toilet Flush Repair',
      price: 300,
      imagePath: 'assets/tap.jpg',
      description: 'Fix flush problems.',
      time: '30-45 mins',
      discount: 10,
      slogan: 'Quick flush repair.',
      includes: [
        'Flush repair',
        'Testing',
      ],
    ),
    ServiceProduct(
      name: 'Toilet Leakage Fix',
      price: 450,
      imagePath: 'assets/tap.jpg',
      description: 'Stop toilet leakage.',
      time: '30-45 mins',
      discount: 10,
      slogan: 'Leak-free toilet solution.',
      includes: [
        'Leak fixing',
        'Seal check',
        'Testing',
      ],
    ),
  ],

  /// 🔹 SINK INSTALLATION
  'Sink Installation': [
    ServiceProduct(
      name: 'Kitchen Sink Installation',
      price: 800,
      imagePath: 'assets/kitchen.jpg',
      description: 'Install kitchen sinks perfectly.',
      time: '40-60 mins',
      discount: 15,
      slogan: 'Perfect sink installation.',
      includes: [
        'Sink setup',
        'Pipe connection',
        'Testing',
      ],
    ),
    ServiceProduct(
      name: 'Sink Replacement',
      price: 900,
      imagePath: 'assets/sink.jpg',
      description: 'Replace old sinks easily.',
      time: '40-60 mins',
      discount: 20,
      slogan: 'Upgrade your sink.',
      includes: [
        'Remove old sink',
        'Install new sink',
        'Testing',
      ],
    ),
  ],
},
       
};

