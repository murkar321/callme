import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:callme/models/service_category.dart';
import 'package:callme/widgets/category_card.dart';
import 'package:callme/provider/service_provider_form.dart';
import 'package:callme/provider/provider_dashboard.dart';

class BusinessPage extends StatefulWidget {
  const BusinessPage({super.key});

  @override
  State<BusinessPage> createState() =>
      _BusinessPageState();
}

class _BusinessPageState
    extends State<BusinessPage> {

  /// =====================================================
  /// FIREBASE
  /// =====================================================

  User? get user =>
      FirebaseAuth.instance.currentUser;

  final firestore =
      FirebaseFirestore.instance;

  /// =====================================================
  /// LOCATION
  /// =====================================================

  String city = "";

  bool loadingLocation = true;

  /// =====================================================
  /// CATEGORIES
  /// =====================================================

  final List<ServiceCategory>
      businessCategories = [

    ServiceCategory(
      name: 'Salon',
      icon: Icons.content_cut,
    ),

    ServiceCategory(
      name: 'Educational Services',
      icon: Icons.school,
    ),

    ServiceCategory(
      name: 'Cleaning',
      icon:
      Icons.cleaning_services,
    ),

    ServiceCategory(
      name: 'Plumbing',
      icon: Icons.plumbing,
    ),

    ServiceCategory(
      name: 'Hotel',
      icon: Icons.hotel,
    ),

    ServiceCategory(
      name: 'Resort',
      icon:
      Icons.holiday_village,
    ),

    ServiceCategory(
      name: 'Laundry',
      icon:
      Icons.local_laundry_service,
    ),

    ServiceCategory(
      name: 'Water',
      icon: Icons.water_drop,
    ),

    ServiceCategory(
      name: 'Civil',
      icon: Icons.construction,
    ),
  ];

  /// =====================================================
  /// INIT
  /// =====================================================

  @override
  void initState() {

    super.initState();

    _getLocation();

    _setupFCM();
  }

  /// =====================================================
  /// FCM SETUP
  /// =====================================================

  Future<void> _setupFCM() async {

    try {

      /// REQUEST PERMISSION

      await FirebaseMessaging.instance
          .requestPermission(

        alert: true,
        badge: true,
        sound: true,
      );

      /// GET TOKEN

      String? token =

      await FirebaseMessaging.instance
          .getToken();

      debugPrint(
        "FCM TOKEN: $token",
      );

      if (token != null &&
          user != null) {

        /// SAVE TOKEN TO PROVIDER

        await firestore
            .collection("users")
            .doc(user!.uid)
            .set({

          "fcmToken": token,

        }, SetOptions(
          merge: true,
        ));
      }

      /// TOKEN REFRESH

      FirebaseMessaging.instance
          .onTokenRefresh
          .listen((newToken) async {

        if (user != null) {

          await firestore
              .collection("users")
              .doc(user!.uid)
              .set({

            "fcmToken": newToken,

          }, SetOptions(
            merge: true,
          ));
        }
      });

      /// FOREGROUND MESSAGE

      FirebaseMessaging.onMessage
          .listen((RemoteMessage message) {

        if (message.notification !=
            null) {

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(

            SnackBar(

              content: Text(

                message.notification
                    ?.title ??
                    "New Notification",
              ),

              backgroundColor:
              Colors.green,
            ),
          );
        }
      });

    } catch (e) {

      debugPrint(
        "FCM ERROR: $e",
      );
    }
  }

  /// =====================================================
  /// LOCATION
  /// =====================================================

  Future<void> _getLocation() async {

    try {

      await Geolocator
          .requestPermission();

      Position pos =
      await Geolocator
          .getCurrentPosition(

        timeLimit:
        const Duration(
          seconds: 5,
        ),
      );

      List<Placemark>
      placemarks =
      await placemarkFromCoordinates(

        pos.latitude,
        pos.longitude,
      );

      if (!mounted) return;

      setState(() {

        city =
            placemarks
                .first
                .locality ?? "";

        loadingLocation = false;
      });

    } catch (e) {

      if (!mounted) return;

      setState(() {

        loadingLocation = false;
      });
    }
  }

  /// =====================================================
  /// HELPERS
  /// =====================================================

  String normalize(String s) {

    return s
        .trim()
        .toLowerCase();
  }

  String _getServiceType(
      String name) {

    if (name ==
        "Educational Services") {

      return "education";
    }

    return normalize(name);
  }

  void _showMessage(String msg) {

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(
        content: Text(msg),
      ),
    );
  }

  /// =====================================================
  /// TAP
  /// =====================================================

  void _handleTap(

      ServiceCategory service,

      Map<String, dynamic>? provider,
      ) {

    final serviceType =
    _getServiceType(
      service.name,
    );

    if (user == null) {

      _showMessage(
        "Please login first",
      );

      return;
    }

    /// NO PROVIDER

    if (provider == null) {

      _showProviderTypeSelector(
        service,
      );

      return;
    }

    final status =
        provider['status']
        ?? "pending";

    /// PENDING

    if (status == "pending") {

      _showMessage(
        "⏳ Under review",
      );

      return;
    }

    /// REJECTED

    if (status == "rejected") {

      _showRejectedDialog(

        service,

        provider['rejectReason']
        ??
            "No reason provided",
      );

      return;
    }

    /// APPROVED

    if (status == "approved") {

      Navigator.push(

        context,

        MaterialPageRoute(

          builder: (_) =>
              BusinessDashboardPage(

                providerId:
                provider['providerId'],

                businessName:
                provider['business']
                ?['businessName']
                    ??
                    "My Business",

                serviceType:
                serviceType,
              ),
        ),
      );
    }
  }

  /// =====================================================
  /// REJECT DIALOG
  /// =====================================================

  void _showRejectedDialog(

      ServiceCategory service,

      String reason,
      ) {

    showDialog(

      context: context,

      builder: (_) => AlertDialog(

        title:
        const Text("Rejected ❌"),

        content:
        Text("Reason: $reason"),

        actions: [

          TextButton(

            onPressed: () {

              Navigator.pop(context);

              _showProviderTypeSelector(
                service,
              );
            },

            child:
            const Text("Reapply"),
          ),
        ],
      ),
    );
  }

  /// =====================================================
  /// PROVIDER TYPE
  /// =====================================================

  void _showProviderTypeSelector(
      ServiceCategory service,
      ) {

    showModalBottomSheet(

      context: context,

      shape:
      const RoundedRectangleBorder(

        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),

      builder: (_) {

        return Padding(

          padding:
          const EdgeInsets.all(18),

          child: Column(

            mainAxisSize:
            MainAxisSize.min,

            children: [

              Text(

                "Register as ${service.name}",

                style: const TextStyle(

                  fontSize: 18,

                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              _typeTile(
                service,
                "Individual",
                Icons.person,
              ),

              _typeTile(
                service,
                "Agency",
                Icons.groups,
              ),

              _typeTile(
                service,
                "Business",
                Icons.business,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _typeTile(

      ServiceCategory service,

      String type,

      IconData icon,
      ) {

    return ListTile(

      leading: Icon(icon),

      title: Text(type),

      onTap: () {

        Navigator.pop(context);

        Navigator.push(

          context,

          MaterialPageRoute(

            builder: (_) =>
                ServiceProviderForm(

                  type:
                  _getServiceType(
                    service.name,
                  ),

                  providerType: type,
                ),
          ),
        );
      },
    );
  }

  /// =====================================================
  /// BUILD
  /// =====================================================

  @override
  Widget build(BuildContext context) {

    final size =
    MediaQuery.of(context).size;

    return Scaffold(

      backgroundColor:
      const Color(0xFFF4F6FA),

      appBar: AppBar(

        backgroundColor:
        Colors.white,

        centerTitle: true,

        title: const Text(

          "Become a Provider",

          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),

      body: Column(

        children: [

          /// HEADER

          Container(

            width: double.infinity,

            margin:
            const EdgeInsets.all(12),

            padding:
            const EdgeInsets.all(18),

            decoration: BoxDecoration(

              gradient:
              const LinearGradient(

                colors: [
                  Colors.blue,
                  Colors.purple,
                ],
              ),

              borderRadius:
              BorderRadius.circular(16),
            ),

            child: Text(

              loadingLocation

                  ? "Detecting location..."

                  : "Available in $city",

              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),

          const Padding(

            padding:
            EdgeInsets.symmetric(
              horizontal: 16,
            ),

            child: Align(

              alignment:
              Alignment.centerLeft,

              child: Text(

                "Select Service Category",

                style: TextStyle(

                  fontSize: 16,

                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// =====================================================
          /// PROVIDERS STREAM
          /// =====================================================

          Expanded(

            child: user == null

                ? _buildGrid(
              {},
              {},
              size,
            )

                : StreamBuilder<
                QuerySnapshot>(

              stream: firestore
                  .collection(
                "providers",
              )
                  .where(
                "userId",
                isEqualTo:
                user!.uid,
              )
                  .snapshots(),

              builder: (
                  context,
                  providerSnapshot,
                  ) {

                if (providerSnapshot
                    .hasError) {

                  return const Center(
                    child: Text(
                      "Error loading providers",
                    ),
                  );
                }

                Map<String,
                    Map<String,
                        dynamic>>
                providerMap = {};

                if (providerSnapshot
                    .hasData) {

                  for (var doc
                  in providerSnapshot
                      .data!
                      .docs) {

                    final data =
                    doc.data()
                    as Map<String,
                        dynamic>;

                    final type =
                    normalize(
                      data['serviceType']
                      ??
                          "",
                    );

                    providerMap[type] =
                        data;
                  }
                }

                /// =====================================================
                /// ORDERS STREAM
                /// =====================================================

                return StreamBuilder<
                    QuerySnapshot>(

                  stream: firestore
                      .collection(
                    "orders",
                  )
                      .where(
                    "providerUserId",
                    isEqualTo:
                    user!.uid,
                  )
                      .where(
                    "status",
                    whereIn: [

                      "pending",

                      "accepted",

                      "ongoing",
                    ],
                  )
                      .snapshots(),

                  builder: (
                      context,
                      orderSnapshot,
                      ) {

                    Map<String, int>
                    orderCountMap = {};

                    if (orderSnapshot
                        .hasData) {

                      for (var doc
                      in orderSnapshot
                          .data!
                          .docs) {

                        final order =
                        doc.data()
                        as Map<String,
                            dynamic>;

                        final type =
                        normalize(

                          order[
                          'serviceType']
                              ??
                              "",
                        );

                        orderCountMap[
                        type] =

                            (orderCountMap[
                            type] ??
                                0) +
                                1;
                      }
                    }

                    return _buildGrid(

                      providerMap,

                      orderCountMap,

                      size,
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

  /// =====================================================
  /// GRID
  /// =====================================================

  Widget _buildGrid(

      Map<String,
      Map<String, dynamic>>
      providerMap,

      Map<String, int>
      orderCountMap,

      Size size,
      ) {

    return GridView.builder(

      padding:
      const EdgeInsets.all(12),

      itemCount:
      businessCategories.length,

      gridDelegate:
      SliverGridDelegateWithFixedCrossAxisCount(

        crossAxisCount:
        size.width < 600
            ? 2
            : 3,

        crossAxisSpacing: 12,

        mainAxisSpacing: 12,
      ),

      itemBuilder: (_, i) {

        final category =
        businessCategories[i];

        final serviceType =
        _getServiceType(
          category.name,
        );

        final provider =
        providerMap[serviceType];

        final count =
            orderCountMap[
            serviceType] ??
                0;

        return GestureDetector(

          onTap: () => _handleTap(
            category,
            provider,
          ),

          child: Stack(

            children: [

              Positioned.fill(

                child: CategoryCard(

                  name:
                  category.name,

                  icon:
                  category.icon,

                  showName: true,

                  imagePath: '',
                ),
              ),

              /// ORDER BADGE

              if (count > 0)

                Positioned(

                  top: 8,

                  right: 8,

                  child: Container(

                    padding:
                    const EdgeInsets
                        .symmetric(

                      horizontal: 8,

                      vertical: 4,
                    ),

                    decoration:
                    BoxDecoration(

                      color: Colors.red,

                      borderRadius:
                      BorderRadius.circular(
                        30,
                      ),
                    ),

                    child: Text(

                      count > 99
                          ? "99+"
                          : count.toString(),

                      style:
                      const TextStyle(

                        color:
                        Colors.white,

                        fontWeight:
                        FontWeight.bold,

                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}