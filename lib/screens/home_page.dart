import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:callme/models/service_category.dart';
import 'package:callme/widgets/category_card.dart';
import 'package:callme/profile/notification_page.dart';

import 'package:callme/screens/universal_services_page.dart';
import 'package:callme/screens/salon_page.dart';
import 'package:callme/models/hotel_service_page.dart';
import 'package:callme/models/civil_services_page.dart';
import 'package:callme/screens/resort_page.dart';
import 'package:callme/screens/laundry_service_page.dart';
import 'package:callme/screens/education_services_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  double _offset = 0.0;

  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  final List<ServiceCategory> categories = [
    ServiceCategory(name: 'Education',      imagePath: 'assets/Education.jpg'),
    ServiceCategory(name: 'Salon',          imagePath: 'assets/salon.png'),
    ServiceCategory(name: 'Cleaning',       imagePath: 'assets/cleaning.jpg'),
    ServiceCategory(name: 'Resorts',        imagePath: 'assets/resort.jpg'),
    ServiceCategory(name: 'Plumbing',       imagePath: 'assets/plumbing.jpg'),
    ServiceCategory(name: 'Laundry',        imagePath: 'assets/laundary.jpg'),
    ServiceCategory(name: 'Hotel',          imagePath: 'assets/hotel.jfif'),
    ServiceCategory(name: 'Water',          imagePath: 'assets/water services.jpeg'),
    ServiceCategory(name: 'Civil Services', imagePath: 'assets/civil.jpeg'),
  ];

  String searchQuery = '';
  String selectedCategory = '';

  List<ServiceCategory> get filteredCategories {
    return categories.where((category) {
      final matchesSearch = category.name
          .toLowerCase()
          .contains(searchQuery.toLowerCase().trim());
      final matchesSelected =
          selectedCategory.isEmpty || category.name == selectedCategory;
      return matchesSearch && matchesSelected;
    }).toList();
  }

  List<ServiceCategory> get filteredHorizontal {
    return categories.where((category) {
      return category.name
          .toLowerCase()
          .contains(searchQuery.toLowerCase().trim());
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (mounted) setState(() => _offset = _scrollController.offset);
    });
    Future.delayed(const Duration(milliseconds: 500), autoScroll);
  }

  void autoScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    double next = _scrollController.offset + 120;
    if (next >= max) next = 0;
    _scrollController.animateTo(
      next,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
    );
    Future.delayed(const Duration(seconds: 4), autoScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Fetch the first active salon provider ID from Firestore ──────────────
  Future<String> _fetchSalonProviderId() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('providers')
          .where('serviceType', isEqualTo: 'salon')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) return snap.docs.first.id;
    } catch (_) {}
    return ''; // fallback — SalonBookingPage will show error if still empty
  }

  // ── Navigate to the correct page for each service ────────────────────────
  Future<void> _navigateToService(String serviceName) async {
    Widget page;

    if (serviceName == 'Salon') {
      // Show a loading indicator while fetching provider ID
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final providerId = await _fetchSalonProviderId();

      if (!mounted) return;
      Navigator.pop(context); // dismiss loader

      page = SalonPage(providerId: providerId);
    } else {
      page = _getStaticPage(serviceName);
    }

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  // ── All non-Salon pages (no async needed) ────────────────────────────────
  Widget _getStaticPage(String serviceName) {
    switch (serviceName.trim()) {
      case 'Cleaning':
      case 'Plumbing':
      case 'Water':
        return UniversalServicesPage(serviceName: serviceName);
      case 'Laundry':
        return const LaundryServicePage();
      case 'Resorts':
        return const ResortPage(resorts: []);
      case 'Hotel':
        return const HotelServicePage();
      case 'Civil Services':
        return const CivilServicesPage();
      case 'Education':
        return const EducationServicesPage();
      default:
        return UniversalServicesPage(serviceName: serviceName);
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationPage()),
    );
  }

  Stream<int> get _unreadCountStream {
    if (_uid == null) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: _uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'Callme Services',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(255, 45, 19, 111),
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StreamBuilder<int>(
              stream: _unreadCountStream,
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_rounded, size: 28),
                      onPressed: _openNotifications,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            constraints: const BoxConstraints(
                                minWidth: 18, minHeight: 18),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white, width: 1.5),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [

            // 🔍 SEARCH
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for a service...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  selectedCategory = '';
                });
              },
            ),

            const SizedBox(height: 12),

            // 🔹 HORIZONTAL SCROLL
            SizedBox(
              height: 110,
              child: NotificationListener<ScrollNotification>(
                onNotification: (scroll) {
                  setState(() => _offset = scroll.metrics.pixels);
                  return true;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredHorizontal.length,
                  itemBuilder: (context, index) {
                    final category = filteredHorizontal[index];
                    final isSelected = selectedCategory == category.name;
                    const width = 106.0;
                    final scale = 1 -
                        (((_offset / width) - index).abs() * 0.18)
                            .clamp(0.0, 0.18);

                    return Transform.scale(
                      scale: scale,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          selectedCategory =
                              isSelected ? '' : category.name;
                        }),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6),
                          child: CategoryCard(
                            name: category.name,
                            imagePath: category.imagePath,
                            showName: true,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 🔹 VERTICAL LIST
            Expanded(
              child: ListView.builder(
                itemCount: filteredCategories.length,
                padding: const EdgeInsets.only(bottom: 12),
                itemBuilder: (context, index) {
                  final category = filteredCategories[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GestureDetector(
                      // ✅ FIXED: now calls async method that fetches providerId
                      onTap: () => _navigateToService(category.name),
                      child: CategoryCard(
                        name: category.name,
                        imagePath: category.imagePath,
                        showName: false,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}