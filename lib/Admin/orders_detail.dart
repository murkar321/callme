import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() =>
      _AdminOrdersPageState();
}

class _AdminOrdersPageState
    extends State<AdminOrdersPage> {

  final CollectionReference ordersRef =
      FirebaseFirestore.instance.collection(
    "orders",
  );

  String search = "";
  String filter = "all";

  /// ================= STATUS COLOR =================
  Color getColor(String status) {
    switch (status.toLowerCase()) {

      case "accepted":
        return Colors.green;

      case "completed":
        return Colors.blue;

      case "rejected":
        return Colors.red;

      case "cancelled":
        return Colors.redAccent;

      default:
        return Colors.orange;
    }
  }

  /// ================= STATUS ICON =================
  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {

      case "accepted":
        return Icons.check_circle;

      case "completed":
        return Icons.task_alt_rounded;

      case "rejected":
        return Icons.cancel;

      case "cancelled":
        return Icons.cancel_schedule_send;

      default:
        return Icons.pending_actions_rounded;
    }
  }

  /// ================= UPDATE STATUS =================
  Future<void> updateStatus(
    String orderId,
    String status,
  ) async {

    try {

      await ordersRef.doc(orderId).update({

        "status": status,

        "updatedAt":
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(
            "Order marked as $status",
          ),
        ),
      );
    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(
            "Failed: $e",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
          const Color(0xfff5f7fb),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,

        title: const Text(
          "All Orders",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),

      body: Column(
        children: [

          /// ================= TOP CARD =================
          Container(
            margin:
                const EdgeInsets.all(16),

            padding:
                const EdgeInsets.all(20),

            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(
                colors: [
                  Color(0xff2563eb),
                  Color(0xff7c3aed),
                ],
              ),

              borderRadius:
                  BorderRadius.circular(24),
            ),

            child: Row(
              children: [

                Container(
                  padding:
                      const EdgeInsets.all(14),

                  decoration: BoxDecoration(
                    color: Colors.white
                        .withOpacity(.15),

                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),

                const SizedBox(width: 16),

                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      Text(
                        "Manage Service Orders",

                        style: TextStyle(
                          color:
                              Colors.white70,
                          fontSize: 15,
                        ),
                      ),

                      SizedBox(height: 6),

                      Text(
                        "Admin Dashboard",

                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 26,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// ================= SEARCH =================
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
            ),

            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(18),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(.04),

                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),

              child: TextField(
                onChanged: (val) {

                  setState(() {
                    search =
                        val.toLowerCase();
                  });
                },

                decoration:
                    const InputDecoration(
                  hintText:
                      "Search by customer, phone or service",

                  prefixIcon: Icon(
                    Icons.search_rounded,
                  ),

                  border: InputBorder.none,

                  contentPadding:
                      EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          /// ================= FILTER =================
          SizedBox(
            height: 45,

            child: ListView(
              scrollDirection:
                  Axis.horizontal,

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
              ),

              children: [

                _chip("all"),
                _chip("pending"),
                _chip("accepted"),
                _chip("completed"),
                _chip("rejected"),
                _chip("cancelled"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// ================= ORDERS =================
          Expanded(
            child:
                StreamBuilder<QuerySnapshot>(
              stream:
                  ordersRef.snapshots(),

              builder:
                  (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {

                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot
                        .data!.docs.isEmpty) {

                  return const Center(
                    child: Text(
                      "No Orders Found",

                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  );
                }

                final docs =
                    snapshot.data!.docs;

                /// SORT
                docs.sort((a, b) {

                  final aTime =
                      (a['createdAt']
                                  as Timestamp?)
                              ?.millisecondsSinceEpoch ??
                          0;

                  final bTime =
                      (b['createdAt']
                                  as Timestamp?)
                              ?.millisecondsSinceEpoch ??
                          0;

                  return bTime.compareTo(
                    aTime,
                  );
                });

                /// FILTER
                final filtered =
                    docs.where((doc) {

                  final data =
                      doc.data()
                          as Map<String,
                              dynamic>;

                  final customer =
                      (data['customerName'] ??
                              "")
                          .toString()
                          .toLowerCase();

                  final phone =
                      (data['customerPhone'] ??
                              "")
                          .toString()
                          .toLowerCase();

                  final service =
                      (data['serviceName'] ??
                              data['serviceType'] ??
                              "")
                          .toString()
                          .toLowerCase();

                  final provider =
                      (data['providerName'] ??
                              "")
                          .toString()
                          .toLowerCase();

                  final status =
                      (data['status'] ??
                              "pending")
                          .toString()
                          .toLowerCase();

                  final matchesSearch =
                      customer.contains(
                            search,
                          ) ||
                          phone.contains(
                            search,
                          ) ||
                          service.contains(
                            search,
                          ) ||
                          provider.contains(
                            search,
                          );

                  final matchesFilter =
                      filter == "all" ||
                          status == filter;

                  return matchesSearch &&
                      matchesFilter;
                }).toList();

                if (filtered.isEmpty) {

                  return const Center(
                    child: Text(
                      "No Matching Orders",
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),

                  itemCount:
                      filtered.length,

                  itemBuilder:
                      (_, index) {

                    final doc =
                        filtered[index];

                    final data =
                        doc.data()
                            as Map<String,
                                dynamic>;

                    final String status =
                        data['status'] ??
                            "pending";

                    final String service =
                        data['serviceName'] ??
                            data['serviceType'] ??
                            "Service";

                    final String customer =
                        data['customerName'] ??
                            "Unknown";

                    final String phone =
                        data['customerPhone'] ??
                            "-";

                    final String provider =
                        data['providerName'] ??
                            "Not Assigned";

                    final String address =
                        data['address'] ??
                            "-";

                    final Timestamp?
                        createdAt =
                        data['createdAt'];

                    String date = "-";

                    if (createdAt != null) {

                      date = DateFormat(
                        'dd MMM yyyy • hh:mm a',
                      ).format(
                        createdAt.toDate(),
                      );
                    }

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
                                    .05),

                            blurRadius: 12,

                            offset:
                                const Offset(
                              0,
                              5,
                            ),
                          ),
                        ],
                      ),

                      child: Padding(
                        padding:
                            const EdgeInsets
                                .all(18),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [

                            /// TOP
                            Row(
                              children: [

                                Container(
                                  height: 64,
                                  width: 64,

                                  decoration:
                                      BoxDecoration(
                                    gradient:
                                        const LinearGradient(
                                      colors: [
                                        Color(
                                            0xff2563eb),
                                        Color(
                                            0xff7c3aed),
                                      ],
                                    ),

                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      20,
                                    ),
                                  ),

                                  child:
                                      const Icon(
                                    Icons
                                        .miscellaneous_services_rounded,

                                    color: Colors
                                        .white,

                                    size: 32,
                                  ),
                                ),

                                const SizedBox(
                                  width: 16,
                                ),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,

                                    children: [

                                      Text(
                                        service
                                            .toUpperCase(),

                                        style:
                                            const TextStyle(
                                          fontSize:
                                              20,

                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 6,
                                      ),

                                      Text(
                                        customer,

                                        style:
                                            TextStyle(
                                          color: Colors
                                              .grey
                                              .shade700,

                                          fontSize:
                                              15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                /// STATUS
                                Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal:
                                        14,
                                    vertical:
                                        8,
                                  ),

                                  decoration:
                                      BoxDecoration(
                                    color:
                                        getColor(
                                      status,
                                    ).withOpacity(
                                      .12,
                                    ),

                                    borderRadius:
                                        BorderRadius.circular(
                                      30,
                                    ),
                                  ),

                                  child: Row(
                                    children: [

                                      Icon(
                                        getStatusIcon(
                                          status,
                                        ),

                                        size: 18,

                                        color:
                                            getColor(
                                          status,
                                        ),
                                      ),

                                      const SizedBox(
                                        width: 6,
                                      ),

                                      Text(
                                        status
                                            .toUpperCase(),

                                        style:
                                            TextStyle(
                                          color:
                                              getColor(
                                            status,
                                          ),

                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            Divider(
                              color: Colors
                                  .grey
                                  .shade200,
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            /// DETAILS
                            _infoTile(
                              icon: Icons.person,

                              title:
                                  "Customer",

                              value:
                                  customer,
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            _infoTile(
                              icon:
                                  Icons.phone,

                              title: "Phone",

                              value: phone,
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            _infoTile(
                              icon: Icons
                                  .engineering,

                              title:
                                  "Provider",

                              value:
                                  provider,
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            _infoTile(
                              icon: Icons
                                  .location_on,

                              title:
                                  "Address",

                              value:
                                  address,
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            _infoTile(
                              icon: Icons
                                  .calendar_month,

                              title:
                                  "Ordered On",

                              value: date,
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            /// ACTION BUTTONS
                            if (status !=
                                "completed")

                              Row(
                                children: [

                                  Expanded(
                                    child:
                                        OutlinedButton(
                                      onPressed:
                                          () {

                                        updateStatus(
                                          doc.id,
                                          "rejected",
                                        );
                                      },

                                      style:
                                          OutlinedButton.styleFrom(
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

                                        padding:
                                            const EdgeInsets.symmetric(
                                          vertical:
                                              14,
                                        ),
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

                                  const SizedBox(
                                    width: 12,
                                  ),

                                  Expanded(
                                    child:
                                        ElevatedButton(
                                      onPressed:
                                          () {

                                        final nextStatus =
                                            status ==
                                                    "pending"
                                                ? "accepted"
                                                : "completed";

                                        updateStatus(
                                          doc.id,
                                          nextStatus,
                                        );
                                      },

                                      style:
                                          ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.green,

                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                            14,
                                          ),
                                        ),

                                        padding:
                                            const EdgeInsets.symmetric(
                                          vertical:
                                              14,
                                        ),
                                      ),

                                      child:
                                          Text(
                                        status ==
                                                "pending"
                                            ? "Accept"
                                            : "Complete",

                                        style:
                                            const TextStyle(
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
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ================= CHIP =================
  Widget _chip(String value) {

    final selected =
        filter == value;

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 6,
      ),

      child: ChoiceChip(
        label: Text(
          value.toUpperCase(),

          style: TextStyle(
            color: selected
                ? Colors.white
                : Colors.black87,

            fontWeight:
                FontWeight.w600,
          ),
        ),

        selected: selected,

        selectedColor:
            const Color(0xff2563eb),

        backgroundColor:
            Colors.white,

        elevation:
            selected ? 2 : 0,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            30,
          ),
        ),

        onSelected: (_) {

          setState(() {
            filter = value;
          });
        },
      ),
    );
  }

  /// ================= INFO TILE =================
  Widget _infoTile({

    required IconData icon,
    required String title,
    required String value,
  }) {

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Container(
          padding:
              const EdgeInsets.all(10),

          decoration: BoxDecoration(
            color:
                Colors.indigo.withOpacity(
              .08,
            ),

            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),

          child: Icon(
            icon,
            color: Colors.indigo,
            size: 20,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text(
                title,

                style: TextStyle(
                  color:
                      Colors.grey.shade600,

                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value.isEmpty
                    ? "-"
                    : value,

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w600,

                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}