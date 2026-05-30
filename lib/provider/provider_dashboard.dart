import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final User? user =
      FirebaseAuth.instance.currentUser;

  /// =========================================================
  /// NORMALIZE
  /// =========================================================

  String normalize(String value) {
    return value
        .trim()
        .toLowerCase();
  }

  /// =========================================================
  /// PROVIDER STREAM
  /// =========================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      providerStream() {
    return firestore
        .collection("providers")
        .doc(widget.providerId)
        .snapshots();
  }

  /// =========================================================
  /// AVAILABLE JOBS
  /// =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      availableJobs() {
    return firestore
        .collection("orders")
        .orderBy(
          "createdAt",
          descending: true,
        )
        .snapshots();
  }

  /// =========================================================
  /// MY JOBS
  /// =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      myJobs() {
    return firestore
        .collection("orders")
        .where(
          "providerUserId",
          isEqualTo: user?.uid ?? "",
        )
        .orderBy(
          "createdAt",
          descending: true,
        )
        .snapshots();
  }

  /// =========================================================
  /// ACCEPT ORDER
  /// =========================================================

  Future<void> acceptOrder(
    String orderId,
  ) async {
    try {
      final ref = firestore
          .collection("orders")
          .doc(orderId);

      await firestore
          .runTransaction((tx) async {
        final snap =
            await tx.get(ref);

        final data =
            snap.data() ?? {};

        final assigned =
            data["providerUserId"] ??
                "";

        if (assigned
            .toString()
            .isNotEmpty) {
          throw Exception(
            "Already assigned",
          );
        }

        tx.update(ref, {
          "providerId":
              widget.providerId,
          "providerUserId":
              user?.uid ?? "",
          "providerName":
              widget.businessName,
          "status": "accepted",
          "isAssigned": true,
          "updatedAt":
              FieldValue.serverTimestamp(),
          "lastActionBy":
              "provider",
        });
      });

      showMessage(
        "Order accepted successfully",
      );
    } catch (e) {
      showMessage(
        "Order already accepted",
      );
    }
  }

  /// =========================================================
  /// COMPLETE ORDER
  /// =========================================================

  Future<void> completeOrder(
    String orderId,
  ) async {
    await firestore
        .collection("orders")
        .doc(orderId)
        .update({
      "status": "completed",
      "isCompleted": true,
      "updatedAt":
          FieldValue.serverTimestamp(),
      "lastActionBy": "provider",
    });

    showMessage(
      "Order completed successfully",
    );
  }

  /// =========================================================
  /// CANCEL ORDER
  /// =========================================================

  Future<void> cancelOrder(
    String orderId,
    String note,
  ) async {
    await firestore
        .collection("orders")
        .doc(orderId)
        .update({
      "status": "cancelled",
      "providerCancelNote":
          note.isEmpty
              ? "Provider cancelled this booking"
              : note,
      "cancelledBy":
          "provider",
      "providerId": "",
      "providerUserId": "",
      "providerName": "",
      "isAssigned": false,
      "updatedAt":
          FieldValue.serverTimestamp(),
      "lastActionBy":
          "provider",
    });

    showMessage(
      "Order cancelled",
    );
  }

  /// =========================================================
  /// CANCEL DIALOG
  /// =========================================================

  Future<void> showCancelDialog(
    String orderId,
  ) async {
    final controller =
        TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              28,
            ),
          ),
          child: Padding(
            padding:
                const EdgeInsets.all(
              22,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  "Cancel Job",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                    height: 12),
                TextField(
                  controller:
                      controller,
                  maxLines: 5,
                  decoration:
                      InputDecoration(
                    hintText:
                        "Write cancellation reason...",
                    filled: true,
                    fillColor:
                        const Color(
                      0xFFF5F6FA,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(
                    height: 20),
                Row(
                  children: [
                    Expanded(
                      child:
                          OutlinedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                          );
                        },
                        child:
                            const Text(
                          "Close",
                        ),
                      ),
                    ),
                    const SizedBox(
                        width: 12),
                    Expanded(
                      child:
                          ElevatedButton(
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.red,
                        ),
                        onPressed:
                            () async {
                          await cancelOrder(
                            orderId,
                            controller.text
                                .trim(),
                          );

                          if (mounted) {
                            Navigator.pop(
                              context,
                            );
                          }
                        },
                        child:
                            const Text(
                          "Cancel",
                          style:
                              TextStyle(
                            color:
                                Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// =========================================================
  /// MESSAGE
  /// =========================================================

  void showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            const Color(
          0xFF6C63FF,
        ),
      ),
    );
  }

  /// =========================================================
  /// STATUS COLOR
  /// =========================================================

  Color getStatusColor(
    String status,
  ) {
    switch (
        status.toLowerCase()) {
      case "accepted":
        return Colors.green;

      case "completed":
        return Colors.blue;

      case "cancelled":
        return Colors.red;

      case "enquiry":
        return Colors.orange;

      default:
        return const Color(
          0xFF6C63FF,
        );
    }
  }

  /// =========================================================
  /// BUILD
  /// =========================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<
        DocumentSnapshot<
            Map<String, dynamic>>>(
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
            snap.data?.data() ?? {};

        if (provider["status"] !=
            "approved") {
          return Scaffold(
            backgroundColor:
                const Color(
              0xFFF6F7FB,
            ),
            body: const Center(
              child: Text(
                "Waiting For Approval",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor:
                const Color(
              0xFFF6F7FB,
            ),
            body: Column(
              children: [
                /// HEADER

                Container(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    55,
                    20,
                    24,
                  ),
                  decoration:
                      const BoxDecoration(
                    gradient:
                        LinearGradient(
                      colors: [
                        Color(
                          0xFF6C63FF,
                        ),
                        Color(
                          0xFF8B80FF,
                        ),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.only(
                      bottomLeft:
                          Radius.circular(
                        34,
                      ),
                      bottomRight:
                          Radius.circular(
                        34,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration:
                                BoxDecoration(
                              color: Colors
                                  .white
                                  .withOpacity(
                                .15,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                22,
                              ),
                            ),
                            child:
                                const Icon(
                              Icons
                                  .business_center_rounded,
                              color:
                                  Colors.white,
                              size: 34,
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
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize:
                                        24,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                const SizedBox(
                                    height:
                                        6),
                                Text(
                                  widget
                                      .serviceType,
                                  style:
                                      const TextStyle(
                                    color: Colors
                                        .white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                              width: 58,
                              height: 58,
                              decoration:
                                  BoxDecoration(
                                shape:
                                    BoxShape
                                        .circle,
                                color: Colors
                                    .white
                                    .withOpacity(
                                  .18,
                                ),
                              ),
                              child:
                                  const Icon(
                                Icons.person,
                                color:
                                    Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                          height: 24),
                      Container(
                        height: 58,
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .white
                              .withOpacity(
                            .15,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                        ),
                        child: TabBar(
                          indicator:
                              BoxDecoration(
                            color:
                                Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                          dividerColor:
                              Colors
                                  .transparent,
                          labelColor:
                              const Color(
                            0xFF6C63FF,
                          ),
                          unselectedLabelColor:
                              Colors.white,
                          tabs: const [
                            Tab(
                              text:
                                  "Available Jobs",
                            ),
                            Tab(
                              text:
                                  "My Jobs",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                /// BODY

                Expanded(
                  child: TabBarView(
                    children: [
                      buildOrders(
                        availableJobs(),
                        true,
                      ),
                      buildOrders(
                        myJobs(),
                        false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// =========================================================
  /// BUILD ORDERS
  /// =========================================================

  Widget buildOrders(
    Stream<QuerySnapshot<
            Map<String, dynamic>>>
        stream,
    bool isAvailable,
  ) {
    return StreamBuilder<
        QuerySnapshot<
            Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        final allDocs =
            snapshot.data!.docs;

        final docs =
            allDocs.where((doc) {
          final data = doc.data();

          final status =
              normalize(
            data["status"] ?? "",
          );

          final assigned =
              (data["providerUserId"] ??
                      "")
                  .toString();

          final orderService =
              normalize(
            data["serviceType"] ??
                "",
          );

          final providerService =
              normalize(
            widget.serviceType,
          );

          if (isAvailable) {
            return
                (status ==
                            "pending" ||
                        status ==
                            "enquiry") &&
                    assigned
                        .isEmpty &&
                orderService ==
                    providerService;
          }

          return assigned ==
              (user?.uid ?? "");
        }).toList();

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "No Jobs Found",
            ),
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.all(
            16,
          ),
          itemCount: docs.length,
          itemBuilder:
              (_, index) {
            final doc =
                docs[index];

            final data =
                doc.data();

            final status =
                data["status"] ??
                    "pending";

            final payment =
                data["payment"] ??
                    {};

            final location =
                data["location"] ??
                    {};

            final schedule =
                data["schedule"] ??
                    {};

            final createdAt =
                data["createdAt"]
                    as Timestamp?;

            String date = "-";

            if (createdAt != null) {
              date = DateFormat(
                "dd MMM yyyy • hh:mm a",
              ).format(
                createdAt.toDate(),
              );
            }

            return Container(
              margin:
                  const EdgeInsets.only(
                bottom: 18,
              ),
              padding:
                  const EdgeInsets.all(
                18,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  28,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(
                      .04,
                    ),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data["userName"] ??
                              "Unknown User",
                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal:
                              14,
                          vertical: 8,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              getStatusColor(
                            status,
                          ).withOpacity(
                            .12,
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
                              TextStyle(
                            color:
                                getStatusColor(
                              status,
                            ),
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

                  infoTile(
                    Icons.phone,
                    data["phone"] ??
                        "-",
                  ),

                  const SizedBox(
                      height: 12),

                  infoTile(
                    Icons.location_on,
                    location["address"] ??
                        "-",
                  ),

                  const SizedBox(
                      height: 12),

                  infoTile(
                    Icons.calendar_today,
                    "${schedule["time"] ?? ""} • $date",
                  ),

                  const SizedBox(
                      height: 18),

                  Container(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    decoration:
                        BoxDecoration(
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
                      borderRadius:
                          BorderRadius.circular(
                        22,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          "Amount",
                          style:
                              TextStyle(
                            color:
                                Colors.white,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "₹${payment["totalAmount"] ?? 0}",
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                      height: 18),

                  if (isAvailable)
                    Row(
                      children: [
                        Expanded(
                          child:
                              ElevatedButton(
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFF6C63FF,
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
                                color: Colors
                                    .white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                            width: 12),

                        Expanded(
                          child:
                              OutlinedButton(
                            onPressed:
                                () =>
                                    showCancelDialog(
                              doc.id,
                            ),
                            child:
                                const Text(
                              "Reject",
                              style:
                                  TextStyle(
                                color:
                                    Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  if (!isAvailable &&
                      status ==
                          "accepted")
                    Row(
                      children: [
                        Expanded(
                          child:
                              ElevatedButton(
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.green,
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
                                color: Colors
                                    .white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                            width: 12),

                        Expanded(
                          child:
                              OutlinedButton(
                            onPressed:
                                () =>
                                    showCancelDialog(
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
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// =========================================================
  /// INFO TILE
  /// =========================================================

  Widget infoTile(
    IconData icon,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color:
              const Color(
            0xFF6C63FF,
          ),
        ),
        const SizedBox(
            width: 10),
        Expanded(
          child: Text(
            value,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}