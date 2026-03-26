class Resort {
  final String name;
  final String city;
  final String image;
  final int price;
  final int originalPrice;
  final int discount;
  final int rating;
  final List<String> facilities;
  final String description;

  Resort({
    required this.name,
    required this.city,
    required this.image,
    required this.price,
    required this.originalPrice,
    required this.discount,
    required this.rating,
    required this.facilities,
    required this.description,
  });
}

List<String> cities = [
  "Virar",
  "Lonavala",
  "Goa",
  "Thane",
];

List<Resort> resortList = [

  // VIRAR
  Resort(
    name: "Rajhans Water Park",
    city: "Virar",
    image: "assets/rajhans.jfif",
    price: 600,
    originalPrice: 700,
    discount: 10,
    rating: 3,
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
    image: "assets/sagar.jfif",
    price: 600,
    originalPrice: 700,
    discount: 10,
    rating: 3,
    facilities: [
      "Lockers Available",
      "A/C & Non A/C Rooms",
      "Bar Facility",
      "Garden Area",
    ],
    description:
        "Sagar Resort in Virar offers a peaceful and relaxing environment. It is a good place for weekend outings and family trips.",
  ),

  // LONAVALA
  Resort(
    name: "Hill View Resort",
    city: "Lonavala",
    image: "assets/hillview.jfif",
    price: 800,
    originalPrice: 900,
    discount: 12,
    rating: 4,
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
    image: "assets/greenvalley.jfif",
    price: 850,
    originalPrice: 950,
    discount: 10,
    rating: 4,
    facilities: [
      "Swimming Pool",
      "Garden View",
      "Restaurant",
      "Parking Facility",
    ],
    description:
        "Green Valley Resort is known for greenery and peaceful atmosphere. Suitable for couples and families.",
  ),

  // GOA
  Resort(
    name: "Beach Side Resort",
    city: "Goa",
    image: "assets/beachside.jfif",
    price: 900,
    originalPrice: 1000,
    discount: 15,
    rating: 4,
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
    image: "assets/ocean.jfif",
    price: 1200,
    originalPrice: 1400,
    discount: 15,
    rating: 5,
    facilities: [
      "Sea View Rooms",
      "Swimming Pool",
      "Bar Facility",
      "Luxury Rooms",
    ],
    description:
        "Ocean Paradise Resort provides luxury stay experience with premium rooms and sea views.",
  ),

  // THANE
  Resort(
    name: "Lake View Resort",
    city: "Thane",
    image: "assets/lakeview.jfif",
    price: 700,
    originalPrice: 800,
    discount: 10,
    rating: 3,
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
    image: "assets/paradise.jfif",
    price: 750,
    originalPrice: 850,
    discount: 12,
    rating: 3,
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



List<Resort> getResortsByCity(String city) {
  return resortList.where((resort) => resort.city == city).toList();
}