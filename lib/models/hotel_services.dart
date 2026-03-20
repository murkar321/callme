import 'package:flutter/material.dart';

class HotelServicePage extends StatefulWidget {
  const HotelServicePage({super.key});

  @override
  State<HotelServicePage> createState() => _HotelServicePageState();
}

class _HotelServicePageState extends State<HotelServicePage> {
  String selectedCity = "Virar";
  String selectedCategory = "Rooms";

  final List<String> cities = [
    "Virar",
    "Vasai",
    "Nalasopara",
    "Safale",
    "Palghar"
  ];

  final List<String> categories = [
    "Rooms",
    "Room Service",
    "Housekeeping",
    "Check-In/Out",
  ];

  // 🏨 DUMMY HOTEL DATA
  final List<Map<String, dynamic>> allHotels = [
    {
      "name": "Hotel Sunshine",
      "city": "Virar",
      "category": "Rooms",
      "price": 2000,
      "discount": 1500,
      "rating": 4.5,
      "desc": "Clean rooms with AC"
    },
    {
      "name": "Sea View Resort",
      "city": "Vasai",
      "category": "Rooms",
      "price": 2500,
      "discount": 1800,
      "rating": 4.3,
      "desc": "Beach side hotel"
    },
    {
      "name": "Comfort Stay",
      "city": "Virar",
      "category": "Room Service",
      "price": 300,
      "discount": 200,
      "rating": 4.2,
      "desc": "Quick food delivery"
    },
    {
      "name": "Clean Hotel",
      "city": "Nalasopara",
      "category": "Housekeeping",
      "price": 400,
      "discount": 250,
      "rating": 4.1,
      "desc": "Daily cleaning service"
    },
    {
      "name": "Royal Palace",
      "city": "Palghar",
      "category": "Check-In/Out",
      "price": 500,
      "discount": 300,
      "rating": 4.6,
      "desc": "Flexible check-in"
    },
  ];

  // 🔍 FILTER FUNCTION
  List<Map<String, dynamic>> get filteredHotels {
    return allHotels.where((hotel) {
      final matchCity = hotel["city"]
          .toString()
          .toLowerCase()
          .contains(selectedCity.toLowerCase());

      final matchCategory = hotel["category"] == selectedCategory;

      return matchCity && matchCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 🔍 SEARCH + CITY
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "Enter Your City",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      selectedCity = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: cities.length,
                    itemBuilder: (context, index) {
                      final isSelected = selectedCity == cities[index];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCity = cities[index];
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? Colors.blue : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              cities[index],
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Row(
              children: [
                // 📂 LEFT PANEL
                Container(
                  width: 110,
                  color: Colors.grey.shade100,
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final isSelected = selectedCategory == categories[index];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory = categories[index];
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.shade100
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                                child: Icon(
                                  getIcon(categories[index]),
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                categories[index],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 🏨 RIGHT PANEL
                Expanded(
                  child: filteredHotels.isEmpty
                      ? const Center(child: Text("No hotels found"))
                      : GridView.builder(
                          padding: const EdgeInsets.all(10),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: filteredHotels.length,
                          itemBuilder: (context, index) {
                            final hotel = filteredHotels[index];
                            return hotelCard(hotel);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🏨 HOTEL CARD
  Widget hotelCard(Map<String, dynamic> hotel) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 90,
            decoration: const BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hotel["name"],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 16),
                    Text("${hotel["rating"]}"),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hotel["desc"],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "₹${hotel["price"]}",
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "₹${hotel["discount"]}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Add to cart + booking
                        },
                        child: const Text("Book"),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: Navigate to details
                        },
                        child: const Text("Details"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 ICONS
  IconData getIcon(String category) {
    switch (category) {
      case "Rooms":
        return Icons.hotel;
      case "Room Service":
        return Icons.room_service;
      case "Housekeeping":
        return Icons.cleaning_services;
      case "Check-In/Out":
        return Icons.login;
      default:
        return Icons.category;
    }
  }
}
