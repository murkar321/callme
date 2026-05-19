import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'provider_profile_page.dart';

class BusinessDashboardPage extends StatefulWidget {
  final String providerId;
  final String businessName;
  final String serviceType;

  const BusinessDashboardPage({
    super.key,
    required this.providerId,
    required this.businessName,
    required this.serviceType,
  });

  @override
  State<BusinessDashboardPage> createState() =>
      _BusinessDashboardPageState();
}

class _BusinessDashboardPageState
    extends State<BusinessDashboardPage> {
  final ordersRef =
      FirebaseFirestore.instance.collection(
    'orders',
  );

  final providersRef =
      FirebaseFirestore.instance.collection(
    'providers',
  );

  final user =
      FirebaseAuth.instance.currentUser;

  /// ================= NORMALIZER =================
  String normalize(String s) =>
      s.trim().toLowerCase();

  /// ================= PROVIDER =================
  Stream<DocumentSnapshot> providerStream() {
    return providersRef
        .doc(widget.providerId)
        .snapshots();
  }

  /// ================= AVAILABLE JOBS =================
  Stream<QuerySnapshot> availableJobs() {
    return ordersRef
        .where(
          'serviceType',
          isEqualTo:
              normalize(widget.serviceType),
        )
        .where(
          'providerUserId',
          isEqualTo: "",
        )
        .where(
          'status',
          whereIn: [
            "pending",
            "enquiry",
          ],
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  /// ================= MY JOBS =================
  Stream<QuerySnapshot> myJobs() {
    return ordersRef
        .where(
          'providerUserId',
          isEqualTo: user!.uid,
        )
        .where(
          'serviceType',
          isEqualTo:
              normalize(widget.serviceType),
        )
        .where(
          'status',
          whereIn: [
            "accepted",
            "completed",
          ],
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  /// ================= ACCEPT =================
  Future<void> acceptOrder(
    String id,
  ) async {
    final ref = ordersRef.doc(id);

    try {
      await FirebaseFirestore.instance
          .runTransaction((tx) async {
        final snap = await tx.get(ref);

        final data =
            snap.data()
                as Map<String, dynamic>;

        if ((data['providerUserId'] ?? "") !=
            "") {
          throw Exception(
            "Already taken",
          );
        }

        tx.update(ref, {
          "providerId":
              widget.providerId,
          "providerUserId":
              user!.uid,
          "providerName":
              widget.businessName,
          "status": "accepted",
          "isAssigned": true,
          "updatedAt":
              FieldValue.serverTimestamp(),
        });
      });

      _msg("✅ Order accepted");
    } catch (e) {
      _msg("❌ Already taken");
    }
  }

  /// ================= COMPLETE =================
  Future<void> completeOrder(
    String id,
  ) async {
    await ordersRef.doc(id).update({
      "status": "completed",
      "isCompleted": true,
      "updatedAt":
          FieldValue.serverTimestamp(),
    });

    _msg("✅ Job completed");
  }

  /// ================= CANCEL =================
  Future<void> cancelOrder(
    String id,
  ) async {
    await ordersRef.doc(id).update({
      "status": "pending",
      "providerId": "",
      "providerUserId": "",
      "providerName": "",
      "isAssigned": false,
      "updatedAt":
          FieldValue.serverTimestamp(),
    });

    _msg("❌ Job reopened");
  }

  /// ================= MESSAGE =================
  void _msg(String m) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            const Color(0xFF6C63FF),
        content: Text(m),
      ),
    );
  }

  /// ================= STATUS COLORS =================
  Color getColor(String status) {
    switch (status) {
      case "accepted":
        return Colors.green;

      case "completed":
        return Colors.blue;

      default:
        return Colors.orange;
    }
  }

  /// ================= STATUS MESSAGE =================
  String getStatusMessage(
    String status,
  ) {
    switch (status) {
      case "accepted":
        return "Contact customer & start work";

      case "completed":
        return "Work completed successfully";

      case "enquiry":
        return "Customer requested callback";

      default:
        return "New job available";
    }
  }

  /// ================= MAIN =================
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: providerStream(),

      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        final provider =
            snap.data!.data()
                as Map<String, dynamic>?;

        /// APPROVAL CHECK
        if (provider?['status'] !=
            "approved") {
          return Scaffold(
            appBar: AppBar(
              title:
                  const Text("Dashboard"),
            ),

            body: const Center(
              child: Text(
                "⏳ Waiting for admin approval",
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 2,

          child: Scaffold(
            backgroundColor:
                const Color(0xFFF5F6FA),

            /// ================= APP BAR =================
            appBar: PreferredSize(
              preferredSize:
                  const Size.fromHeight(
                150,
              ),

              child: Container(
                decoration:
                    const BoxDecoration(
                  color: Colors.white,

                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color:
                          Color(0x12000000),
                    ),
                  ],
                ),

                child: SafeArea(
                  child: Column(
                    children: [
                      /// HEADER
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          14,
                          16,
                          10,
                        ),

                        child: Row(
                          children: [
                            /// LOGO
                            Container(
                              width: 56,
                              height: 56,

                              decoration:
                                  BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(
                                  16,
                                ),

                                gradient:
                                    const LinearGradient(
                                  colors: [
                                    Color(
                                      0xFF6C63FF,
                                    ),
                                    Color(
                                      0xFF8B80FF,
                                    ),
                                  ],
                                ),
                              ),

                              child:
                                  const Icon(
                                Icons
                                    .business_center,
                                color:
                                    Colors.white,
                                size: 28,
                              ),
                            ),

                            const SizedBox(
                                width: 14),

                            /// TITLE
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [
                                  Text(
                                    widget
                                        .businessName,

                                    maxLines: 1,

                                    overflow:
                                        TextOverflow
                                            .ellipsis,

                                    style:
                                        const TextStyle(
                                      fontSize:
                                          22,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),

                                  const SizedBox(
                                      height:
                                          4),

                                  Text(
                                    widget
                                        .serviceType,

                                    maxLines: 1,

                                    overflow:
                                        TextOverflow
                                            .ellipsis,

                                    style:
                                        TextStyle(
                                      color: Colors
                                          .grey
                                          .shade600,
                                      fontSize:
                                          15,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// PROFILE
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,

                                  MaterialPageRoute(
                                    builder:
                                        (_) =>
                                            ProviderProfilePage(
                                      providerId:
                                          widget
                                              .providerId,
                                    ),
                                  ),
                                );
                              },

                              child:
                                  Container(
                                width: 52,
                                height: 52,

                                decoration:
                                    BoxDecoration(
                                  shape:
                                      BoxShape
                                          .circle,

                                  border:
                                      Border.all(
                                    color:
                                        const Color(
                                      0xFF6C63FF,
                                    ),
                                    width:
                                        2.5,
                                  ),
                                ),

                                child:
                                    const Icon(
                                  Icons.person,
                                  color:
                                      Color(
                                    0xFF6C63FF,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// MODERN TAB SWITCH
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),

                        child: Container(
                          height: 54,

                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFF1F3F6,
                            ),

                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),

                          child: TabBar(
                            dividerColor:
                                Colors
                                    .transparent,

                            indicator:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFF6C63FF,
                              ),

                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                            ),

                            indicatorPadding:
                                const EdgeInsets.all(
                              5,
                            ),

                            labelColor:
                                Colors.white,

                            unselectedLabelColor:
                                Colors.black87,

                            labelStyle:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                              fontSize: 14,
                            ),

                            tabs: const [
                              Tab(
                                child: FittedBox(
                                  fit:
                                      BoxFit
                                          .scaleDown,

                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons
                                            .work_outline,
                                        size:
                                            18,
                                      ),

                                      SizedBox(
                                          width:
                                              8),

                                      Text(
                                        "Available Jobs",
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Tab(
                                child: FittedBox(
                                  fit:
                                      BoxFit
                                          .scaleDown,

                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons
                                            .check_circle_outline,
                                        size:
                                            18,
                                      ),

                                      SizedBox(
                                          width:
                                              8),

                                      Text(
                                        "My Jobs",
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 14),
                    ],
                  ),
                ),
              ),
            ),

            /// ================= BODY =================
            body: TabBarView(
              children: [
                _jobList(
                  availableJobs(),
                  true,
                ),

                _jobList(
                  myJobs(),
                  false,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ================= JOB LIST =================
  Widget _jobList(
    Stream<QuerySnapshot> stream,
    bool isAvailable,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,

      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "No jobs found",
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.all(12),

          itemCount: docs.length,

          itemBuilder: (_, i) {
            final doc = docs[i];

            final data =
                doc.data()
                    as Map<String, dynamic>;

            final userData =
                data['user'] ?? {};

            final payment =
                data['payment'] ?? {};

            final schedule =
                data['schedule'] ?? {};

            final services =
                (data['services'] as List?)
                        ?.map(
                          (e) =>
                              e.toString(),
                        )
                        .toList() ??
                    [];

            final status =
                data['status'] ?? "pending";

            return Container(
              margin:
                  const EdgeInsets.only(
                bottom: 12,
              ),

              padding:
                  const EdgeInsets.all(
                14,
              ),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  18,
                ),

                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black
                        .withOpacity(
                      0.05,
                    ),
                  )
                ],
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  /// NAME
                  Text(
                    userData['name'] ??
                        "No Name",

                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                      height: 8),

                  /// PHONE
                  Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 16,
                        color:
                            Color(0xFF6C63FF),
                      ),

                      const SizedBox(
                          width: 8),

                      Expanded(
                        child: Text(
                          userData['phone'] ??
                              "",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 6),

                  /// LOCATION
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color:
                            Color(0xFF6C63FF),
                      ),

                      const SizedBox(
                          width: 8),

                      Expanded(
                        child: Text(
                          data['location']
                                  ?['address'] ??
                              "",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 8),

                  /// SERVICES
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,

                    children: services
                        .map(
                          (e) => Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal:
                                  10,
                              vertical:
                                  5,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFFF1EEFF,
                              ),

                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),

                            child: Text(
                              e,

                              style:
                                  const TextStyle(
                                color:
                                    Color(
                                  0xFF6C63FF,
                                ),
                                fontSize:
                                    12,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(
                      height: 10),

                  /// DATE
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 15,
                        color:
                            Color(0xFF6C63FF),
                      ),

                      const SizedBox(
                          width: 8),

                      Expanded(
                        child: Text(
                          schedule['time'] ??
                              "",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 12),

                  /// PRICE + STATUS
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,

                    children: [
                      Text(
                        "₹${payment['totalAmount'] ?? 0}",

                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              getColor(status),

                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                        ),

                        child: Text(
                          status
                              .toUpperCase(),

                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 6),

                  Text(
                    getStatusMessage(
                      status,
                    ),

                    style:
                        TextStyle(
                      color:
                          Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(
                      height: 14),

                  /// ACTIONS
                  Row(
                    children: [
                      if (isAvailable)
                        Expanded(
                          child:
                              ElevatedButton(
                            style:
                                ElevatedButton.styleFrom(
                              elevation:
                                  0,

                              backgroundColor:
                                  const Color(
                                0xFF6C63FF,
                              ),

                              padding:
                                  const EdgeInsets.symmetric(
                                vertical:
                                    14,
                              ),

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                              ),
                            ),

                            onPressed:
                                () =>
                                    acceptOrder(
                              doc.id,
                            ),

                            child:
                                const Text(
                              "Accept",
                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                              ),
                            ),
                          ),
                        ),

                      if (!isAvailable &&
                          status ==
                              "accepted") ...[
                        Expanded(
                          child:
                              ElevatedButton(
                            style:
                                ElevatedButton.styleFrom(
                              elevation:
                                  0,

                              backgroundColor:
                                  Colors.green,

                              padding:
                                  const EdgeInsets.symmetric(
                                vertical:
                                    14,
                              ),

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                              ),
                            ),

                            onPressed:
                                () =>
                                    completeOrder(
                              doc.id,
                            ),

                            child:
                                const Text(
                              "Complete",
                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                            width: 10),

                        Expanded(
                          child:
                              OutlinedButton(
                            style:
                                OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical:
                                    14,
                              ),

                              side:
                                  const BorderSide(
                                color:
                                    Colors.red,
                              ),

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                              ),
                            ),

                            onPressed:
                                () =>
                                    cancelOrder(
                              doc.id,
                            ),

                            child:
                                const Text(
                              "Cancel",

                              style:
                                  TextStyle(
                                color:
                                    Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}