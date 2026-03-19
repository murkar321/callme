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

// 👕 LAUNDRY
  'Laundry': {
    /// WASHING
    'Washing': [
      ServiceProduct(
        name: 'Shirt Washing',
        price: 60,
        imagePath: 'assets/wash.jfif',
        description:
            'Professional cleaning to remove dirt, sweat, and stains while keeping fabric fresh and soft.',
        time: '24 Hours',
        discount: 10,
        slogan: 'Fresh and clean shirt washing service.',
        includes: [
          'Deep fabric cleaning',
          'Quality detergent washing',
          'Fabric softener treatment',
          'Fresh fragrance finish',
        ],
      ),
      ServiceProduct(
        name: 'Pant Washing',
        price: 70,
        imagePath: 'assets/pant.jpg',
        description:
            'Proper cleaning for trousers and everyday pants while maintaining fabric quality and color.',
        time: '24 Hours',
        discount: 10,
        slogan: 'Proper washing for everyday pants.',
        includes: [
          'Deep fabric cleaning',
          'Color protection',
          'Fabric softener treatment',
          'Proper drying process',
        ],
      ),
      ServiceProduct(
        name: 'Suit Washing',
        price: 200,
        imagePath: 'assets/blazzer.jpg',
        description:
            'Careful washing for formal suits with premium fabric care.',
        time: '48 Hours',
        discount: 12,
        slogan: 'Careful washing for formal suits.',
        includes: [
          'Premium fabric care',
          'Deep stain removal',
          'Shape retention',
          'Professional finishing',
        ],
      ),
      ServiceProduct(
        name: 'Saree Washing',
        price: 150,
        imagePath: 'assets/saree.jpg',
        description:
            'Gentle cleaning for delicate sarees while protecting fabric, color, and design.',
        time: '48 Hours',
        discount: 10,
        slogan: 'Gentle washing for delicate sarees.',
        includes: [
          'Gentle washing process',
          'Fabric protection',
          'Color-safe cleaning',
          'Fresh fragrance finish',
        ],
      ),
      ServiceProduct(
        name: 'Curtain Washing',
        price: 120,
        imagePath: 'assets/curtain.jpg',
        description:
            'Removes dust, stains, and allergens to keep curtains fresh and hygienic.',
        time: '48 Hours',
        discount: 10,
        slogan: 'Dust-free and fresh curtain washing.',
        includes: [
          'Deep dust removal',
          'Fabric-safe washing',
          'Color protection',
          'Fresh fragrance',
        ],
      ),
      ServiceProduct(
        name: 'Shoe Washing',
        price: 130,
        imagePath: 'assets/shoe.jpg',
        description:
            'Deep cleaning to remove dirt, stains, and odor while restoring freshness.',
        time: '48 Hours',
        discount: 10,
        slogan: 'Clean and refreshed shoes.',
        includes: [
          'Dirt and stain removal',
          'Deep washing process',
          'Odor cleaning',
          'Proper drying',
        ],
      ),
      ServiceProduct(
        name: 'Bedsheet Washing',
        price: 90,
        imagePath: 'assets/sheets.jpg',
        description:
            'Ensures hygienic cleaning and removal of dirt, bacteria, and stains.',
        time: '24 Hours',
        discount: 8,
        slogan: 'Soft, fresh and hygienic bedsheets.',
        includes: [
          'Hygienic deep cleaning',
          'Soft fabric care',
          'Fresh fragrance finish',
          'Proper drying and folding',
        ],
      ),
    ],

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
        name: 'Blazer Dry Cleaning',
        price: 300,
        imagePath: 'assets/blazzer.jpg',
        description: 'Expert cleaning for blazers and jackets.',
        time: '72 Hours',
        discount: 10,
        slogan: 'Keep your blazer sharp and fresh.',
        includes: [
          'Odor removal',
          'Shape retention',
          'Soft fabric care',
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
      ServiceProduct(
        name: 'Kids Clothes Ironing',
        price: 10,
        imagePath: 'assets/kids.jfif',
        description: 'Gentle ironing for kids’ clothes.',
        time: 'Same Day',
        discount: 5,
        slogan: 'Soft care for little ones.',
        includes: [
          'Delicate handling',
          'Smooth finish',
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
        name: 'Luxury Curtain Cleaning',
        price: 300,
        imagePath: 'assets/curtain.jpg',
        description: 'Premium cleaning for luxury curtains.',
        time: '72 Hours',
        discount: 15,
        slogan: 'Luxury care for your curtains.',
        includes: [
          'Color protection',
          'Premium fabric care',
          'Fresh scent',
        ],
      ),
    ],

    /// 🔹 SHOE CLEANING
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
        includes: ['Stain removal', 'Odor cleaning', 'Deep wash', 'Drying'],
        process: [
          'Step 1: Inspection',
          'Step 2: Cleaning',
          'Step 3: Drying',
          'Step 4: Finishing'
        ],
      ),
      ServiceProduct(
        name: 'Boot Cleaning',
        price: 220,
        imagePath: 'assets/boots.jfif',
        description: 'Special cleaning for boots to maintain shine and shape.',
        time: '48 Hours',
        discount: 12,
        slogan: 'Shiny and fresh boots every time.',
        includes: [
          'Deep dirt removal',
          'Polish treatment',
          'Proper drying',
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
      ServiceProduct(
        name: 'Luxury Bedsheet Cleaning',
        price: 250,
        imagePath: 'assets/sheets.jpg',
        description: 'Premium care for luxury bedsheets.',
        time: '48 Hours',
        discount: 15,
        slogan: 'Luxury care for your bedsheets.',
        includes: [
          'Fabric-safe deep wash',
          'Premium finishing',
          'Fresh fragrance',
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

// 🧹 CLEANING SERVICES
  'Cleaning': {
    /// 🔹 HOME CLEANING
    'Home Cleaning': [
      ServiceProduct(
        name: '1 BHK Full Cleaning',
        price: 999,
        imagePath: 'assets/1bhk.jfif',
        description:
            'Complete cleaning solution for small homes with proper dust removal and hygiene care.',
        time: '2–3 Hours',
        discount: 20,
        slogan: 'Complete cleaning for small homes',
        includes: [
          'Floor sweeping & mopping',
          'Furniture dusting',
          'Kitchen surface cleaning',
          'Bathroom cleaning',
          'Cobweb removal',
        ],
      ),
      ServiceProduct(
        name: '2 BHK Full Cleaning',
        price: 1499,
        imagePath: 'assets/2bhk.jfif',
        description:
            'Ideal for medium homes with detailed cleaning of all rooms and common areas.',
        time: '3–4 Hours',
        discount: 20,
        slogan: 'Perfect cleaning for medium homes',
        includes: [
          'Full house cleaning',
          'Kitchen & bathroom cleaning',
          'Dust removal from all surfaces',
        ],
      ),
      ServiceProduct(
        name: '3 BHK Full Cleaning',
        price: 1999,
        imagePath: 'assets/3bhk.jfif',
        description:
            'Deep and detailed cleaning for large homes ensuring every corner is covered.',
        time: '4–5 Hours',
        discount: 25,
        slogan: 'Deep cleaning for large homes',
        includes: [
          'Complete house cleaning',
          'Deep dusting',
          'Mopping',
          'Bathroom & kitchen cleaning',
        ],
      ),
      ServiceProduct(
        name: 'Living Room Cleaning',
        price: 399,
        imagePath: 'assets/living.jfif',
        description:
            'Focused cleaning of your living space to maintain freshness and hygiene.',
        time: '60 Minutes',
        discount: 10,
        slogan: 'Fresh and dust free living space',
        includes: [
          'Sofa dusting',
          'Table cleaning',
          'TV unit cleaning',
          'Floor mopping',
        ],
      ),
      ServiceProduct(
        name: 'Bedroom Cleaning',
        price: 349,
        imagePath: 'assets/bedroom.jfif',
        description:
            'Clean and relaxing bedroom environment with proper dust removal.',
        time: '45 Minutes',
        discount: 10,
        slogan: 'Clean and relaxing bedroom',
        includes: [
          'Bed area cleaning',
          'Furniture dusting',
          'Floor cleaning',
        ],
      ),
    ],

    /// 🔹 KITCHEN CLEANING
    'Kitchen Cleaning': [
      ServiceProduct(
        name: 'Basic Kitchen Cleaning',
        price: 499,
        imagePath: 'assets/kitchen.jpg',
        description: 'Quick cleaning for daily kitchen maintenance.',
        time: '60 Minutes',
        discount: 10,
        slogan: 'Quick kitchen refresh',
        includes: [
          'Slab cleaning',
          'Sink wash',
          'Basic surface cleaning',
        ],
      ),
      ServiceProduct(
        name: 'Deep Kitchen Cleaning',
        price: 1199,
        imagePath: 'assets/kitchen.jpg',
        description:
            'Complete grease and stain removal for a hygienic kitchen.',
        time: '2–3 Hours',
        discount: 20,
        slogan: 'Remove grease and tough stains',
        includes: [
          'Grease removal',
          'Slab, tiles cleaning',
          'Cabinet exterior cleaning',
        ],
      ),
      ServiceProduct(
        name: 'Chimney Cleaning',
        price: 599,
        imagePath: 'assets/chimney.jfif',
        description: 'Improves airflow and removes oil buildup from chimney.',
        time: '60 Minutes',
        discount: 15,
        slogan: 'Smoke free kitchen experience',
        includes: [
          'Filter cleaning',
          'Outer body cleaning',
        ],
      ),
      ServiceProduct(
        name: 'Stove Cleaning',
        price: 299,
        imagePath: 'assets/stove.jfif',
        description: 'Makes your stove shine by removing oil and stains.',
        time: '30 Minutes',
        discount: 10,
        slogan: 'Sparkling clean stove',
        includes: [
          'Burner cleaning',
          'Surface cleaning',
        ],
      ),
      ServiceProduct(
        name: 'Kitchen Cabinet Cleaning',
        price: 399,
        imagePath: 'assets/cabinet.jfif',
        description: 'Clean and organized cabinets inside and outside.',
        time: '45 Minutes',
        discount: 10,
        slogan: 'Clean and organized cabinets',
        includes: [
          'Internal cleaning',
          'External cleaning',
        ],
      ),
    ],

    /// 🔹 BATHROOM CLEANING
    'Bathroom Cleaning': [
      ServiceProduct(
        name: 'Basic Bathroom Cleaning',
        price: 399,
        imagePath: 'assets/bathroom.jpg',
        description: 'Regular cleaning to maintain hygiene.',
        time: '45 Minutes',
        discount: 10,
        slogan: 'Quick bathroom refresh',
        includes: [
          'Toilet cleaning',
          'Sink & mirror cleaning',
          'Floor cleaning',
        ],
      ),
      ServiceProduct(
        name: 'Deep Bathroom Cleaning',
        price: 799,
        imagePath: 'assets/bathroom.jpg',
        description: 'Removes tough stains and bacteria for deep hygiene.',
        time: '90 Minutes',
        discount: 15,
        slogan: 'Remove stains and bacteria',
        includes: [
          'Tile scrubbing',
          'Stain removal',
          'Full sanitization',
        ],
      ),
      ServiceProduct(
        name: 'Toilet Cleaning',
        price: 299,
        imagePath: 'assets/toilet.jfif',
        description: 'Focused cleaning for toilet hygiene.',
        time: '30 Minutes',
        discount: 10,
        slogan: 'Hygienic toilet cleaning',
        includes: [
          'Toilet seat cleaning',
          'Pot cleaning',
          'Area cleaning',
        ],
      ),
      ServiceProduct(
        name: 'Tile & Grout Cleaning',
        price: 499,
        imagePath: 'assets/tiles.jfif',
        description: 'Restores shine of tiles by removing dirt from gaps.',
        time: '60 Minutes',
        discount: 10,
        slogan: 'Shine your bathroom tiles',
        includes: [
          'Tile cleaning',
          'Grout cleaning',
        ],
      ),
      ServiceProduct(
        name: 'Hard Water Stain Removal',
        price: 599,
        imagePath: 'assets/stain.jfif',
        description: 'Removes white and yellow stains caused by hard water.',
        time: '60 Minutes',
        discount: 15,
        slogan: 'Remove tough water stains',
        includes: [
          'Tap cleaning',
          'Tile cleaning',
          'Fittings cleaning',
        ],
      ),
    ],

    /// 🔹 SOFA CLEANING
    'Sofa Cleaning': [
      ServiceProduct(
        name: 'Fabric Sofa Cleaning',
        price: 599,
        imagePath: 'assets/sofa.jfif',
        description: 'Fresh and dust free sofa cleaning.',
        time: '60 Minutes',
        discount: 15,
        slogan: 'Fresh and dust free sofa',
        includes: [
          'Dust removal',
          'Fabric cleaning',
        ],
      ),
      ServiceProduct(
        name: 'Leather Sofa Cleaning',
        price: 699,
        imagePath: 'assets/sofa.jpg',
        description: 'Safe care for leather sofas.',
        time: '60 Minutes',
        discount: 15,
        slogan: 'Safe care for leather sofas',
        includes: [
          'Leather safe cleaning',
          'Polishing',
        ],
      ),
      ServiceProduct(
        name: 'L-Shaped Sofa Cleaning',
        price: 999,
        imagePath: 'assets/sofa.jfif',
        description: 'Deep clean for large sofas.',
        time: '90 Minutes',
        discount: 20,
        slogan: 'Deep clean for large sofas',
        includes: [
          'Deep vacuuming',
          'Full surface cleaning',
        ],
      ),
      ServiceProduct(
        name: 'Cushion Cleaning',
        price: 299,
        imagePath: 'assets/cushion.jfif',
        description: 'Clean and fresh cushions.',
        time: '30 Minutes',
        discount: 10,
        slogan: 'Clean and fresh cushions',
        includes: [
          'Dust removal',
          'Fabric cleaning',
        ],
      ),
      ServiceProduct(
        name: 'Sofa Stain Removal',
        price: 399,
        imagePath: 'assets/stain.jfif',
        description: 'Remove stubborn stains easily.',
        time: '45 Minutes',
        discount: 10,
        slogan: 'Remove stubborn stains easily',
        includes: [
          'Stain treatment',
          'Spot cleaning',
        ],
      ),
    ],
  }
};
