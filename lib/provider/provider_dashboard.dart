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

  /// ================= PROVIDER STREAM =================
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

  /// ================= ACCEPT ORDER =================
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

  /// ================= COMPLETE ORDER =================
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

  /// ================= CANCEL ORDER =================
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

  /// ================= SNACKBAR =================
  void _msg(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            const Color(0xFF6C63FF),
        content: Text(message),
      ),
    );
  }

  /// ================= STATUS COLOR =================
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
            backgroundColor:
                const Color(0xFFF6F7FB),

            appBar: AppBar(
              elevation: 0,
              backgroundColor:
                  Colors.white,
              foregroundColor:
                  Colors.black,
              title: const Text(
                "Dashboard",
              ),
            ),

            body: Center(
              child: Container(
                margin:
                    const EdgeInsets.all(
                  24,
                ),

                padding:
                    const EdgeInsets.all(
                  24,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    24,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(
                        0.05,
                      ),
                      blurRadius: 12,
                    ),
                  ],
                ),

                child: const Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor:
                          Color(
                        0xFFF1EEFF,
                      ),

                      child: Icon(
                        Icons.hourglass_top,
                        size: 36,
                        color:
                            Color(
                          0xFF6C63FF,
                        ),
                      ),
                    ),

                    SizedBox(
                        height: 18),

                    Text(
                      "Waiting for Approval",

                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      "Your profile is under admin review.",

                      textAlign:
                          TextAlign.center,

                      style: TextStyle(
                        color:
                            Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 2,

          child: Scaffold(
            backgroundColor:
                const Color(0xFFF6F7FB),

            /// ================= APP BAR =================
            appBar: PreferredSize(
              preferredSize:
                  const Size.fromHeight(
                180,
              ),

              child: Container(
                decoration:
                    const BoxDecoration(
                  gradient:
                      LinearGradient(
                    colors: [
                      Color(0xFF6C63FF),
                      Color(0xFF8B80FF),
                    ],
                    begin:
                        Alignment.topLeft,
                    end:
                        Alignment.bottomRight,
                  ),
                ),

                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      18,
                      16,
                      18,
                      16,
                    ),

                    child: Column(
                      children: [
                        /// HEADER
                        Row(
                          children: [
                            Container(
                              width: 62,
                              height: 62,

                              decoration:
                                  BoxDecoration(
                                color: Colors
                                    .white
                                    .withOpacity(
                                  0.15,
                                ),

                                borderRadius:
                                    BorderRadius.circular(
                                  18,
                                ),
                              ),

                              child:
                                  const Icon(
                                Icons
                                    .business_center,
                                size: 30,
                                color:
                                    Colors
                                        .white,
                              ),
                            ),

                            const SizedBox(
                                width: 14),

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
                                      color:
                                          Colors
                                              .white,
                                      fontSize:
                                          22,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),

                                  const SizedBox(
                                      height:
                                          6),

                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal:
                                          12,
                                      vertical:
                                          5,
                                    ),

                                    decoration:
                                        BoxDecoration(
                                      color: Colors
                                          .white
                                          .withOpacity(
                                        0.16,
                                      ),

                                      borderRadius:
                                          BorderRadius.circular(
                                        30,
                                      ),
                                    ),

                                    child: Text(
                                      widget
                                          .serviceType,

                                      style:
                                          const TextStyle(
                                        color:
                                            Colors
                                                .white,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                        fontSize:
                                            13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// PROFILE BUTTON
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
                                width: 54,
                                height: 54,

                                decoration:
                                    BoxDecoration(
                                  shape:
                                      BoxShape
                                          .circle,

                                  color: Colors
                                      .white
                                      .withOpacity(
                                    0.18,
                                  ),

                                  border:
                                      Border.all(
                                    color:
                                        Colors
                                            .white,
                                    width:
                                        2,
                                  ),
                                ),

                                child:
                                    const Icon(
                                  Icons.person,
                                  color:
                                      Colors
                                          .white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                            height: 24),

                        /// TABS
                        Container(
                          height: 56,

                          decoration:
                              BoxDecoration(
                            color: Colors
                                .white
                                .withOpacity(
                              0.15,
                            ),

                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                          ),

                          child: TabBar(
                            dividerColor:
                                Colors
                                    .transparent,

                            indicator:
                                BoxDecoration(
                              color:
                                  Colors.white,

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
                                const Color(
                              0xFF6C63FF,
                            ),

                            unselectedLabelColor:
                                Colors.white,

                            labelStyle:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
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
                      ],
                    ),
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
          return Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,

              children: [
                Icon(
                  Icons.work_off,
                  size: 70,
                  color: Colors
                      .grey.shade400,
                ),

                const SizedBox(
                    height: 16),

                Text(
                  "No jobs found",

                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w600,
                    color: Colors
                        .grey.shade700,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.all(
            16,
          ),

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
                (data['services']
                            as List?)
                        ?.map(
                          (e) => e
                              .toString(),
                        )
                        .toList() ??
                    [];

            final status =
                data['status'] ??
                    "pending";

            return Container(
              margin:
                  const EdgeInsets.only(
                bottom: 18,
              ),

              decoration:
                  BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  24,
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(
                      0.05,
                    ),
                    blurRadius: 14,
                    offset:
                        const Offset(
                      0,
                      4,
                    ),
                  ),
                ],
              ),

              child: Padding(
                padding:
                    const EdgeInsets.all(
                  18,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    /// TOP
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              const Color(
                            0xFFF1EEFF,
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

                        const SizedBox(
                            width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              Text(
                                userData[
                                        'name'] ??
                                    "No Name",

                                maxLines: 1,

                                overflow:
                                    TextOverflow
                                        .ellipsis,

                                style:
                                    const TextStyle(
                                  fontSize:
                                      17,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              const SizedBox(
                                  height:
                                      4),

                              Text(
                                getStatusMessage(
                                  status,
                                ),

                                style:
                                    TextStyle(
                                  color: Colors
                                      .grey
                                      .shade600,
                                  fontSize:
                                      12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal:
                                12,
                            vertical:
                                6,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                getColor(
                              status,
                            ),

                            borderRadius:
                                BorderRadius.circular(
                              30,
                            ),
                          ),

                          child: Text(
                            status
                                .toUpperCase(),

                            style:
                                const TextStyle(
                              color: Colors
                                  .white,
                              fontSize:
                                  11,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                        height: 18),

                    /// DETAILS
                    _infoTile(
                      Icons.phone,
                      userData['phone'] ??
                          "",
                    ),

                    const SizedBox(
                        height: 10),

                    _infoTile(
                      Icons.location_on,
                      data['location']
                              ?['address'] ??
                          "",
                    ),

                    const SizedBox(
                        height: 10),

                    _infoTile(
                      Icons.calendar_today,
                      schedule['time'] ??
                          "",
                    ),

                    const SizedBox(
                        height: 18),

                    /// SERVICES
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,

                      children: services
                          .map(
                            (e) =>
                                Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal:
                                    12,
                                vertical:
                                    7,
                              ),

                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFF4F1FF,
                                ),

                                borderRadius:
                                    BorderRadius.circular(
                                  30,
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
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                  fontSize:
                                      12,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),

                    const SizedBox(
                        height: 20),

                    /// PRICE
                    Container(
                      padding:
                          const EdgeInsets.all(
                        14,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFF8F8FC,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                      ),

                      child: Row(
                        children: [
                          const Icon(
                            Icons.payments,
                            color:
                                Color(
                              0xFF6C63FF,
                            ),
                          ),

                          const SizedBox(
                              width: 10),

                          const Text(
                            "Total Amount",

                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),

                          const Spacer(),

                          Text(
                            "₹${payment['totalAmount'] ?? 0}",

                            style:
                                const TextStyle(
                              fontSize:
                                  20,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                        height: 18),

                    /// ACTION BUTTONS
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
                                      15,
                                ),

                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    16,
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
                                "Accept Job",

                                style:
                                    TextStyle(
                                  color:
                                      Colors
                                          .white,
                                  fontWeight:
                                      FontWeight
                                          .bold,
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
                                      15,
                                ),

                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    16,
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
                                      Colors
                                          .white,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                              width: 12),

                          Expanded(
                            child:
                                OutlinedButton(
                              style:
                                  OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical:
                                      15,
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
                                    16,
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
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// ================= INFO TILE =================
  Widget _infoTile(
    IconData icon,
    String text,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Container(
          padding:
              const EdgeInsets.all(8),

          decoration: BoxDecoration(
            color:
                const Color(0xFFF4F1FF),

            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),

          child: Icon(
            icon,
            size: 18,
            color:
                const Color(
              0xFF6C63FF,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(
              top: 4,
            ),

            child: Text(
              text,

              style:
                  const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}