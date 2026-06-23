import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:callme/provider/service_provider_form.dart';
import 'package:callme/provider/provider_dashboard.dart';

// =====================================================
// CATEGORY MODEL
// =====================================================

class ServiceCategoryStyle {
  final String name;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const ServiceCategoryStyle({
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

// =====================================================
// BUSINESS PAGE
// =====================================================

class BusinessPage extends StatefulWidget {
  const BusinessPage({super.key});

  @override
  State<BusinessPage> createState() => _BusinessPageState();
}

class _BusinessPageState extends State<BusinessPage>
    with TickerProviderStateMixin {

  // ── Firebase ──────────────────────────────────────
  User? get user => FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  // ── Location ──────────────────────────────────────
  String city = "";
  bool loadingLocation = true;

  // ── Stagger animation ─────────────────────────────
  late AnimationController _listController;
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  // ── Categories ────────────────────────────────────
  static const List<ServiceCategoryStyle> businessCategories = [
    ServiceCategoryStyle(
      name: 'Salon',
      icon: Icons.content_cut_rounded,
      iconColor: Color(0xFFE91E8C),
      iconBg: Color(0xFFFCE4F1),
    ),
    ServiceCategoryStyle(
      name: 'Educational Services',
      icon: Icons.menu_book_rounded,
      iconColor: Color(0xFF5C6BC0),
      iconBg: Color(0xFFE8EAF6),
    ),
    ServiceCategoryStyle(
      name: 'Cleaning',
      icon: Icons.cleaning_services_rounded,
      iconColor: Color(0xFF00897B),
      iconBg: Color(0xFFE0F2F1),
    ),
    ServiceCategoryStyle(
      name: 'Plumbing',
      icon: Icons.plumbing_rounded,
      iconColor: Color(0xFF0288D1),
      iconBg: Color(0xFFE1F5FE),
    ),
    ServiceCategoryStyle(
      name: 'Hotel',
      icon: Icons.hotel_rounded,
      iconColor: Color(0xFFF57C00),
      iconBg: Color(0xFFFFF3E0),
    ),
    ServiceCategoryStyle(
      name: 'Resort',
      icon: Icons.beach_access_rounded,
      iconColor: Color(0xFF2E7D32),
      iconBg: Color(0xFFE8F5E9),
    ),
    ServiceCategoryStyle(
      name: 'Laundry',
      icon: Icons.local_laundry_service_rounded,
      iconColor: Color(0xFF8E24AA),
      iconBg: Color(0xFFF3E5F5),
    ),
    ServiceCategoryStyle(
      name: 'Water',
      icon: Icons.water_drop_rounded,
      iconColor: Color(0xFF1976D2),
      iconBg: Color(0xFFE3F2FD),
    ),
    ServiceCategoryStyle(
      name: 'Civil',
      icon: Icons.construction_rounded,
      iconColor: Color(0xFFD84315),
      iconBg: Color(0xFFFBE9E7),
    ),
  ];

  // ── Init ──────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _getLocation();
    _setupFCM();
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    _listController.dispose();
    super.dispose();
  }

  // ── FCM ───────────────────────────────────────────
  Future<void> _setupFCM() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
          alert: true, badge: true, sound: true);
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && user != null) {
        await firestore
            .collection("users")
            .doc(user!.email?.toLowerCase())
            .set({"fcmToken": token}, SetOptions(merge: true));
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (user != null) {
          await firestore
              .collection("users")
              .doc(user!.email?.toLowerCase())
              .set({"fcmToken": newToken}, SetOptions(merge: true));
        }
      });
      _fcmSubscription =
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (!mounted) return;
        if (message.notification != null) {
          _showSnack(
            message.notification?.title ?? "New Notification",
            isSuccess: true,
          );
        }
      });
    } catch (e) {
      debugPrint("FCM ERROR: $e");
    }
  }

  // ── Location ──────────────────────────────────────
  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => loadingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 8));
      final marks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        city = marks.first.locality ?? "";
        loadingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingLocation = false);
    }
  }

  // ── Helpers ───────────────────────────────────────
  String normalize(String s) => s.trim().toLowerCase();

  String _getServiceType(String name) {
    if (name == "Educational Services") return "education";
    return normalize(name);
  }

  void _showSnack(String msg, {bool isSuccess = false, bool isError = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            isError
                ? Icons.error_outline
                : isSuccess
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: isError
            ? const Color(0xFFD84315)
            : isSuccess
                ? const Color(0xFF388E3C)
                : const Color(0xFF37474F),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Tap handler ───────────────────────────────────
  void _handleTap(
      ServiceCategoryStyle service, Map<String, dynamic>? provider) {
    if (user == null) {
      _showSnack("Please login first to continue", isError: true);
      return;
    }
    if (provider == null) {
      _showProviderTypeSelector(service);
      return;
    }
    final status = provider['status'] ?? "pending";
    if (status == "pending") {
      _showSnack("⏳ Your application is under review. Please wait.");
      return;
    }
    if (status == "rejected") {
      _showRejectedDialog(
          service, provider['rejectReason'] ?? "No reason provided.");
      return;
    }
    if (status == "approved") {
      final serviceType = _getServiceType(service.name);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BusinessDashboardPage(
            providerId: provider['providerId'] ?? '',
            businessName:
                provider['business']?['businessName'] ?? "My Business",
            serviceType: serviceType,
          ),
        ),
      );
    }
  }

  // ── Rejected dialog ───────────────────────────────
  void _showRejectedDialog(ServiceCategoryStyle service, String reason) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE9E7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.cancel_rounded,
                    color: Color(0xFFD84315), size: 30),
              ),
              const SizedBox(height: 16),
              const Text("Application Rejected",
                  style:
                      TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(reason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFF757575), height: 1.5)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text("Cancel",
                          style: TextStyle(color: Color(0xFF424242))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showProviderTypeSelector(service);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5C6BC0),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text("Reapply"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Provider type bottom sheet ────────────────────
  void _showProviderTypeSelector(ServiceCategoryStyle service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: service.iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(service.icon, color: service.iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Register as",
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500)),
                    Text(service.name,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF212121))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 28),
            _typeTile(service, "Individual", Icons.person_rounded,
                const Color(0xFF5C6BC0)),
            const SizedBox(height: 8),
            _typeTile(service, "Agency", Icons.groups_rounded,
                const Color(0xFF00897B)),
            const SizedBox(height: 8),
            _typeTile(service, "Business", Icons.business_rounded,
                const Color(0xFFF57C00)),
          ],
        ),
      ),
    );
  }

  Widget _typeTile(ServiceCategoryStyle service, String type,
      IconData icon, Color color) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceProviderForm(
                type: _getServiceType(service.name),
                providerType: type,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFF0F0F0)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Text(type,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121))),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFBDBDBD), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              "Become a Provider",
              style: TextStyle(
                color: Color(0xFF212121),
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child:
                  Container(height: 1, color: const Color(0xFFF0F0F0)),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  const Text(
                    "Service Categories",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF212121),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${businessCategories.length}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5C6BC0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (user == null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: _buildGridSliver({}, {}, size),
            )
          else
            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection("providers")
                    .where("userId", isEqualTo: user!.uid)
                    .snapshots(),
                builder: (context, providerSnap) {
                  final Map<String, Map<String, dynamic>> providerMap = {};
                  if (providerSnap.hasData) {
                    for (var doc in providerSnap.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final type = normalize(data['serviceType'] ?? "");
                      providerMap[type] = {...data, 'providerId': doc.id};
                    }
                  }
                  return StreamBuilder<QuerySnapshot>(
                    stream: firestore
                        .collection("orders")
                        .where("providerUserId", isEqualTo: user!.uid)
                        .where("status",
                            whereIn: ["pending", "accepted", "ongoing"])
                        .snapshots(),
                    builder: (context, orderSnap) {
                      final Map<String, int> orderCountMap = {};
                      if (orderSnap.hasData) {
                        for (var doc in orderSnap.data!.docs) {
                          final order =
                              doc.data() as Map<String, dynamic>;
                          final type =
                              normalize(order['serviceType'] ?? "");
                          orderCountMap[type] =
                              (orderCountMap[type] ?? 0) + 1;
                        }
                      }
                      return Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: businessCategories.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: size.width < 600 ? 2 : 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.05,
                          ),
                          itemBuilder: (_, i) =>
                              _buildCard(i, providerMap, orderCountMap),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      alignment: Alignment.bottomLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFDDE3FF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  loadingLocation
                      ? Icons.location_searching_rounded
                      : Icons.location_on_rounded,
                  color: const Color(0xFF5C6BC0),
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  loadingLocation
                      ? "Detecting location..."
                      : city.isNotEmpty
                          ? city
                          : "Location unavailable",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5C6BC0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Grow your business with us",
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  SliverGrid _buildGridSliver(
    Map<String, Map<String, dynamic>> providerMap,
    Map<String, int> orderCountMap,
    Size size,
  ) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: size.width < 600 ? 2 : 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      delegate: SliverChildBuilderDelegate(
        (_, i) => _buildCard(i, providerMap, orderCountMap),
        childCount: businessCategories.length,
      ),
    );
  }

  Widget _buildCard(
    int i,
    Map<String, Map<String, dynamic>> providerMap,
    Map<String, int> orderCountMap,
  ) {
    final category = businessCategories[i];
    final serviceType = _getServiceType(category.name);
    final provider = providerMap[serviceType];
    final count = orderCountMap[serviceType] ?? 0;
    final status = provider?['status'];

    final delay = i * 0.05;
    final animation = CurvedAnimation(
      parent: _listController,
      curve: Interval(delay.clamp(0.0, 0.8), 1.0,
          curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - animation.value)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () => _handleTap(category, provider),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF0F0F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: category.iconBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(category.icon,
                          color: category.iconColor, size: 26),
                    ),
                    const Spacer(),
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF212121),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (status != null)
                      _statusPill(status)
                    else
                      Row(
                        children: const [
                          Icon(Icons.add_circle_outline_rounded,
                              size: 12, color: Color(0xFFBDBDBD)),
                          SizedBox(width: 4),
                          Text(
                            "Register",
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9E9E9E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (count > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: category.iconColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      count > 99 ? "99+" : "$count",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    late Color color;
    late Color bg;
    late String label;
    late IconData icon;

    switch (status) {
      case "approved":
        color = const Color(0xFF2E7D32);
        bg = const Color(0xFFE8F5E9);
        label = "Active";
        icon = Icons.check_circle_rounded;
        break;
      case "pending":
        color = const Color(0xFFE65100);
        bg = const Color(0xFFFFF3E0);
        label = "Pending";
        icon = Icons.hourglass_top_rounded;
        break;
      case "rejected":
        color = const Color(0xFFD84315);
        bg = const Color(0xFFFBE9E7);
        label = "Rejected";
        icon = Icons.cancel_rounded;
        break;
      default:
        color = const Color(0xFF757575);
        bg = const Color(0xFFF5F5F5);
        label = status;
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}