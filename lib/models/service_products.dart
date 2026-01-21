import '../models/service_product.dart';

final Map<String, Map<String, List<ServiceProduct>>> serviceProducts = {
  // 📸 PHOTOGRAPHY
  'Photography': {
    'Album': [
      ServiceProduct(
          name: 'Single Photo Half Day',
          price: 250,
          imagePath: 'assets/a1.jpg'),
      ServiceProduct(
          name: 'Children Photo Full Day',
          price: 500,
          imagePath: 'assets/a2.jpg'),
      ServiceProduct(
          name: 'Single Photo Half Day',
          price: 250,
          imagePath: 'assets/a3.jpg'),
      ServiceProduct(
          name: 'Children Photo Full Day',
          price: 500,
          imagePath: 'assets/a4.jpg'),
    ],
    'Wedding': [
      ServiceProduct(
          name: 'Wedding Photography',
          price: 10000,
          imagePath: 'assets/w1.jpg'),
      ServiceProduct(
          name: 'Pre Wedding Shoot', price: 5000, imagePath: 'assets/w2.jpg'),
      ServiceProduct(
          name: 'Wedding Photography',
          price: 10000,
          imagePath: 'assets/w3.jpg'),
      ServiceProduct(
          name: 'Pre Wedding Shoot', price: 5000, imagePath: 'assets/w4.jpg'),
    ],
    'Event': [
      ServiceProduct(
          name: 'Event Photography',
          price: 5000,
          imagePath: 'assets/event.jpg'),
      ServiceProduct(
          name: 'Corporate Event', price: 7000, imagePath: 'assets/e1.jpg'),
      ServiceProduct(
          name: 'House Event', price: 9000, imagePath: 'assets/e2.jpg'),
      ServiceProduct(
          name: 'Wedding Event', price: 8000, imagePath: 'assets/e3.jpg'),
      ServiceProduct(
          name: 'College Event', price: 1000, imagePath: 'assets/e4.jpg'),
    ],
    'Birthday': [
      ServiceProduct(
          name: 'Birthday Shoot Half Day',
          price: 1000,
          imagePath: 'assets/bi1.jpg'),
      ServiceProduct(
          name: 'Birthday Shoot Full Day',
          price: 2000,
          imagePath: 'assets/bi2.jpg'),
      ServiceProduct(
          name: 'Birthday Shoot Half Day',
          price: 1000,
          imagePath: 'assets/bi3.jpg'),
      ServiceProduct(
          name: 'Birthday Shoot Full Day',
          price: 2000,
          imagePath: 'assets/bi4.jpg'),
      ServiceProduct(
          name: 'Birthday Shoot Full Day',
          price: 2000,
          imagePath: 'assets/bi5.jpg'),
    ],
    'Baby Shower': [
      ServiceProduct(
          name: 'Baby Shower Photography',
          price: 3000,
          imagePath: 'assets/bs1.jpg'),
      ServiceProduct(
          name: 'Baby Shower Photography',
          price: 5000,
          imagePath: 'assets/bs2.jpg'),
      ServiceProduct(
          name: 'Baby Shower Photography',
          price: 10000,
          imagePath: 'assets/bs3.jpg'),
    ],
  },

  // 🧹 CLEANING
  'Cleaning': {
    'Kitchen Cleaning': [
      ServiceProduct(name: 'Cleaning', price: 1200, imagePath: 'assets/k1.jpg'),
      ServiceProduct(name: 'Cleaning', price: 500, imagePath: 'assets/k2.jpg'),
      ServiceProduct(name: 'Cleaning', price: 1200, imagePath: 'assets/k6.jpg'),
      ServiceProduct(name: 'Cleaning', price: 500, imagePath: 'assets/k4.jpg'),
      ServiceProduct(name: 'Cleaning', price: 1200, imagePath: 'assets/k5.jpg'),
    ],
    'Bathroom Cleaning': [
      ServiceProduct(
          name: 'Cleaning', price: 1200, imagePath: 'assets/bc1.jpg'),
      ServiceProduct(name: 'Cleaning', price: 500, imagePath: 'assets/bc2.jpg'),
      ServiceProduct(
          name: 'Cleaning', price: 1200, imagePath: 'assets/bc3.jpg'),
      ServiceProduct(name: 'Cleaning', price: 500, imagePath: 'assets/bc4.jpg'),
    ],
    'Floor Cleaning': [
      ServiceProduct(
          name: 'Office Floor', price: 2000, imagePath: 'assets/f1.jpg'),
      ServiceProduct(
          name: 'Home Floor', price: 1200, imagePath: 'assets/f2.jpg'),
      ServiceProduct(
          name: 'MAll Floor', price: 1000, imagePath: 'assets/f3.jpg'),
      ServiceProduct(
          name: 'Shops Floor', price: 800, imagePath: 'assets/f4.jpg'),
    ],
    'Electronics Cleaning': [
      ServiceProduct(name: 'Fans', price: 2000, imagePath: 'assets/fan.jpg'),
      ServiceProduct(
          name: 'Fridge', price: 1200, imagePath: 'assets/fridge.jpg'),
      ServiceProduct(
          name: 'Coolers', price: 500, imagePath: 'assets/cooler.jpg'),
      ServiceProduct(
          name: 'Air Conditioners', price: 500, imagePath: 'assets/ac.jpg'),
    ],
  },

  // 🔨 CARPENTER
  'Carpenter': {
    'Bed & Bedroom': [
      ServiceProduct(
          name: 'Bed Making', price: 6000, imagePath: 'assets/be1.jpg'),
      ServiceProduct(
          name: 'Room Making', price: 8500, imagePath: 'assets/be2.jpg'),
      ServiceProduct(
          name: 'Bed Making', price: 7987, imagePath: 'assets/be3.jpg'),
      ServiceProduct(
          name: 'Room Making', price: 8900, imagePath: 'assets/be1.jpg'),
    ],
    'Mandir': [
      ServiceProduct(
          name: 'Mandir Making', price: 600, imagePath: 'assets/mandir.jpg'),
      ServiceProduct(
          name: 'Mandir Making', price: 1000, imagePath: 'assets/man1.jfif'),
      ServiceProduct(
          name: 'Mandir Making', price: 5000, imagePath: 'assets/man2.jfif'),
      ServiceProduct(
          name: 'Mandir Making', price: 9500, imagePath: 'assets/man3.jfif'),
      ServiceProduct(
          name: 'Mandir Making', price: 800, imagePath: 'assets/man4.jfif'),
    ],
    'Tv Unit': [
      ServiceProduct(
          name: 'Tv Unit Making', price: 600, imagePath: 'assets/tv.jpg'),
      ServiceProduct(
          name: 'Tv Unit Making', price: 600, imagePath: 'assets/tv1.jpg'),
      ServiceProduct(
          name: 'Tv Unit Making', price: 600, imagePath: 'assets/tv2.jpg'),
      ServiceProduct(
          name: 'Tv Unit Making', price: 600, imagePath: 'assets/tv3.jpg'),
      ServiceProduct(
          name: 'Tv Unit Making', price: 600, imagePath: 'assets/tv4.jpg'),
    ],
  },

  // 🏋️ GYM
  'Gym': {
    'Membership': [
      ServiceProduct(
          name: 'Monthly Membership',
          price: 1500,
          imagePath: 'assets/member.jpg'),
      ServiceProduct(
          name: 'Yearly Membership', price: 15000, imagePath: 'assets/gym.jpg'),
    ],
    'Training': [
      ServiceProduct(
          name: 'Personal Training',
          price: 3000,
          imagePath: 'assets/personal.jpg'),
    ],
  },

  // 👕 LAUNDRY
  'Laundry': {
    'Clothes': [
      ServiceProduct(
          name: 'Wash & Iron', price: 30, imagePath: 'assets/laundry.png'),
      ServiceProduct(
          name: 'Dry Cleaning', price: 80, imagePath: 'assets/laundry.png'),
    ],
  },

  // 🧁 BAKERY
  'Bakery': {
    'Bread': [
      ServiceProduct(name: 'Bread', price: 40, imagePath: 'assets/1b.jpg'),
      ServiceProduct(name: 'Bread', price: 40, imagePath: 'assets/2b.jpg'),
      ServiceProduct(name: 'Bread', price: 40, imagePath: 'assets/3b.jpg'),
      ServiceProduct(name: 'Bread', price: 40, imagePath: 'assets/4b.jpg'),
    ],
    'Cakes': [
      ServiceProduct(name: 'Chocolate', price: 350, imagePath: 'assets/1c.jpg'),
      ServiceProduct(name: 'Stawberry', price: 60, imagePath: 'assets/2c.jpg'),
      ServiceProduct(
          name: 'Minion Shape', price: 60, imagePath: 'assets/3c.jpg'),
      ServiceProduct(name: 'Berry', price: 60, imagePath: 'assets/4c.jpg'),
      ServiceProduct(name: 'Mango', price: 60, imagePath: 'assets/5c.jpg'),
    ],
    'Cupcakes': [
      ServiceProduct(
          name: 'Chocolate', price: 350, imagePath: 'assets/cupcake.jpg'),
      ServiceProduct(name: 'Creamy', price: 60, imagePath: 'assets/creamy.jpg'),
      ServiceProduct(
          name: 'Mixfruit', price: 60, imagePath: 'assets/mfruit.jpg'),
      ServiceProduct(
          name: 'Redvelvet', price: 60, imagePath: 'assets/red velvet.jpg'),
      ServiceProduct(name: 'Carmel', price: 60, imagePath: 'assets/carmel.jpg'),
      ServiceProduct(name: 'Berry', price: 60, imagePath: 'assets/cherry.jpg'),
    ],
    'Pastries': [
      ServiceProduct(
          name: 'Chocolate', price: 60, imagePath: 'assets/choco.jpg'),
      ServiceProduct(
          name: 'Strawberry', price: 60, imagePath: 'assets/straw.jpg'),
      ServiceProduct(
          name: 'Truffle', price: 60, imagePath: 'assets/trufle.jpg'),
      ServiceProduct(
          name: 'Browniee', price: 60, imagePath: 'assets/browniee.jpg'),
    ],
  },

  // 🔧 MECHANIC
  'Mechanic': {
    'Bike': [
      ServiceProduct(
          name: 'Bike Service', price: 800, imagePath: 'assets/oil.jpg'),
    ],
    'Car': [
      ServiceProduct(
          name: 'Car Service', price: 2500, imagePath: 'assets/tin.jpg'),
    ],
  },

  // 💧 WATER SERVICE
  'Water Service': {
    'Drinking Water': [
      ServiceProduct(
          name: 'Water Can (20L)', price: 50, imagePath: 'assets/can.jpg'),
      ServiceProduct(
          name: 'Water Bottle', price: 10, imagePath: 'assets/bottle.jpg'),
    ],
    'Supply': [
      ServiceProduct(
          name: 'Monthly Supply', price: 1200, imagePath: 'assets/tank.jpg'),
      ServiceProduct(
          name: 'Aqua Guard', price: 1200, imagePath: 'assets/acqua.jpg'),
    ],
  },
};
