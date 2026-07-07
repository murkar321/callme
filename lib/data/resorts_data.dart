import 'package:flutter/material.dart';

/// ================= SUPPORTING MODELS =================

class HighlightItem {
  final IconData icon;
  final String label;
  final String sub;
  const HighlightItem({
    required this.icon,
    required this.label,
    required this.sub,
  });
}

class TimingItem {
  final IconData icon;
  final String label;
  final String value;
  const TimingItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

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

  final List<Map<String, String>> images;

  // ✅ NEW — makes every resort's detail page genuinely distinct
  final String tagline;
  final String distanceInfo;
  final List<HighlightItem> highlights;
  final List<String> inclusions;
  final List<TimingItem> timings;
  final List<String> rules;

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
    required this.images,
    required this.tagline,
    required this.distanceInfo,
    required this.highlights,
    required this.inclusions,
    required this.timings,
    required this.rules,
  });
}

/// ================= RESORT DATA =================
const List<Resort> resorts = [

  /// 1 — Anand Resort (waterpark / day-outing resort near Arnala Beach)
  Resort(
    name: "Anand Resort",
    city: "Virar",
    location: "Arnala Beach, Virar West, Palghar, Maharashtra 401303",
    providerId: "resort_001",
    image: "assets/anand.jpeg",
    price: 600,
    originalPrice: 900,
    discount: 33,
    rating: 4.2,
    tagline: "Waterpark & Day-Outing Resort near Arnala Beach",
    distanceInfo: "~8 km from Virar Railway Station • Free pickup available",
    facilities: [
      "Water Park",
      "Swimming Pool",
      "Natural Waterfall",
      "Rain Dance / DJ Floor",
      "Conference Hall (300 capacity)",
      "Free Parking",
    ],
    description:
        "Anand Resort is known for its lively waterpark set amid coconut palms and banana plantations near Arnala Beach. With thrilling slides, a wave pool, a natural waterfall and a DJ rain-dance floor, it's a popular pick for day outings, group picnics and family weekend getaways — with buffet lunch included and free pickup from Virar station.",
    images: [
      {'path': 'assets/waterpark.jpeg', 'label': 'Water Park'},
      {'path': 'assets/rpool.jpeg', 'label': 'Resort Pool'},
      {'path': 'assets/lunch.jpeg', 'label': 'Lunch'},
      {'path': 'assets/raindance.jpeg', 'label': 'Rain Dance'},
    ],
    highlights: [
      HighlightItem(icon: Icons.waves, label: "Water Park", sub: "Slides & wave pool"),
      HighlightItem(icon: Icons.water, label: "Natural Waterfall", sub: "Scenic cascade"),
      HighlightItem(icon: Icons.music_note, label: "Rain Dance", sub: "DJ floor"),
      HighlightItem(icon: Icons.child_friendly, label: "Tot Pool", sub: "Kids' play area"),
      HighlightItem(icon: Icons.camera_alt, label: "3D Selfie Point", sub: "Photo zone"),
      HighlightItem(icon: Icons.park, label: "Green Lawns", sub: "Palm & banana groves"),
    ],
    inclusions: [
      "Unlimited waterpark & pool access all day",
      "Buffet lunch (veg & non-veg)",
      "Rain dance session with DJ",
      "Free parking for two- & four-wheelers",
      "Free pickup from Virar station",
      "Locker & changing room access",
    ],
    timings: [
      TimingItem(icon: Icons.login, label: "Check-in", value: "10:00 AM"),
      TimingItem(icon: Icons.restaurant, label: "Lunch", value: "12:30 PM – 3:00 PM"),
      TimingItem(icon: Icons.waves, label: "Water Park", value: "10:00 AM – 5:30 PM"),
      TimingItem(icon: Icons.music_note, label: "Rain Dance", value: "2:00 PM – 4:00 PM"),
    ],
    rules: [
      "Swimwear is mandatory for pool & waterpark areas",
      "Outside food & beverages are not allowed",
      "Children below 3 ft entry is free",
      "Photography permitted at select zones only",
      "Resort management reserves the right of admission",
    ],
  ),

  /// 2 — Alexon Resort (stay & banquet resort near Arnala Beach)
  Resort(
    name: "Alexon Resort",
    city: "Virar",
    location: "Lopes Wadi, Near Arnala Beach, Virar West, Palghar, Maharashtra 401302",
    providerId: "resort_002",
    image: "assets/alexon.jpg",
    price: 600,
    originalPrice: 900,
    discount: 33,
    rating: 4.1,
    tagline: "Stay & Banquet Resort near Arnala Beach",
    distanceInfo: "~2 mins walk from Arnala Beach",
    facilities: [
      "Swimming Pool",
      "Banquet / Wedding Hall",
      "Multi-Cuisine Restaurant & Bar",
      "Fitness Center",
      "A/C Rooms",
      "Free Parking",
    ],
    description:
        "Alexon Resort is a stay-and-banquet property just steps from Arnala Beach, offering 28 well-appointed rooms, a large wedding/banquet lawn that can host up to 900 guests, and a multi-cuisine restaurant with bar. It's best suited for overnight stays, weddings, receptions and group functions.",
    images: [
      {'path': 'assets/alexonr.jpg', 'label': 'Resort View'},
      {'path': 'assets/alxhalls.jpg', 'label': 'Hall View'},
      {'path': 'assets/alwater.jpg', 'label': 'Water Park'},
      {'path': 'assets/alxroom.jpg', 'label': 'Rooms'},
      {'path': 'assets/alexon.jpg', 'label': 'Resort View'},
      {'path': 'assets/alxhall.jpg', 'label': 'Wedding Hall'},
    ],
    highlights: [
      HighlightItem(icon: Icons.pool, label: "Swimming Pool", sub: "Outdoor pool"),
      HighlightItem(icon: Icons.celebration, label: "Banquet Hall", sub: "Up to 900 guests"),
      HighlightItem(icon: Icons.restaurant, label: "Multi-Cuisine", sub: "Restaurant & bar"),
      HighlightItem(icon: Icons.fitness_center, label: "Fitness Center", sub: "Onsite gym"),
      HighlightItem(icon: Icons.beach_access, label: "Beachside", sub: "Near Arnala Beach"),
      HighlightItem(icon: Icons.king_bed, label: "Spacious Rooms", sub: "28 rooms & suites"),
    ],
    inclusions: [
      "Overnight stay in A/C rooms",
      "Multi-cuisine buffet dining",
      "Access to swimming pool & lawns",
      "Free parking",
      "Use of banquet lawns for group bookings",
      "24-hour room service",
    ],
    timings: [
      TimingItem(icon: Icons.login, label: "Check-in", value: "10:00 AM"),
      TimingItem(icon: Icons.logout, label: "Check-out", value: "12:00 PM"),
      TimingItem(icon: Icons.restaurant, label: "Dining", value: "All-day multi-cuisine"),
      TimingItem(icon: Icons.pool, label: "Pool Access", value: "Daytime"),
    ],
    rules: [
      "Valid ID proof required at check-in",
      "Pets are not allowed",
      "Children below 13 years stay free",
      "Cash or card payments accepted",
      "Resort management reserves the right of admission",
    ],
  ),
];

/// ================= HELPERS =================

List<Resort> getResortsByCity(String city) {
  return resorts
      .where((r) => r.city.toLowerCase() == city.toLowerCase())
      .toList();
}

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