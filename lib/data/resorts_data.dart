/// ================= MODEL =================
class Resort {
  final String name;
  final String city;
  final String location;
  final String image;

  final int price;
  final int originalPrice;
  final int discount;

  final double rating;

  final List<String> facilities;
  final String description;

  final String providerId;

  const Resort({
    required this.name,
    required this.city,
    required this.location,
    required this.image,
    required this.price,
    required this.originalPrice,
    required this.discount,
    required this.rating,
    required this.facilities,
    required this.description,
    required this.providerId,
  });
}

/// ================= ONLY VIRAR CITY =================
const List<String> cities = [
  "Virar",
];

/// ================= RESORT DATA =================
const List<Resort> resortList = [

  /// 1
  Resort(
    name: "Arnala Beach Resort",
    city: "Virar",
    location:
        "Arnala Beach, Virar West, Palghar, Maharashtra 401303",

    providerId: "resort_001",

    image: "assets/resort.jpg",

    price: 700,
    originalPrice: 900,
    discount: 20,

    rating: 4.2,

    facilities: [
      "Swimming Pool",
      "A/C Rooms",
      "Family Rooms",
      "Parking Facility",
    ],

    description:
        "Arnala Beach Resort is a peaceful resort near Arnala Beach offering relaxing stay, family rooms and comfortable amenities.",

  ),

  /// 2
  Resort(
    name: "Calamansi Cove Resort",
    city: "Virar",
    location:
        "Navapur, Virar West, Palghar, Maharashtra 401303",

    providerId: "resort_002",

    image: "assets/resort.jpg",

    price: 700,
    originalPrice: 900,
    discount: 20,

    rating: 4.1,

    facilities: [
      "Swimming Pool",
      "Restaurant",
      "Garden Area",
      "Free WiFi",
    ],

    description:
        "Calamansi Cove Resort provides a calm environment with modern rooms and relaxing atmosphere for families and couples.",
  ),

  /// 3
  Resort(
    name: "Rajodi Beach Resort",
    city: "Virar",
    location:
        "Rajodi Beach, Virar West, Palghar, Maharashtra 401303",

    providerId: "resort_003",

    image: "assets/resort.jpg",

    price: 700,
    originalPrice: 900,
    discount: 20,

    rating: 4.0,

    facilities: [
      "Beach Access",
      "A/C Rooms",
      "Restaurant",
      "Parking Facility",
    ],

    description:
        "Rajodi Beach Resort offers beachside stay experience with spacious rooms and family-friendly atmosphere.",
  ),

  /// 4
  Resort(
    name: "Visava Beach Resort",
    city: "Virar",
    location:
        "Arnala Beach Road, Virar West, Palghar, Maharashtra 401303",

    providerId: "resort_004",

    image: "assets/resort.jpg",

    price: 700,
    originalPrice: 900,
    discount: 20,

    rating: 4.3,

    facilities: [
      "Swimming Pool",
      "Sea View",
      "Restaurant",
      "Party Area",
    ],

    description:
        "Visava Beach Resort is known for beachside ambience, swimming pool and relaxing weekend stay.",
  ),

  /// 5
  Resort(
    name: "Patil Resort",
    city: "Virar",
    location:
        "Arnala West, Virar, Palghar, Maharashtra 401303",

    providerId: "resort_005",

    image: "assets/resort.jpg",

    price: 700,
    originalPrice: 900,
    discount: 20,

    rating: 3.9,

    facilities: [
      "Garden Area",
      "A/C Rooms",
      "Restaurant",
      "Parking Facility",
    ],

    description:
        "Patil Resort provides peaceful stay with garden area and comfortable rooms for families and groups.",
  ),

  /// 6
  Resort(
    name: "Anand Resort",
    city: "Virar",
    location:
        "Arnala Beach, Virar West, Palghar, Maharashtra 401303",

    providerId: "resort_006",

    image: "assets/resort.jpg",

    price: 700,
    originalPrice: 900,
    discount: 20,

    rating: 4.1,

    facilities: [
      "Swimming Pool",
      "Bar Facility",
      "Family Rooms",
      "Parking",
    ],

    description:
        "Anand Resort offers comfortable stay with pool access and relaxing atmosphere near Arnala Beach.",
  ),

  /// 7
  Resort(
    name: "Oceanic Beach Resort",
    city: "Virar",
    location:
        "Navapur Beach Road, Virar West, Maharashtra 401303",

    providerId: "resort_007",

    image: "assets/resort.jpg",

    price: 700,
    originalPrice: 900,
    discount: 20,

    rating: 4.4,

    facilities: [
      "Beach Access",
      "Swimming Pool",
      "Restaurant",
      "Free WiFi",
    ],

    description:
        "Oceanic Beach Resort provides beautiful beachside experience with pool and modern amenities.",
  ),

  /// 8
  Resort(
    name: "Green Paradise Resort",
    city: "Virar",
    location:
        "Arnala, Virar West, Palghar, Maharashtra 401303",

    providerId: "resort_008",

    image: "assets/resort.jpg",

    price: 700,
    originalPrice: 900,
    discount: 20,

    rating: 4.0,

    facilities: [
      "Garden Area",
      "Family Rooms",
      "Restaurant",
      "Parking",
    ],

    description:
        "Green Paradise Resort offers greenery, peaceful atmosphere and comfortable stay for visitors.",
  ),

  /// 9
  Resort(
    name: "Seaside Water Park Resort",
    city: "Virar",
    location:
        "Arnala Beach, Virar West, Maharashtra 401303",

    providerId: "resort_009",

    image: "assets/resort.jpg",

    price: 700,
    originalPrice: 900,
    discount: 20,

    rating: 4.5,

    facilities: [
      "Water Park",
      "Swimming Pool",
      "Restaurant",
      "Locker Facility",
    ],

    description:
        "Seaside Water Park Resort is ideal for family outings with water rides and relaxing stay facilities.",
  ),

  /// 10
  Resort(
    name: "Swapna Nagari Resort",
    city: "Virar",
    location:
        "Virar East, Palghar, Maharashtra 401305",

    providerId: "resort_010",

    image: "assets/resort.jpg",

    price: 700,
    originalPrice: 900,
    discount: 20,

    rating: 3.8,

    facilities: [
      "A/C Rooms",
      "Restaurant",
      "Parking",
      "Family Stay",
    ],

    description:
        "Swapna Nagari Resort provides affordable stay with family-friendly environment and peaceful surroundings.",
  ),

  /// 11
  Resort(
    name: "Palash Resort",
    city: "Virar",
    location:
        "Agashi, Virar West, Palghar, Maharashtra 401301",

    providerId: "resort_011",

    image: "assets/resort.jpg",

    price: 700,
    originalPrice: 900,
    discount: 20,

    rating: 4.1,

    facilities: [
      "Swimming Pool",
      "Restaurant",
      "Party Area",
      "Parking",
    ],

    description:
        "Palash Resort offers comfortable rooms and peaceful environment suitable for family vacations.",
  ),

  /// 12
  Resort(
    name: "Sai Resort",
    city: "Virar",
    location:
        "Navapur Beach, Virar West, Maharashtra 401303",

    providerId: "resort_012",

    image: "assets/resort.jpg",

    price: 700,
    originalPrice: 900,
    discount: 20,

    rating: 4.0,

    facilities: [
      "Beach Access",
      "Restaurant",
      "Family Rooms",
      "Parking",
    ],

    description:
        "Sai Resort provides relaxing beachside stay with spacious rooms and good dining services.",
  ),

  /// 13
  Resort(
    name: "Blue Wave Resort",
    city: "Virar",
    location:
        "Arnala Beach, Virar West, Palghar, Maharashtra 401303",

    providerId: "resort_013",

    image: "assets/resort.jpg",

    price: 700,
    originalPrice: 900,
    discount: 20,

    rating: 4.4,

    facilities: [
      "Sea View",
      "Swimming Pool",
      "Restaurant",
      "Parking",
    ],

    description:
        "Blue Wave Resort offers modern rooms and beautiful beachside ambience for peaceful vacations.",
  ),

  /// 14
  Resort(
    name: "Coconut Grove Resort",
    city: "Virar",
    location:
        "Rajodi Beach, Virar West, Maharashtra 401303",

    providerId: "resort_014",

    image: "assets/resort.jpg",

    price: 700,
    originalPrice: 900,
    discount: 20,

    rating: 4.2,

    facilities: [
      "Garden Area",
      "Beach Access",
      "Restaurant",
      "Free WiFi",
    ],

    description:
        "Coconut Grove Resort is known for relaxing atmosphere, greenery and beach access.",
  ),

  /// 15
  Resort(
    name: "Golden Quarter Resort",
    city: "Virar",
    location:
        "Virar West, Palghar, Maharashtra 401303",

    providerId: "resort_015",

    image: "assets/resort.jpg",

    price: 700,
    originalPrice: 900,
    discount: 20,

    rating: 3.9,

    facilities: [
      "Family Rooms",
      "Parking",
      "Restaurant",
      "Party Area",
    ],

    description:
        "Golden Quarter Resort offers affordable stay with family facilities and spacious rooms.",
  ),

  /// 16
  Resort(
    name: "Rudanti Resort",
    city: "Virar",
    location:
        "Arnala Bypass Road, Virar West, Maharashtra 401303",

    providerId: "resort_016",

    image: "assets/resort.jpg",

    price: 700,
    originalPrice: 900,
    discount: 20,

    rating: 4.0,

    facilities: [
      "Swimming Pool",
      "Restaurant",
      "Parking",
      "Family Rooms",
    ],

    description:
        "Rudanti Resort offers comfortable stay and modern facilities for family and group outings.",
  ),

  /// 17
  Resort(
    name: "Surya Resort",
    city: "Virar",
    location:
        "Navapur, Virar West, Palghar, Maharashtra 401303",

    providerId: "resort_017",

    image: "assets/resort.jpg",

    price: 700,
    originalPrice: 900,
    discount: 20,

    rating: 4.1,

    facilities: [
      "Swimming Pool",
      "Restaurant",
      "Garden Area",
      "Parking",
    ],

    description:
        "Surya Resort provides peaceful ambience with pool and relaxing stay experience.",
  ),

  /// 18
  Resort(
    name: "Sun Beach Resort Virar",
    city: "Virar",
    location:
        "Pachtalab, Virar West, Maharashtra 401303",

    providerId: "resort_018",

    image: "assets/resort.jpg",

    price: 700,
    originalPrice: 900,
    discount: 20,

    rating: 4.3,

    facilities: [
      "Beach Access",
      "Sea View",
      "Restaurant",
      "Parking",
    ],

    description:
        "Sun Beach Resort Virar offers beachside stay with beautiful views and comfortable rooms.",
  ),

  /// 19
  Resort(
    name: "Hill View Resort",
    city: "Virar",
    location:
        "Mandvi, Virar East, Palghar, Maharashtra 401305",

    providerId: "resort_019",

    image: "assets/resort.jpg",

    price: 700,
    originalPrice: 900,
    discount: 20,

    rating: 4.0,

    facilities: [
      "Hill View",
      "Family Rooms",
      "Restaurant",
      "Parking",
    ],

    description:
        "Hill View Resort offers peaceful hill surroundings and comfortable stay experience.",
  ),

  /// 20
  Resort(
    name: "Royal Resort",
    city: "Virar",
    location:
        "Arnala Beach, Virar West, Palghar, Maharashtra 401303",

    providerId: "resort_020",

    image: "assets/resort.jpg",

    price: 700,
    originalPrice: 900,
    discount: 20,

    rating: 4.4,

    facilities: [
      "Swimming Pool",
      "Luxury Rooms",
      "Restaurant",
      "Parking",
    ],

    description:
        "Royal Resort provides premium stay experience near Arnala Beach with modern amenities and spacious rooms.",
  ),
];

/// ================= HELPERS =================

List<Resort> getResortsByCity(String city) {
  return resortList
      .where(
        (resort) =>
            resort.city.toLowerCase() ==
            city.toLowerCase(),
      )
      .toList();
}

/// ================= SORT HELPERS =================

List<Resort> sortByPriceLowHigh(List<Resort> list) {
  final sorted = [...list];

  sorted.sort(
    (a, b) => a.price.compareTo(b.price),
  );

  return sorted;
}

List<Resort> sortByRating(List<Resort> list) {
  final sorted = [...list];

  sorted.sort(
    (a, b) => b.rating.compareTo(a.rating),
  );

  return sorted;
}