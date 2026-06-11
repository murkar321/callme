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
    name: "Anand Resort",
    city: "Virar",
    location:
        "Arnala Beach, Virar West, Palghar, Maharashtra 401303",

    providerId: "resort_001",

    image: "assets/anand.jpeg",

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
        "Anand Resort is a peaceful resort near Arnala Beach offering relaxing stay, family rooms and comfortable amenities.",

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