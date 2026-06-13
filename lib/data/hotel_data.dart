/// ================= MODEL =================
class HotelData {
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

  // ✅ Per-hotel gallery images for the detail page
  final List<Map<String, String>> images;

  const HotelData({
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
    required this.images,
  });
}

/// ================= HOTEL DATA =================
const List<HotelData> hotels = [

  /// 1 — Kingsland
  HotelData(
    name: "KINGSLAND VIDYA BANQUETS & ROOMS",
    city: "Virar",
    location:
        "Vidya Plaza, 90 Ft Road, near Bank of Baroda, Virar East, Palghar, Maharashtra 401303",
    providerId: "hotel_001",
    image: "assets/kingsland.jpg",
    price: 700,
    originalPrice: 900,
    discount: 20,
    rating: 4.2,
    facilities: [
      "Junior Suites",
      "Deluxe Suites",
      "Family Suites",
      "Executive Suites",
      "Mini Suites",
    ],
    description:
        "KINGSLAND VIDYA BANQUETS & ROOMS is a modern hotel offering comfortable stay, family rooms and convenient amenities.",
    images: [
      {'path': 'assets/kingsland.jpg', 'label': 'Hotel View'},
      {'path': 'assets/kingsland.jpg', 'label': 'Room View'},
      {'path': 'assets/kingsland.jpg', 'label': 'Lobby'},
      {'path': 'assets/kingsland.jpg', 'label': 'Dining'},
    ],
  ),

  /// 2 — Add your second hotel like this:
  // HotelData(
  //   name: "Second Hotel Name",
  //   city: "Virar",
  //   location: "...",
  //   providerId: "hotel_002",
  //   image: "assets/hotel2_cover.jpg",
  //   price: 1200,
  //   originalPrice: 1500,
  //   discount: 20,
  //   rating: 4.5,
  //   facilities: ["Deluxe Rooms", "Conference Hall", "Restaurant"],
  //   description: "...",
  //   images: [
  //     {'path': 'assets/hotel2_front.jpg',  'label': 'Hotel View'},
  //     {'path': 'assets/hotel2_room.jpg',   'label': 'Room View'},
  //     {'path': 'assets/hotel2_lobby.jpg',  'label': 'Lobby'},
  //     {'path': 'assets/hotel2_dining.jpg', 'label': 'Dining'},
  //   ],
  // ),
];

/// ================= HELPERS =================

List<HotelData> getHotelsByCity(String city) {
  return hotels
      .where((h) => h.city.toLowerCase() == city.toLowerCase())
      .toList();
}

List<HotelData> sortByPriceLowHigh(List<HotelData> list) {
  final sorted = [...list];
  sorted.sort((a, b) => a.price.compareTo(b.price));
  return sorted;
}

List<HotelData> sortByRating(List<HotelData> list) {
  final sorted = [...list];
  sorted.sort((a, b) => b.rating.compareTo(a.rating));
  return sorted;
}