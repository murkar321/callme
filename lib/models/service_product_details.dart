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
    ),
    ServiceProduct(
      name: 'Suit Dry Cleaning',
      price: 350,
      imagePath: 'assets/blazzer.jpg',
      description: 'Premium cleaning service for formal suits.',
    ),
    ServiceProduct(
      name: 'Saree Dry Cleaning',
      price: 250,
      imagePath: 'assets/saree.jpg',
      description: 'Safe cleaning for delicate sarees with color protection.',
    ),
    ServiceProduct(
      name: 'Curtain Dry Cleaning',
      price: 220,
      imagePath: 'assets/curtain.jpg',
      description: 'Professional dry cleaning for curtains and large fabrics.',
    ),
  ],

  /// 🔹 IRONING
  'Ironing': [
    ServiceProduct(
      name: 'Shirt Ironing',
      price: 15,
      imagePath: 'assets/ironing.jpg',
      description: 'Crisp and wrinkle-free shirt ironing.',
    ),
    ServiceProduct(
      name: 'Pant Ironing',
      price: 20,
      imagePath: 'assets/pant.jpg',
      description: 'Perfectly pressed pants with sharp crease.',
    ),
    ServiceProduct(
      name: 'Saree Ironing',
      price: 40,
      imagePath: 'assets/saree.jpg',
      description: 'Smooth and neat saree ironing service.',
    ),
    ServiceProduct(
      name: 'Dress Ironing',
      price: 30,
      imagePath: 'assets/dress.jpg',
      description: 'Wrinkle-free ironing for all dresses.',
    ),
  ],

  /// 🔹 SHOE CLEANING
  'Shoe Cleaning': [
    ServiceProduct(
      name: 'Sports Shoe Cleaning',
      price: 150,
      imagePath: 'assets/shoe.jpg',
      description: 'Deep cleaning for sports shoes.',
    ),
    ServiceProduct(
      name: 'Leather Shoe Cleaning',
      price: 200,
      imagePath: 'assets/leather.jpg',
      description: 'Premium care for leather shoes.',
    ),
    ServiceProduct(
      name: 'Sneaker Cleaning',
      price: 180,
      imagePath: 'assets/dry.jpg',
      description: 'Deep cleaning for trendy sneakers.',
    ),
  ],

  /// 🔹 CURTAIN CLEANING
  'Curtain Cleaning': [
    ServiceProduct(
      name: 'Window Curtain Cleaning',
      price: 120,
      imagePath: 'assets/curtain.jpg',
      description: 'Dust-free and fresh curtain cleaning.',
    ),
    ServiceProduct(
      name: 'Heavy Curtain Cleaning',
      price: 200,
      imagePath: 'assets/curtain.jpg',
      description: 'Deep cleaning for heavy curtains.',
    ),
    ServiceProduct(
      name: 'Dry Curtain Cleaning',
      price: 220,
      imagePath: 'assets/curtain.jpg',
      description: 'Professional dry cleaning for curtains.',
    ),
  ],

  /// 🔹 BEDSHEET CLEANING
  'Bedsheet Cleaning': [
    ServiceProduct(
      name: 'Single Bedsheet Cleaning',
      price: 80,
      imagePath: 'assets/sheets.jpg',
      description: 'Fresh and hygienic single bedsheet cleaning.',
    ),
    ServiceProduct(
      name: 'Double Bedsheet Cleaning',
      price: 120,
      imagePath: 'assets/sheets.jpg',
      description: 'Soft and clean double bedsheets.',
    ),
    ServiceProduct(
      name: 'Bedsheet Deep Cleaning',
      price: 180,
     imagePath: 'assets/sheets.jpg',
      description: 'Deep hygienic cleaning for bedsheets.',
    ),
  ],
},

  // REAL ESTATE
  'Real Estate': {
    '1BHK': [
      ServiceProduct(
        name: '1BHK',
        price: 15000,
        imagePath: 'assets/1bhk.jfif',
        description: 'Complete 1BHK interior design and decoration service.',
      ),
      ServiceProduct(
        name: '1BHK',
        price: 15000,
        imagePath: 'assets/1bhk.jfif',
        description: 'Complete 1BHK interior design and decoration service.',
      ),
    ],
    '2BHK': [
      ServiceProduct(
        name: '2BHK',
        price: 25000,
        imagePath: 'assets/2bhk.jfif',
        description: 'Complete 2BHK interior design and decoration service.',
      ),
      ServiceProduct(
        name: '2BHK',
        price: 25000,
        imagePath: 'assets/2bhk.jfif',
        description: 'Complete 2BHK interior design and decoration service.',
      ),
    ],
    '3BHK': [
      ServiceProduct(
        name: '3BHK',
        price: 35000,
        imagePath: 'assets/3bhk.jfif',
        description: 'Complete 3BHK interior design and decoration service.',
      ),
      ServiceProduct(
        name: '3BHK',
        price: 35000,
        imagePath: 'assets/3bhk.jfif',
        description: 'Complete 3BHK interior design and decoration service.',
      ),
    ],
  },

  // 🔧 MECHANIC
  'Mechanic': {
    'Bike': [
      ServiceProduct(
        name: 'Bike Service',
        price: 800,
        imagePath: 'assets/oil.jpg',
        description: 'Basic bike servicing including oil change.',
      ),
    ],
    'Car': [
      ServiceProduct(
        name: 'Car Service',
        price: 2500,
        imagePath: 'assets/tin.jpg',
        description: 'Full car service with oil and filter replacement.',
      ),
    ],
  },
// 🚰 PLUMBING
'Plumbing': {
  'Pipe Repair': [
    ServiceProduct(
      name: 'Pipe Leakage Repair',
      price: 400,
      imagePath: 'assets/pipe_repair.jpg',
      description: 'Quick fix for leaking pipes with proper sealing.',
    ),
    ServiceProduct(
      name: 'Broken Pipe Fix',
      price: 600,
      imagePath: 'assets/tap_install.jpg',
      description: 'Reliable repair for damaged pipes.',
    ),
    ServiceProduct(
      name: 'Pipe Replacement',
      price: 1200,
      imagePath: 'assets/tap_install.jpg',
      description: 'Complete pipe replacement for long-lasting use.',
    ),
    ServiceProduct(
      name: 'Pipe Joint Repair',
      price: 350,
      imagePath: 'assets/pipe_repair.jpg',
      description: 'Fix leaking pipe joints with precision.',
    ),
    ServiceProduct(
      name: 'Wall Pipe Repair',
      price: 700,
      imagePath: 'assets/tap.jpg',
      description: 'Safe repair of concealed wall pipes.',
    ),
  ],

  'Leakage Fix': [
    ServiceProduct(
      name: 'Kitchen Pipe Leakage Fix',
      price: 400,
      imagePath: 'assets/kitchen.jpg',
      description: 'Stop kitchen pipe leaks quickly.',
    ),
    ServiceProduct(
      name: 'Bathroom Pipe Leakage Fix',
      price: 450,
      imagePath: 'assets/bathroom.jpg',
      description: 'Efficient bathroom leakage repair.',
    ),
    ServiceProduct(
      name: 'Pipe Joint Leakage Fix',
      price: 350,
      imagePath: 'assets/pipe_repair.jpg',
      description: 'Seal pipe joint leaks properly.',
    ),
    ServiceProduct(
      name: 'Tank Pipe Leakage Fix',
      price: 600,
      imagePath: 'assets/pipe_repair.jpg',
      description: 'Fix water tank pipe leakage permanently.',
    ),
  ],

  'Tap Installation': [
    ServiceProduct(
      name: 'New Tap Installation',
      price: 300,
      imagePath: 'assets/tap_install.jpg',
      description: 'Install new taps with precision.',
    ),
    ServiceProduct(
      name: 'Tap Replacement',
      price: 350,
      imagePath: 'assets/pipe_repair.jpg',
      description: 'Replace old taps easily.',
    ),
    ServiceProduct(
      name: 'Tap Leakage Fix',
      price: 200,
      imagePath: 'assets/pipe_repair.jpg',
      description: 'Fix dripping taps instantly.',
    ),
    ServiceProduct(
      name: 'Mixer Tap Installation',
      price: 500,
      imagePath: 'assets/pipe_repair.jpg',
      description: 'Install modern mixer taps.',
    ),
    ServiceProduct(
      name: 'Kitchen Tap Installation',
      price: 350,
      imagePath: 'assets/kitchen.jpg',
      description: 'Perfect kitchen tap setup.',
    ),
  ],

  'Drain Cleaning': [
    ServiceProduct(
      name: 'Kitchen Drain Cleaning',
      price: 400,
      imagePath: 'assets/cleaning.png',
      description: 'Remove kitchen blockages quickly.',
    ),
    ServiceProduct(
      name: 'Bathroom Drain Cleaning',
      price: 400,
      imagePath: 'assets/clean.jfif',
      description: 'Keep bathroom drains clean.',
    ),
    ServiceProduct(
      name: 'Blocked Drain Fix',
      price: 600,
      imagePath: 'assets/drain.jpg',
      description: 'Clear heavily blocked drains.',
    ),
    ServiceProduct(
      name: 'Drain Pipe Cleaning',
      price: 500,
      imagePath: 'assets/drain.jpg',
      description: 'Deep cleaning for drain pipes.',
    ),
  ],

  'Bathroom Repair': [
    ServiceProduct(
      name: 'Shower Repair',
      price: 400,
      imagePath: 'assets/bathroom.jpg',
      description: 'Fix faulty showers quickly.',
    ),
    ServiceProduct(
      name: 'Bathroom Pipe Repair',
      price: 600,
      imagePath: 'assets/tap.jpg',
      description: 'Repair bathroom pipes efficiently.',
    ),
    ServiceProduct(
      name: 'Shower Installation',
      price: 500,
      imagePath: 'assets/sink.jpg',
      description: 'Install new showers professionally.',
    ),
    ServiceProduct(
      name: 'Wash Basin Pipe Repair',
      price: 400,
      imagePath: 'assets/sink.jpg',
      description: 'Fix wash basin pipe issues.',
    ),
  ],

  'Toilet Repair': [
    ServiceProduct(
      name: 'Toilet Flush Repair',
      price: 300,
      imagePath: 'assets/tap.jpg',
      description: 'Fix flush issues quickly.',
    ),
    ServiceProduct(
      name: 'Toilet Leakage Fix',
      price: 450,
      imagePath: 'assets/tap.jpg',
      description: 'Stop toilet leaks effectively.',
    ),
    ServiceProduct(
      name: 'Toilet Seat Replacement',
      price: 350,
     imagePath: 'assets/tap.jpg',
      description: 'Replace damaged toilet seats.',
    ),
    ServiceProduct(
      name: 'Toilet Pipe Repair',
      price: 500,
      imagePath: 'assets/plumbing.jpg',
      description: 'Repair toilet pipe connections.',
    ),
    ServiceProduct(
      name: 'Flush Tank Repair',
      price: 400,
      imagePath: 'assets/sink.jpg',
      description: 'Fix flush tank problems.',
    ),
  ],

  'Sink Installation': [
    ServiceProduct(
      name: 'Kitchen Sink Installation',
      price: 800,
      imagePath: 'assets/kitchen.jpg',
      description: 'Install kitchen sinks perfectly.',
    ),
    ServiceProduct(
      name: 'Wash Basin Installation',
      price: 700,
      imagePath: 'assets/tap.jpg',
      description: 'Professional basin installation.',
    ),
    ServiceProduct(
      name: 'Sink Replacement',
      price: 900,
      imagePath: 'assets/sink.jpg',
      description: 'Replace old sinks easily.',
    ),
    ServiceProduct(
      name: 'Sink Pipe Connection',
      price: 400,
      imagePath: 'assets/pipe_repair.jpg',
      description: 'Proper sink pipe connections.',
    ),
    ServiceProduct(
      name: 'Sink Leakage Repair',
      price: 400,
      imagePath: 'assets/sink.jpg',
      description: 'Fix sink leakage issues quickly.',
    ),
  ],
},



       
};

