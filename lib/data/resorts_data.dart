
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

/// ================= CITY LIST =================
const List<String> cities = [
  "Virar",
  "Lonavala",
  "Goa",
  "Thane",
];

/// ================= RESORT DATA =================
const List<Resort> resortList = [

  /// ================= VIRAR =================
  Resort(
    name: "Rajhans Water Park",
    city: "Virar",
    location: "Virar, Mumbai",
    providerId: "resort_001",
    image: "assets/rajhans.jfif",
    price: 600,
    originalPrice: 700,
    discount: 10,
    rating: 3.5,
    facilities: [
      "Water Park Access",
      "Lockers Available",
      "A/C & Non A/C Rooms",
      "Bar Facility",
    ],
    description:
        "Rajhans Water Park is a popular resort in Virar. It is a great place to enjoy water rides, swimming, and relaxing rooms with family and friends.",
  ),

  Resort(
    name: "Sagar Resort",
    city: "Virar",
    location: "Virar East",
    providerId: "resort_002",
    image: "assets/sagar.jfif",
    price: 600,
    originalPrice: 700,
    discount: 10,
    rating: 3.8,
    facilities: [
      "Lockers Available",
      "A/C & Non A/C Rooms",
      "Bar Facility",
      "Garden Area",
    ],
    description:
        "Sagar Resort in Virar offers a peaceful and relaxing environment. It is a good place for weekend outings and family trips.",
  ),

  /// ================= LONAVALA =================
  Resort(
    name: "Hill View Resort",
    city: "Lonavala",
    location: "Lonavala Hills",
    providerId: "resort_003",
    image: "assets/hillview.jfif",
    price: 800,
    originalPrice: 900,
    discount: 12,
    rating: 4.2,
    facilities: [
      "Swimming Pool",
      "A/C & Non A/C Rooms",
      "Restaurant",
      "Hill View",
    ],
    description:
        "Hill View Resort in Lonavala provides a beautiful view of the hills and peaceful nature stay.",
  ),

  Resort(
    name: "Green Valley Resort",
    city: "Lonavala",
    location: "Green Valley Area",
    providerId: "resort_004",
    image: "assets/green valley.jfif",
    price: 850,
    originalPrice: 950,
    discount: 10,
    rating: 4.0,
    facilities: [
      "Swimming Pool",
      "Garden View",
      "Restaurant",
      "Parking Facility",
    ],
    description:
        "Green Valley Resort is known for greenery and peaceful atmosphere. Suitable for couples and families.",
  ),

  /// ================= GOA =================
  Resort(
    name: "Beach Side Resort",
    city: "Goa",
    location: "Near Baga Beach",
    providerId: "resort_005",
    image: "assets/beachside.jfif",
    price: 900,
    originalPrice: 1000,
    discount: 15,
    rating: 4.3,
    facilities: [
      "Sea View Rooms",
      "A/C & Non A/C Rooms",
      "Bar Facility",
      "Beach Access",
    ],
    description:
        "Beach Side Resort in Goa is located near the beach with sea view rooms and relaxing environment.",
  ),

  Resort(
    name: "Ocean Paradise Resort",
    city: "Goa",
    location: "Calangute Beach",
    providerId: "resort_006",
    image: "assets/ocean.jfif",
    price: 1200,
    originalPrice: 1400,
    discount: 15,
    rating: 4.8,
    facilities: [
      "Sea View Rooms",
      "Swimming Pool",
      "Bar Facility",
      "Luxury Rooms",
    ],
    description:
        "Ocean Paradise Resort provides luxury stay experience with premium rooms and sea views.",
  ),

  /// ================= THANE =================
  Resort(
    name: "Lake View Resort",
    city: "Thane",
    location: "Upvan Lake Area",
    providerId: "resort_007",
    image: "assets/lakeview.jfif",
    price: 700,
    originalPrice: 800,
    discount: 10,
    rating: 3.6,
    facilities: [
      "Lake View",
      "A/C & Non A/C Rooms",
      "Restaurant",
      "Garden Area",
    ],
    description:
        "Lake View Resort in Thane offers peaceful environment and beautiful lake view.",
  ),

  Resort(
    name: "Paradise Resort",
    city: "Thane",
    location: "Ghodbunder Road",
    providerId: "resort_008",
    image: "assets/paradise.jfif",
    price: 750,
    originalPrice: 850,
    discount: 12,
    rating: 3.9,
    facilities: [
      "Swimming Pool",
      "A/C Rooms",
      "Restaurant",
      "Party Area",
    ],
    description:
        "Paradise Resort offers comfortable rooms, swimming pool and dining facilities for family outings.",
  ),
];

/// ================= HELPERS =================

List<Resort> getResortsByCity(String city) {
  return resortList
      .where((resort) => resort.city.toLowerCase() == city.toLowerCase())
      .toList();
}

/// 🔥 BONUS: Sort helpers (optional)

List<Resort> sortByPriceLowHigh(List<Resort> list) {
  final sorted = [...list];
  sorted.sort((a, b) => a.price.compareTo(b.price));
  return sorted;
}

List<Resort> sortByRating(List<Resort> list) {
  final sorted = [...list];
  sorted.sort((a, b) => b.rating.compareTo(a.rating));
  return sorted;
}