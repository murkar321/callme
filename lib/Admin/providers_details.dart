import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProvidersPage extends StatefulWidget {
  const ProvidersPage({super.key});

  @override
  State<ProvidersPage> createState() =>
      _ProvidersPageState();
}

class _ProvidersPageState
    extends State<ProvidersPage> {
  final CollectionReference providersRef =
      FirebaseFirestore.instance
          .collection("providers");

  /// ================= STATUS COLOR =================
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return const Color(0xFF16A34A);

      case "rejected":
        return const Color(0xFFDC2626);

      case "pending":
        return const Color(0xFFF59E0B);

      default:
        return const Color(0xFF4F46E5);
    }
  }

  /// ================= SERVICE ICON =================
  IconData getServiceIcon(
    String service,
  ) {
    final value =
        service.toLowerCase();

    if (value.contains("water")) {
      return Icons.water_drop_rounded;
    }

    if (value.contains("clean")) {
      return Icons
          .cleaning_services_rounded;
    }

    if (value.contains("electric")) {
      return Icons
          .electrical_services_rounded;
    }

    if (value.contains("plumb")) {
      return Icons.plumbing_rounded;
    }

    if (value.contains("salon")) {
      return Icons.content_cut_rounded;
    }

    return Icons
        .miscellaneous_services_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FB),

      body: SafeArea(
        child:
            StreamBuilder<QuerySnapshot>(
          stream:
              providersRef.snapshots(),

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

            /// EMPTY
            if (!snapshot.hasData ||
                snapshot
                    .data!
                    .docs
                    .isEmpty) {
              return _emptyState();
            }

            final docs =
                snapshot.data!.docs;

            /// SORT BY DATE
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

            /// COUNTS
            final approved =
                docs.where((e) {
              final data =
                  e.data()
                      as Map<String, dynamic>;

              return ((data['status'] ??
                              "")
                          .toString()
                          .toLowerCase() ==
                      "approved") ||
                  (((data['profile']
                                  as Map?)?[
                              'status'] ??
                          "")
                      .toString()
                      .toLowerCase() ==
                      "approved");
            }).length;

            final pending =
                docs.where((e) {
              final data =
                  e.data()
                      as Map<String, dynamic>;

              return ((data['status'] ??
                              "")
                          .toString()
                          .toLowerCase() ==
                      "pending") ||
                  (((data['profile']
                                  as Map?)?[
                              'status'] ??
                          "")
                      .toString()
                      .toLowerCase() ==
                      "pending");
            }).length;

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
                          Alignment
                              .topLeft,

                      end:
                          Alignment
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
                            width: 54,
                            height: 54,

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
                                  .storefront_rounded,

                              color:
                                  Colors
                                      .white,

                              size: 28,
                            ),
                          ),

                          const SizedBox(
                              width: 14),

                          Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [
                                const Text(
                                  "Service Providers",

                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white,
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize:
                                        22,
                                  ),
                                ),

                                const SizedBox(
                                    height:
                                        4),

                                Text(
                                  "${docs.length} registered providers",

                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white70,
                                    fontSize:
                                        13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                          height: 22),

                      /// STATS
                      Row(
                        children: [
                          Expanded(
                            child:
                                _topCard(
                              title:
                                  "Approved",
                              count:
                                  approved
                                      .toString(),
                            ),
                          ),

                          const SizedBox(
                              width:
                                  12),

                          Expanded(
                            child:
                                _topCard(
                              title:
                                  "Pending",
                              count:
                                  pending
                                      .toString(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                /// ================= LIST =================
                Expanded(
                  child:
                      ListView.builder(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),

                    itemCount:
                        docs.length,

                    itemBuilder:
                        (_, index) {
                      final doc =
                          docs[index];

                      final data =
                          doc.data()
                              as Map<
                                  String,
                                  dynamic>;

                      /// MAPS
                      final business =
                          (data['business']
                                  as Map<
                                      String,
                                      dynamic>?) ??
                              {};

                      final bank =
                          (data['bank']
                                  as Map<
                                      String,
                                      dynamic>?) ??
                              {};

                      final service =
                          (data['service']
                                  as Map<
                                      String,
                                      dynamic>?) ??
                              {};

                      final profile =
                          (data['profile']
                                  as Map<
                                      String,
                                      dynamic>?) ??
                              {};

                      /// VALUES
                      final String
                          businessName =
                          business[
                                  'businessName'] ??
                              "No Name";

                      final String
                          ownerName =
                          business[
                                  'ownerName'] ??
                              "";

                      final String
                          phone =
                          business[
                                  'phone'] ??
                              "";

                      final String
                          city =
                          business[
                                  'city'] ??
                              "";

                      final String
                          state =
                          business[
                                  'state'] ??
                              "";

                      final String
                          image =
                          business[
                                  'image'] ??
                              "";

                      final String
                          providerType =
                          profile[
                                  'providerType'] ??
                              data[
                                  'providerType'] ??
                              "Provider";

                      final String
                          status =
                          profile[
                                  'status'] ??
                              data[
                                  'status'] ??
                              "pending";

                      final String
                          serviceType =
                          service[
                                  'serviceType'] ??
                              "";

                      final bool
                          ownTools =
                          service[
                                  'ownTools'] ??
                              false;

                      final List
                          categories =
                          List.from(
                        data['categories'] ??
                            [],
                      );

                      final Timestamp?
                          createdAt =
                          data[
                              'createdAt'];

                      String joined =
                          "-";

                      if (createdAt !=
                          null) {
                        joined =
                            DateFormat(
                          'dd MMM yyyy',
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
                            26,
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
                                5,
                              ),
                            ),
                          ],
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
                                      74,
                                  height:
                                      74,

                                  decoration:
                                      BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(
                                      24,
                                    ),

                                    image: image
                                            .isNotEmpty
                                        ? DecorationImage(
                                            image:
                                                NetworkImage(
                                              image,
                                            ),

                                            fit:
                                                BoxFit.cover,
                                          )
                                        : null,

                                    gradient:
                                        image.isEmpty
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(
                                                    0xFF2563EB,
                                                  ),
                                                  Color(
                                                    0xFF7C3AED,
                                                  ),
                                                ],
                                              )
                                            : null,
                                  ),

                                  child:
                                      image.isEmpty
                                          ? Icon(
                                              getServiceIcon(
                                                serviceType,
                                              ),

                                              color:
                                                  Colors.white,

                                              size:
                                                  34,
                                            )
                                          : null,
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
                                        businessName,

                                        maxLines:
                                            1,

                                        overflow:
                                            TextOverflow.ellipsis,

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
                                        ownerName,

                                        maxLines:
                                            1,

                                        overflow:
                                            TextOverflow.ellipsis,

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

                                      Wrap(
                                        spacing:
                                            8,
                                        runSpacing:
                                            8,

                                        children: [
                                          _tag(
                                            status
                                                .toUpperCase(),

                                            getStatusColor(
                                              status,
                                            ).withOpacity(
                                                .10),

                                            getStatusColor(
                                              status,
                                            ),
                                          ),

                                          _tag(
                                            providerType,

                                            const Color(
                                              0xFFEEF2FF,
                                            ),

                                            const Color(
                                              0xFF4F46E5,
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

                            /// ================= INFO BOX =================
                            Container(
                              padding:
                                  const EdgeInsets.all(
                                14,
                              ),

                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFF7F8FD,
                                ),

                                borderRadius:
                                    BorderRadius.circular(
                                  20,
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
                                              .calendar_today_rounded,

                                          joined,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                      height:
                                          14),

                                  Row(
                                    children: [
                                      Expanded(
                                        child:
                                            _compactInfo(
                                          Icons
                                              .location_on_rounded,

                                          "$city, $state",
                                        ),
                                      ),

                                      const SizedBox(
                                          width:
                                              12),

                                      Expanded(
                                        child:
                                            _compactInfo(
                                          Icons
                                              .build_circle_rounded,

                                          ownTools
                                              ? "Own Tools"
                                              : "No Tools",
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                      height:
                                          14),

                                  _compactInfo(
                                    Icons
                                        .miscellaneous_services_rounded,

                                    serviceType,
                                  ),
                                ],
                              ),
                            ),

                            /// ================= CATEGORIES =================
                            if (categories
                                .isNotEmpty) ...[
                              const SizedBox(
                                  height:
                                      18),

                              Text(
                                "Categories",

                                style:
                                    TextStyle(
                                  color: Colors
                                      .grey
                                      .shade700,

                                  fontWeight:
                                      FontWeight
                                          .w600,

                                  fontSize:
                                      14,
                                ),
                              ),

                              const SizedBox(
                                  height:
                                      12),

                              Wrap(
                                spacing:
                                    8,
                                runSpacing:
                                    8,

                                children:
                                    List.generate(
                                  categories
                                      .length,

                                  (i) {
                                    return Container(
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
                                          0xFFEEF2FF,
                                        ),

                                        borderRadius:
                                            BorderRadius.circular(
                                          30,
                                        ),
                                      ),

                                      child:
                                          Text(
                                        categories[
                                                i]
                                            .toString(),

                                        style:
                                            const TextStyle(
                                          color:
                                              Color(
                                            0xFF4F46E5,
                                          ),

                                          fontSize:
                                              12,

                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],

                            const SizedBox(
                                height:
                                    18),

                            /// ================= BANK =================
                            Container(
                              width: double
                                  .infinity,

                              padding:
                                  const EdgeInsets.all(
                                16,
                              ),

                              decoration:
                                  BoxDecoration(
                                border:
                                    Border.all(
                                  color:
                                      Colors
                                          .grey
                                          .shade200,
                                ),

                                borderRadius:
                                    BorderRadius.circular(
                                  20,
                                ),
                              ),

                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons
                                            .account_balance_rounded,

                                        size:
                                            18,

                                        color:
                                            Color(
                                          0xFF4F46E5,
                                        ),
                                      ),

                                      SizedBox(
                                          width:
                                              8),

                                      Text(
                                        "Bank Details",

                                        style:
                                            TextStyle(
                                          fontWeight:
                                              FontWeight.bold,

                                          fontSize:
                                              15,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                      height:
                                          16),

                                  _bankRow(
                                    "Holder",
                                    bank['accountHolder'] ??
                                        "-",
                                  ),

                                  _bankRow(
                                    "Account",
                                    bank['accountNumber'] ??
                                        "-",
                                  ),

                                  _bankRow(
                                    "IFSC",
                                    bank['ifsc'] ??
                                        "-",
                                  ),

                                  _bankRow(
                                    "UPI",
                                    bank['upi'] ??
                                        "-",
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

  /// ================= TAG =================
  Widget _tag(
    String text,
    Color bg,
    Color textColor,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: bg,

        borderRadius:
            BorderRadius.circular(30),
      ),

      child: Text(
        text,

        style: TextStyle(
          color: textColor,

          fontWeight:
              FontWeight.bold,

          fontSize: 11,
        ),
      ),
    );
  }

  /// ================= TOP CARD =================
  Widget _topCard({
    required String title,
    required String count,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 16,
      ),

      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(
          .14,
        ),

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Column(
        children: [
          Text(
            count,

            style:
                const TextStyle(
              color:
                  Colors.white,

              fontSize: 24,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,

            style:
                const TextStyle(
              color:
                  Colors.white70,

              fontSize: 13,
            ),
          ),
        ],
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

            color:
                const Color(
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
                  TextOverflow
                      .ellipsis,

              style:
                  const TextStyle(
                fontSize: 13,

                fontWeight:
                    FontWeight.w600,

                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ================= BANK ROW =================
  Widget _bankRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),

      child: Row(
        children: [
          SizedBox(
            width: 90,

            child: Text(
              title,

              style: TextStyle(
                color:
                    Colors.grey
                        .shade700,

                fontSize: 13,

                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value.isEmpty
                  ? "-"
                  : value,

              overflow:
                  TextOverflow
                      .ellipsis,

              style:
                  const TextStyle(
                fontSize: 13,

                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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
            width: 90,
            height: 90,

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFEEF2FF,
              ),

              borderRadius:
                  BorderRadius.circular(
                28,
              ),
            ),

            child: const Icon(
              Icons
                  .storefront_outlined,

              size: 42,

              color:
                  Color(0xFF4F46E5),
            ),
          ),

          const SizedBox(
              height: 18),

          const Text(
            "No Providers Found",

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
}