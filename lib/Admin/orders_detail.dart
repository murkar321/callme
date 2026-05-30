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
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  String search = "";
  String filter = "all";

  final TextEditingController
      searchController =
      TextEditingController();

  /// ================= STREAM =================
  Stream<QuerySnapshot<Map<String, dynamic>>>
      ordersStream() {
    return firestore
        .collection("orders")
        .snapshots();
  }

  /// ================= STATUS COLOR =================
  Color getStatusColor(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case "accepted":
        return const Color(0xFF16A34A);

      case "completed":
        return const Color(0xFF2563EB);

      case "cancelled":
        return const Color(0xFFDC2626);

      case "rejected":
        return const Color(0xFFEF4444);

      default:
        return const Color(0xFFF59E0B);
    }
  }

  /// ================= STATUS ICON =================
  IconData getStatusIcon(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case "accepted":
        return Icons.check_circle;

      case "completed":
        return Icons.task_alt;

      case "cancelled":
        return Icons.cancel;

      case "rejected":
        return Icons.remove_circle;

      default:
        return Icons.pending_actions;
    }
  }

  /// ================= SERVICE ICON =================
  IconData getServiceIcon(
    String service,
  ) {
    final value =
        service.toLowerCase();

    if (value.contains(
      "laundry",
    )) {
      return Icons.local_laundry_service;
    }

    if (value.contains(
      "clean",
    )) {
      return Icons.cleaning_services;
    }

    if (value.contains(
      "electric",
    )) {
      return Icons.electrical_services;
    }

    if (value.contains(
      "plumb",
    )) {
      return Icons.plumbing;
    }

    if (value.contains(
      "salon",
    )) {
      return Icons.content_cut;
    }

    return Icons.miscellaneous_services;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF3F5FA),

      body: SafeArea(
        child: StreamBuilder<
            QuerySnapshot<
                Map<String, dynamic>>>(
          stream: ordersStream(),

          builder:
              (context, snapshot) {
            /// LOADING
            if (snapshot
                    .connectionState ==
                ConnectionState
                    .waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            /// ERROR
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),
                  child: Text(
                    snapshot.error
                        .toString(),

                    textAlign:
                        TextAlign.center,
                  ),
                ),
              );
            }

            /// EMPTY
            if (!snapshot.hasData ||
                snapshot
                    .data!
                    .docs
                    .isEmpty) {
              return _emptyState();
            }

            List<
                    QueryDocumentSnapshot<
                        Map<String,
                            dynamic>>>
                docs =
                snapshot.data!.docs;

            /// ================= SAFE SORT =================
            docs.sort((a, b) {
              final aTime =
                  a
                      .data()['createdAt'];
              final bTime =
                  b
                      .data()['createdAt'];

              if (aTime
                      is Timestamp &&
                  bTime
                      is Timestamp) {
                return bTime
                    .toDate()
                    .compareTo(
                      aTime.toDate(),
                    );
              }

              return 0;
            });

            /// ================= FILTER =================
            final filtered =
                docs.where((doc) {
              final data =
                  doc.data();

              final userName =
                  (data['userName'] ??
                          "")
                      .toString()
                      .toLowerCase();

              final email =
                  (data['email'] ??
                          "")
                      .toString()
                      .toLowerCase();

              final phone =
                  (data['phone'] ??
                          "")
                      .toString()
                      .toLowerCase();

              final service =
                  (data['serviceType'] ??
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

              final orderId =
                  (data['orderId'] ??
                          "")
                      .toString()
                      .toLowerCase();

              final matchesSearch =
                  userName.contains(
                        search,
                      ) ||
                      email.contains(
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
                      ) ||
                      orderId.contains(
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
                _buildHeader(
                  filtered.length,
                ),

                /// ================= LIST =================
                Expanded(
                  child: filtered
                          .isEmpty
                      ? _noMatch()
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(
                            14,
                            14,
                            14,
                            20,
                          ),

                          physics:
                              const BouncingScrollPhysics(),

                          itemCount:
                              filtered.length,

                          itemBuilder:
                              (
                            context,
                            index,
                          ) {
                            final data =
                                filtered[
                                        index]
                                    .data();

                            /// ================= DATA =================
                            final String
                                orderId =
                                data['orderId'] ??
                                    filtered[
                                            index]
                                        .id;

                            final String
                                userName =
                                data['userName'] ??
                                    "Unknown User";

                            final String
                                email =
                                data['email'] ??
                                    "-";

                            final String
                                phone =
                                data['phone'] ??
                                    "-";

                            final String
                                service =
                                data['serviceType'] ??
                                    "Service";

                            final String
                                providerName =
                                data['providerName'] ==
                                        ""
                                    ? "Not Assigned"
                                    : data[
                                        'providerName'];

                            final String
                                address =
                                data['address'] ??
                                    "-";

                            final String
                                status =
                                data['status'] ??
                                    "pending";

                            final bool
                                paid =
                                data['payment']?[
                                        'paid'] ??
                                    false;

                            final String
                                paymentMethod =
                                data['payment']?[
                                        'method'] ??
                                    "-";

                            final dynamic
                                amount =
                                data['totalAmount'] ??
                                    0;

                            final List
                                services =
                                data['services'] ??
                                    [];

                            final String
                                time =
                                data['schedule']?[
                                        'time'] ??
                                    data['time'] ??
                                    "-";

                            final Timestamp?
                                scheduleDate =
                                data['schedule']?[
                                    'date'];

                            final Timestamp?
                                createdAt =
                                data['createdAt'];

                            String visitDate =
                                "-";

                            if (scheduleDate !=
                                null) {
                              visitDate =
                                  DateFormat(
                                "dd MMM yyyy",
                              ).format(
                                scheduleDate
                                    .toDate(),
                              );
                            }

                            String createdDate =
                                "-";

                            if (createdAt !=
                                null) {
                              createdDate =
                                  DateFormat(
                                "dd MMM yyyy • hh:mm a",
                              ).format(
                                createdAt
                                    .toDate(),
                              );
                            }

                            return Container(
                              margin:
                                  const EdgeInsets.only(
                                bottom: 14,
                              ),

                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.white,

                                borderRadius:
                                    BorderRadius.circular(
                                  28,
                                ),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors
                                        .black
                                        .withOpacity(
                                      .05,
                                    ),

                                    blurRadius:
                                        18,

                                    offset:
                                        const Offset(
                                      0,
                                      8,
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
                                    /// ================= TOP =================
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,

                                      children: [
                                        Container(
                                          width:
                                              68,
                                          height:
                                              68,

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
                                              22,
                                            ),
                                          ),

                                          child:
                                              Icon(
                                            getServiceIcon(
                                              service,
                                            ),

                                            color:
                                                Colors.white,

                                            size:
                                                32,
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
                                                service
                                                    .toUpperCase(),

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
                                                      4),

                                              Text(
                                                userName,

                                                style:
                                                    TextStyle(
                                                  color:
                                                      Colors.grey.shade700,

                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),

                                              const SizedBox(
                                                  height:
                                                      10),

                                              Row(
                                                children: [
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
                                                          getStatusColor(
                                                        status,
                                                      ).withOpacity(
                                                        .12,
                                                      ),

                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        40,
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
                                                              14,

                                                          color:
                                                              getStatusColor(
                                                            status,
                                                          ),
                                                        ),

                                                        const SizedBox(
                                                            width:
                                                                5),

                                                        Text(
                                                          status.toUpperCase(),

                                                          style:
                                                              TextStyle(
                                                            color:
                                                                getStatusColor(
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

                                                  const SizedBox(
                                                      width:
                                                          8),

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
                                                      color: paid
                                                          ? Colors.green.withOpacity(
                                                              .12)
                                                          : Colors.red.withOpacity(
                                                              .12),

                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        40,
                                                      ),
                                                    ),

                                                    child:
                                                        Text(
                                                      paid
                                                          ? "PAID"
                                                          : "UNPAID",

                                                      style:
                                                          TextStyle(
                                                        color: paid
                                                            ? Colors.green
                                                            : Colors.red,

                                                        fontWeight:
                                                            FontWeight.bold,

                                                        fontSize:
                                                            11,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(
                                        height:
                                            18),

                                    /// ================= AMOUNT =================
                                    Container(
                                      width: double
                                          .infinity,

                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal:
                                            16,
                                        vertical:
                                            16,
                                      ),

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
                                          22,
                                        ),
                                      ),

                                      child:
                                          Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,

                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,

                                            children: [
                                              const Text(
                                                "Total Amount",

                                                style:
                                                    TextStyle(
                                                  color:
                                                      Colors.white70,

                                                  fontSize:
                                                      13,
                                                ),
                                              ),

                                              const SizedBox(
                                                  height:
                                                      4),

                                              Text(
                                                "₹${amount.toString()}",

                                                style:
                                                    const TextStyle(
                                                  color:
                                                      Colors.white,

                                                  fontWeight:
                                                      FontWeight.bold,

                                                  fontSize:
                                                      24,
                                                ),
                                              ),
                                            ],
                                          ),

                                          Container(
                                            padding:
                                                const EdgeInsets.all(
                                              14,
                                            ),

                                            decoration:
                                                BoxDecoration(
                                              color: Colors
                                                  .white
                                                  .withOpacity(
                                                .14,
                                              ),

                                              borderRadius:
                                                  BorderRadius.circular(
                                                18,
                                              ),
                                            ),

                                            child:
                                                const Icon(
                                              Icons
                                                  .payments_rounded,

                                              color:
                                                  Colors.white,

                                              size:
                                                  28,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(
                                        height:
                                            18),

                                    /// ================= INFO =================
                                    _infoCard(
                                      children: [
                                        _infoTile(
                                          Icons
                                              .phone,
                                          "Phone",
                                          phone,
                                        ),

                                        _infoTile(
                                          Icons
                                              .email,
                                          "Email",
                                          email,
                                        ),

                                        _infoTile(
                                          Icons
                                              .location_on,
                                          "Address",
                                          address,
                                        ),

                                        _infoTile(
                                          Icons
                                              .engineering,
                                          "Provider",
                                          providerName,
                                        ),

                                        _infoTile(
                                          Icons
                                              .schedule,
                                          "Visit Time",
                                          "$visitDate • $time",
                                        ),

                                        _infoTile(
                                          Icons
                                              .payments,
                                          "Payment",
                                          paymentMethod
                                              .toUpperCase(),
                                        ),

                                        _infoTile(
                                          Icons
                                              .receipt_long,
                                          "Order ID",
                                          orderId,
                                        ),

                                        _infoTile(
                                          Icons
                                              .calendar_month,
                                          "Created",
                                          createdDate,
                                        ),
                                      ],
                                    ),

                                    /// ================= SERVICES =================
                                    if (services
                                        .isNotEmpty) ...[
                                      const SizedBox(
                                          height:
                                              18),

                                      const Text(
                                        "Selected Services",

                                        style:
                                            TextStyle(
                                          fontSize:
                                              15,

                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(
                                          height:
                                              12),

                                      Wrap(
                                        spacing:
                                            10,
                                        runSpacing:
                                            10,

                                        children:
                                            services.map(
                                          (
                                            item,
                                          ) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal:
                                                    14,
                                                vertical:
                                                    10,
                                              ),

                                              decoration:
                                                  BoxDecoration(
                                                color:
                                                    const Color(
                                                  0xFFF3F4FF,
                                                ),

                                                borderRadius:
                                                    BorderRadius.circular(
                                                  40,
                                                ),
                                              ),

                                              child:
                                                  Text(
                                                item
                                                    .toString(),

                                                style:
                                                    const TextStyle(
                                                  color:
                                                      Color(
                                                    0xFF4F46E5,
                                                  ),

                                                  fontWeight:
                                                      FontWeight.w700,

                                                  fontSize:
                                                      12,
                                                ),
                                              ),
                                            );
                                          },
                                        ).toList(),
                                      ),
                                    ],
                                  ],
                                ),
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

  /// ================= HEADER =================
  Widget _buildHeader(
    int count,
  ) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        22,
      ),

      decoration:
          const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF7C3AED),
          ],

          begin: Alignment.topLeft,
          end:
              Alignment.bottomRight,
        ),

        borderRadius:
            BorderRadius.only(
          bottomLeft:
              Radius.circular(
            32,
          ),
          bottomRight:
              Radius.circular(
            32,
          ),
        ),
      ),

      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,

                decoration:
                    BoxDecoration(
                  color: Colors.white
                      .withOpacity(
                    .14,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    18,
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
                        color:
                            Colors
                                .white,

                        fontWeight:
                            FontWeight
                                .bold,

                        fontSize: 23,
                      ),
                    ),

                    const SizedBox(
                        height: 4),

                    Text(
                      "$count orders available",

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
            height: 58,

            decoration:
                BoxDecoration(
              color: Colors.white,

              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),

            child: TextField(
              controller:
                  searchController,

              onChanged: (
                value,
              ) {
                setState(() {
                  search = value
                      .trim()
                      .toLowerCase();
                });
              },

              decoration:
                  InputDecoration(
                border:
                    InputBorder.none,

                hintText:
                    "Search order, user or service",

                prefixIcon:
                    const Icon(
                  Icons.search,
                ),

                suffixIcon:
                    search.isNotEmpty
                        ? IconButton(
                            onPressed:
                                () {
                              searchController
                                  .clear();

                              setState(
                                () {
                                  search =
                                      "";
                                },
                              );
                            },

                            icon:
                                const Icon(
                              Icons.close,
                            ),
                          )
                        : null,

                contentPadding:
                    const EdgeInsets.symmetric(
                  vertical: 18,
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
                _chip("cancelled"),
                _chip("rejected"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ================= CHIP =================
  Widget _chip(
    String value,
  ) {
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
                FontWeight.w700,

            fontSize: 12,
          ),
        ),

        selected: selected,

        backgroundColor:
            Colors.white,

        selectedColor:
            const Color(
          0xFF2563EB,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            40,
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

  /// ================= INFO CARD =================
  Widget _infoCard({
    required List<Widget>
        children,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFF8FAFC,
        ),

        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),

      child: Column(
        children: children
            .map(
              (
                e,
              ) => Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 14,
                ),
                child: e,
              ),
            )
            .toList(),
      ),
    );
  }

  /// ================= INFO TILE =================
  Widget _infoTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Container(
          padding:
              const EdgeInsets.all(
            10,
          ),

          decoration:
              BoxDecoration(
            color: Colors.white,

            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),

          child: Icon(
            icon,

            size: 18,

            color:
                const Color(
              0xFF4F46E5,
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
                title,

                style:
                    TextStyle(
                  color: Colors
                      .grey
                      .shade600,

                  fontSize: 12,
                ),
              ),

              const SizedBox(
                  height: 2),

              Text(
                value.isEmpty
                    ? "-"
                    : value,

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w700,

                  fontSize: 13,

                  height: 1.4,
                ),
              ),
            ],
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
            MainAxisAlignment
                .center,

        children: [
          Container(
            width: 95,
            height: 95,

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFEEF2FF,
              ),

              borderRadius:
                  BorderRadius.circular(
                30,
              ),
            ),

            child: const Icon(
              Icons
                  .shopping_bag_outlined,

              size: 42,

              color:
                  Color(
                0xFF4F46E5,
              ),
            ),
          ),

          const SizedBox(
              height: 18),

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
            MainAxisAlignment
                .center,

        children: [
          Icon(
            Icons.search_off,

            size: 52,

            color:
                Colors.grey.shade400,
          ),

          const SizedBox(
              height: 12),

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