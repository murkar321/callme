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
        return const Color(0xFF16A34A);

      case "completed":
        return const Color(0xFF2563EB);

      case "rejected":
        return const Color(0xFFDC2626);

      case "cancelled":
        return const Color(0xFFEF4444);

      default:
        return const Color(0xFFF59E0B);
    }
  }

  /// ================= STATUS ICON =================
  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case "accepted":
        return Icons.check_circle_rounded;

      case "completed":
        return Icons.task_alt_rounded;

      case "rejected":
        return Icons.cancel_rounded;

      case "cancelled":
        return Icons.remove_circle_rounded;

      default:
        return Icons.pending_actions_rounded;
    }
  }

  /// ================= SERVICE ICON =================
  IconData getServiceIcon(String service) {
    final value = service.toLowerCase();

    if (value.contains("clean")) {
      return Icons.cleaning_services_rounded;
    }

    if (value.contains("electric")) {
      return Icons.electrical_services_rounded;
    }

    if (value.contains("plumb")) {
      return Icons.plumbing_rounded;
    }

    if (value.contains("water")) {
      return Icons.water_drop_rounded;
    }

    if (value.contains("salon")) {
      return Icons.content_cut_rounded;
    }

    return Icons.miscellaneous_services_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FB),

      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: ordersRef.snapshots(),

          builder: (context, snapshot) {
            /// LOADING
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            /// EMPTY
            if (!snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {
              return _emptyState();
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
                      as Map<String, dynamic>;

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

            return Column(
              children: [
                /// ================= HEADER =================
                Container(
                  padding:
                      const EdgeInsets.fromLTRB(
                    18,
                    18,
                    18,
                    24,
                  ),

                  decoration:
                      const BoxDecoration(
                    gradient:
                        LinearGradient(
                      colors: [
                        Color(
                          0xFF2563EB,
                        ),
                        Color(
                          0xFF7C3AED,
                        ),
                      ],

                      begin:
                          Alignment.topLeft,

                      end: Alignment
                          .bottomRight,
                    ),

                    borderRadius:
                        BorderRadius.only(
                      bottomLeft:
                          Radius.circular(
                        30,
                      ),
                      bottomRight:
                          Radius.circular(
                        30,
                      ),
                    ),
                  ),

                  child: Column(
                    children: [
                      /// TOP BAR
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,

                            decoration:
                                BoxDecoration(
                              color: Colors
                                  .white
                                  .withOpacity(
                                .14,
                              ),

                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                            ),

                            child: const Icon(
                              Icons
                                  .shopping_bag_rounded,

                              color:
                                  Colors.white,
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
                                const Text(
                                  "Orders Dashboard",

                                  style:
                                      TextStyle(
                                    color: Colors
                                        .white,

                                    fontWeight:
                                        FontWeight
                                            .bold,

                                    fontSize: 22,
                                  ),
                                ),

                                const SizedBox(
                                    height: 4),

                                Text(
                                  "${filtered.length} available orders",

                                  style:
                                      const TextStyle(
                                    color: Colors
                                        .white70,

                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                          height: 22),

                      /// SEARCH
                      Container(
                        decoration:
                            BoxDecoration(
                          color: Colors.white,

                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
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
                                "Search customer, provider or service",

                            border:
                                InputBorder.none,

                            prefixIcon: Icon(
                              Icons
                                  .search_rounded,
                            ),

                            contentPadding:
                                EdgeInsets.symmetric(
                              vertical: 17,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 18),

                      /// FILTERS
                      SizedBox(
                        height: 42,

                        child: ListView(
                          scrollDirection:
                              Axis.horizontal,

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
                    ],
                  ),
                ),

                /// ================= LIST =================
                Expanded(
                  child: filtered.isEmpty
                      ? _noMatch()
                      : ListView.builder(
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
                                    as Map<
                                        String,
                                        dynamic>;

                            final String
                                status =
                                data['status'] ??
                                    "pending";

                            final String
                                service =
                                data['serviceName'] ??
                                    data['serviceType'] ??
                                    "Service";

                            final String
                                customer =
                                data['customerName'] ??
                                    "Unknown";

                            final String
                                phone =
                                data['customerPhone'] ??
                                    "-";

                            final String
                                provider =
                                data['providerName'] ??
                                    "Not Assigned";

                            final String
                                address =
                                data['address'] ??
                                    "-";

                            final Timestamp?
                                createdAt =
                                data['createdAt'];

                            String date =
                                "-";

                            if (createdAt !=
                                null) {
                              date =
                                  DateFormat(
                                'dd MMM yyyy • hh:mm a',
                              ).format(
                                createdAt
                                    .toDate(),
                              );
                            }

                            return Container(
                              margin:
                                  const EdgeInsets.only(
                                bottom: 18,
                              ),

                              padding:
                                  const EdgeInsets.all(
                                16,
                              ),

                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.white,

                                borderRadius:
                                    BorderRadius.circular(
                                  24,
                                ),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors
                                        .black
                                        .withOpacity(
                                      .04,
                                    ),

                                    blurRadius:
                                        14,

                                    offset:
                                        const Offset(
                                      0,
                                      6,
                                    ),
                                  ),
                                ],
                              ),

                              child: Column(
                                children: [
                                  /// TOP
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,

                                    children: [
                                      Container(
                                        width: 68,
                                        height: 68,

                                        decoration:
                                            BoxDecoration(
                                          gradient:
                                              const LinearGradient(
                                            colors: [
                                              Color(
                                                0xFF2563EB,
                                              ),
                                              Color(
                                                0xFF7C3AED,
                                              ),
                                            ],
                                          ),

                                          borderRadius:
                                              BorderRadius.circular(
                                            20,
                                          ),
                                        ),

                                        child: Icon(
                                          getServiceIcon(
                                            service,
                                          ),

                                          color: Colors
                                              .white,

                                          size: 32,
                                        ),
                                      ),

                                      const SizedBox(
                                          width:
                                              14),

                                      Expanded(
                                        child:
                                            Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,

                                          children: [
                                            Text(
                                              service,

                                              maxLines:
                                                  1,

                                              overflow:
                                                  TextOverflow
                                                      .ellipsis,

                                              style:
                                                  const TextStyle(
                                                fontSize:
                                                    18,

                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),

                                            const SizedBox(
                                                height:
                                                    5),

                                            Text(
                                              customer,

                                              style:
                                                  TextStyle(
                                                color: Colors
                                                    .grey
                                                    .shade700,

                                                fontSize:
                                                    14,
                                              ),
                                            ),

                                            const SizedBox(
                                                height:
                                                    10),

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
                                                ).withOpacity(
                                                  .10,
                                                ),

                                                borderRadius:
                                                    BorderRadius.circular(
                                                  30,
                                                ),
                                              ),

                                              child:
                                                  Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,

                                                children: [
                                                  Icon(
                                                    getStatusIcon(
                                                      status,
                                                    ),

                                                    size:
                                                        15,

                                                    color:
                                                        getColor(
                                                      status,
                                                    ),
                                                  ),

                                                  const SizedBox(
                                                      width:
                                                          6),

                                                  Text(
                                                    status.toUpperCase(),

                                                    style:
                                                        TextStyle(
                                                      color:
                                                          getColor(
                                                        status,
                                                      ),

                                                      fontWeight:
                                                          FontWeight.bold,

                                                      fontSize:
                                                          11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                      height:
                                          18),

                                  /// INFO BOX
                                  Container(
                                    padding:
                                        const EdgeInsets.all(
                                      14,
                                    ),

                                    decoration:
                                        BoxDecoration(
                                      color:
                                          const Color(
                                        0xFFF8FAFC,
                                      ),

                                      borderRadius:
                                          BorderRadius.circular(
                                        18,
                                      ),
                                    ),

                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child:
                                                  _compactInfo(
                                                Icons
                                                    .phone_rounded,
                                                phone,
                                              ),
                                            ),

                                            const SizedBox(
                                                width:
                                                    12),

                                            Expanded(
                                              child:
                                                  _compactInfo(
                                                Icons
                                                    .engineering_rounded,
                                                provider,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(
                                            height:
                                                14),

                                        _compactInfo(
                                          Icons
                                              .location_on_rounded,
                                          address,
                                        ),

                                        const SizedBox(
                                            height:
                                                14),

                                        _compactInfo(
                                          Icons
                                              .calendar_month_rounded,
                                          date,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// ================= CHIP =================
  Widget _chip(String value) {
    final selected =
        filter == value;

    return Padding(
      padding:
          const EdgeInsets.only(
        right: 10,
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

            fontSize: 12,
          ),
        ),

        selected: selected,

        selectedColor:
            const Color(0xFF2563EB),

        backgroundColor:
            Colors.white,

        elevation:
            selected ? 1 : 0,

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

  /// ================= COMPACT INFO =================
  Widget _compactInfo(
    IconData icon,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Container(
          padding:
              const EdgeInsets.all(8),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),

          child: Icon(
            icon,

            size: 16,

            color: const Color(
              0xFF4F46E5,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(
              top: 2,
            ),

            child: Text(
              value.isEmpty
                  ? "-"
                  : value,

              maxLines: 2,

              overflow:
                  TextOverflow.ellipsis,

              style:
                  const TextStyle(
                fontSize: 13,

                fontWeight:
                    FontWeight.w600,

                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ================= EMPTY =================
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Container(
            width: 92,
            height: 92,

            decoration:
                BoxDecoration(
              color: const Color(
                0xFFEEF2FF,
              ),

              borderRadius:
                  BorderRadius.circular(
                28,
              ),
            ),

            child: const Icon(
              Icons.shopping_bag_outlined,

              size: 42,

              color: Color(
                0xFF4F46E5,
              ),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            "No Orders Found",

            style: TextStyle(
              fontSize: 18,

              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// ================= NO MATCH =================
  Widget _noMatch() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Icon(
            Icons.search_off_rounded,

            size: 52,

            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 14),

          Text(
            "No Matching Orders",

            style: TextStyle(
              color:
                  Colors.grey.shade700,

              fontWeight:
                  FontWeight.w600,

              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}