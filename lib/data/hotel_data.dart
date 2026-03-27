class HotelRoom {
  final String id;
  final String category;
  final String hotelName;
  final String city;
  final String address;
  final int price;
  final int discount;
  final String tagline;
  final String image;

  final List<String> features;
  final List<String> facilities;
  final String suitableFor;
  final String description;

  HotelRoom({
    required this.id,
    required this.category,
    required this.hotelName,
    required this.city,
    required this.address,
    required this.price,
    required this.discount,
    required this.tagline,
    required this.image,
    required this.features,
    required this.facilities,
    required this.suitableFor,
    required this.description,
  });
}

/// MAIN HOTEL DATA
List<HotelRoom> hotels = [
  HotelRoom(
    category: "Junior Suite",
    hotelName: "Palm Residency",
    city: "Mumbai",
    image: "assets/ocean.jfif",
    address: "Linking Road, Khar West, Mumbai, Maharashtra 400052",
    price: 2500,
    discount: 10,
    tagline: "Compact Luxury with Comfort",
    features: [
      "Queen Size Bed",
      "Air Conditioning",
      "Free Wi-Fi",
      "Smart TV",
      "Work Desk",
    ],
    facilities: [
      "24/7 Room Service",
      "Daily Housekeeping",
      "Free Parking",
    ],
    suitableFor: "Couples and Solo Travelers",
    description:
        "A cozy and modern room designed for comfort with all essential amenities for a relaxing stay.",
    id: '1',
  ),
  HotelRoom(
    category: "Executive Suite",
    hotelName: "Palm Residency",
    city: "Pune",
    image: "assets/hillview.jfif",
    address: "Linking Road, Khar West, Mumbai, Maharashtra 400052",
    price: 4000,
    discount: 15,
    tagline: "Work Smart, Stay Smart",
    features: [
      "King Size Bed",
      "Dedicated Workspace",
      "High-Speed Wi-Fi",
      "Mini Bar",
      "City View",
    ],
    facilities: [
      "Business Support Services",
      "24/7 Room Service",
      "Laundry Service",
    ],
    suitableFor: "Business Travelers",
    description:
        "Spacious suite with premium workspace and modern facilities, perfect for work and relaxation.",
    id: '2',
  ),
  HotelRoom(
    category: "Family Suite",
    hotelName: "Palm Residency",
    city: "Goa",
    image: "assets/beachside.jfif",
    address: "Linking Road, Khar West, Mumbai, Maharashtra 400052",
    price: 6000,
    discount: 20,
    tagline: "Where Family Feels at Home",
    features: [
      "2 Double Beds",
      "Large Living Area",
      "Kids Friendly Space",
      "Free Wi-Fi",
      "Storage Space",
    ],
    facilities: [
      "Free Breakfast",
      "Housekeeping",
      "Extra Bed Available",
    ],
    suitableFor: "Families and Groups",
    description:
        "A spacious suite designed for families with comfort, space, and convenience.",
    id: '3',
  ),
  HotelRoom(
    category: "Deluxe Suite",
    hotelName: "Palm Residency",
    city: "Delhi",
    image: "assets/rajhans.jfif",
    address: "Linking Road, Khar West, Mumbai, Maharashtra 400052",
    price: 7500,
    discount: 25,
    tagline: "Luxury Redefined",
    features: [
      "King Size Bed",
      "Jacuzzi / Bathtub",
      "Premium Interiors",
      "Balcony View",
      "Smart TV",
    ],
    facilities: [
      "24/7 Room Service",
      "Private Dining Option",
      "Laundry Service",
    ],
    suitableFor: "Luxury Stay",
    description:
        "Experience premium luxury with elegant interiors and top-class amenities.",
    id: '4',
  ),
  HotelRoom(
    category: "Mini Suite",
    hotelName: "Palm Residency",
    city: "Banglore",
    image: "assets/lakeview.jfif",
    address: "Linking Road, Khar West, Mumbai, Maharashtra 400052",
    price: 1800,
    discount: 5,
    tagline: "Affordable Comfort for Everyone",
    features: [
      "Double Bed",
      "Air Conditioning",
      "Free Wi-Fi",
      "TV",
      "Basic Amenities",
    ],
    facilities: [
      "Room Service",
      "Housekeeping",
    ],
    suitableFor: "Budget Travelers",
    description:
        "A simple and affordable room with all basic facilities for a comfortable stay.",
    id: '5',
  ),
  HotelRoom(
    category: "Junior Suite",
    hotelName: "Palm Residency",
    city: "Goa",
    image: "assets/ocean.jfif",
    address: "Linking Road, Khar West, Mumbai, Maharashtra 400052",
    price: 2500,
    discount: 10,
    tagline: "Compact Luxury with Comfort",
    features: [
      "Queen Size Bed",
      "Air Conditioning",
      "Free Wi-Fi",
      "Smart TV",
      "Work Desk",
    ],
    facilities: [
      "24/7 Room Service",
      "Daily Housekeeping",
      "Free Parking",
    ],
    suitableFor: "Couples and Solo Travelers",
    description:
        "A cozy and modern room designed for comfort with all essential amenities for a relaxing stay.",
    id: '1',
  ),
  HotelRoom(
    category: "Executive Suite",
    hotelName: "Palm Residency",
    city: "Mumbai",
    image: "assets/hillview.jfif",
    address: "Linking Road, Khar West, Mumbai, Maharashtra 400052",
    price: 4000,
    discount: 15,
    tagline: "Work Smart, Stay Smart",
    features: [
      "King Size Bed",
      "Dedicated Workspace",
      "High-Speed Wi-Fi",
      "Mini Bar",
      "City View",
    ],
    facilities: [
      "Business Support Services",
      "24/7 Room Service",
      "Laundry Service",
    ],
    suitableFor: "Business Travelers",
    description:
        "Spacious suite with premium workspace and modern facilities, perfect for work and relaxation.",
    id: '2',
  ),
  HotelRoom(
    category: "Family Suite",
    hotelName: "Palm Residency",
    city: "Banglore",
    image: "assets/beachside.jfif",
    address: "Linking Road, Khar West, Mumbai, Maharashtra 400052",
    price: 6000,
    discount: 20,
    tagline: "Where Family Feels at Home",
    features: [
      "2 Double Beds",
      "Large Living Area",
      "Kids Friendly Space",
      "Free Wi-Fi",
      "Storage Space",
    ],
    facilities: [
      "Free Breakfast",
      "Housekeeping",
      "Extra Bed Available",
    ],
    suitableFor: "Families and Groups",
    description:
        "A spacious suite designed for families with comfort, space, and convenience.",
    id: '3',
  ),
  HotelRoom(
    category: "Deluxe Suite",
    hotelName: "Palm Residency",
    city: "Pune",
    image: "assets/rajhans.jfif",
    address: "Linking Road, Khar West, Mumbai, Maharashtra 400052",
    price: 7500,
    discount: 25,
    tagline: "Luxury Redefined",
    features: [
      "King Size Bed",
      "Jacuzzi / Bathtub",
      "Premium Interiors",
      "Balcony View",
      "Smart TV",
    ],
    facilities: [
      "24/7 Room Service",
      "Private Dining Option",
      "Laundry Service",
    ],
    suitableFor: "Luxury Stay",
    description:
        "Experience premium luxury with elegant interiors and top-class amenities.",
    id: '4',
  ),
  HotelRoom(
    category: "Mini Suite",
    hotelName: "Palm Residency",
    city: "Delhi",
    image: "assets/lakeview.jfif",
    address: "Linking Road, Khar West, Mumbai, Maharashtra 400052",
    price: 1800,
    discount: 5,
    tagline: "Affordable Comfort for Everyone",
    features: [
      "Double Bed",
      "Air Conditioning",
      "Free Wi-Fi",
      "TV",
      "Basic Amenities",
    ],
    facilities: [
      "Room Service",
      "Housekeeping",
    ],
    suitableFor: "Budget Travelers",
    description:
        "A simple and affordable room with all basic facilities for a comfortable stay.",
    id: '5',
  ),
];

/// FILTER BY CATEGORY + CITY
List<HotelRoom> filterHotels({
  required String category,
  required String city,
}) {
  return hotels.where((hotel) {
    return hotel.category == category && hotel.city == city;
  }).toList();
}

/// OPTIONAL: FILTER ONLY BY CITY
List<HotelRoom> getByCity(String city) {
  return hotels.where((hotel) => hotel.city == city).toList();
}

/// OPTIONAL: FILTER ONLY BY CATEGORY
List<HotelRoom> getByCategory(String category) {
  return hotels.where((hotel) => hotel.category == category).toList();
}
