import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../provider/provider_profile_page.dart';

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

  String searchQuery = "";

  /// ======================================================
  /// STATUS COLOR
  /// ======================================================

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

  /// ======================================================
  /// STATUS BG
  /// ======================================================

  Color getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return const Color(0xFFE9FCEF);

      case "rejected":
        return const Color(0xFFFEECEC);

      case "pending":
        return const Color(0xFFFFF5E5);

      default:
        return const Color(0xFFEEF2FF);
    }
  }

  /// ======================================================
  /// SERVICE ICON
  /// ======================================================

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

    if (value.contains("ac")) {
      return Icons.ac_unit_rounded;
    }

    return Icons
        .miscellaneous_services_rounded;
  }

  /// ======================================================
  /// UI
  /// ======================================================

  @override
  Widget build(BuildContext context) {
    final size =
        MediaQuery.of(context).size;

    final isTablet =
        size.width >= 700;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F7FC),

      body: SafeArea(
        child:
            StreamBuilder<QuerySnapshot>(
          stream:
              providersRef.snapshots(),
          builder:
              (context, snapshot) {
            /// ================= LOADING =================

            if (snapshot
                    .connectionState ==
                ConnectionState
                    .waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            /// ================= EMPTY =================

            if (!snapshot.hasData ||
                snapshot
                    .data!
                    .docs
                    .isEmpty) {
              return _emptyState();
            }

            List<QueryDocumentSnapshot>
                docs =
                snapshot.data!.docs;

            /// ================= SORT =================

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

            /// ================= SEARCH =================

            if (searchQuery.isNotEmpty) {
              docs =
                  docs.where((doc) {
                final data =
                    doc.data()
                        as Map<String,
                            dynamic>;

                final business =
                    data['business'] ??
                        {};

                final name =
                    (business[
                                    'businessName'] ??
                                "")
                            .toString()
                            .toLowerCase();

                final phone =
                    (business[
                                    'phone'] ??
                                "")
                            .toString()
                            .toLowerCase();

                return name.contains(
                      searchQuery
                          .toLowerCase(),
                    ) ||
                    phone.contains(
                      searchQuery
                          .toLowerCase(),
                    );
              }).toList();
            }

            /// ================= COUNTS =================

            final approved =
                docs.where((e) {
              final data =
                  e.data()
                      as Map<String,
                          dynamic>;

              return ((data['status'] ??
                              "")
                          .toString()
                          .toLowerCase() ==
                      "approved");
            }).length;

            final pending =
                docs.where((e) {
              final data =
                  e.data()
                      as Map<String,
                          dynamic>;

              return ((data['status'] ??
                              "")
                          .toString()
                          .toLowerCase() ==
                      "pending");
            }).length;

            final rejected =
                docs.where((e) {
              final data =
                  e.data()
                      as Map<String,
                          dynamic>;

              return ((data['status'] ??
                              "")
                          .toString()
                          .toLowerCase() ==
                      "rejected");
            }).length;

            return Column(
              children: [
                /// ======================================================
                /// HEADER
                /// ======================================================

                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.fromLTRB(
                    isTablet ? 28 : 18,
                    18,
                    isTablet ? 28 : 18,
                    26,
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
                      /// TOP BAR

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
                                .14,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),
                            child:
                                const Icon(
                              Icons
                                  .storefront_rounded,
                              color:
                                  Colors
                                      .white,
                              size: 30,
                            ),
                          ),

                          const SizedBox(
                              width: 16),

                          Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const Text(
                                  "Providers",
                                  style:
                                      TextStyle(
                                    color:
                                        Colors
                                            .white,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    fontSize:
                                        25,
                                  ),
                                ),

                                const SizedBox(
                                    height:
                                        4),

                                Text(
                                  "${docs.length} service providers registered",
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors
                                            .white70,
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
                          height: 24),

                      /// SEARCH

                      Container(
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .white
                              .withOpacity(
                            .15,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                        ),
                        child: TextField(
                          onChanged: (v) {
                            setState(() {
                              searchQuery =
                                  v;
                            });
                          },
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                          ),
                          decoration:
                              InputDecoration(
                            hintText:
                                "Search providers...",
                            hintStyle:
                                const TextStyle(
                              color:
                                  Colors
                                      .white70,
                            ),
                            prefixIcon:
                                const Icon(
                              Icons.search,
                              color:
                                  Colors.white,
                            ),
                            border:
                                InputBorder
                                    .none,
                            contentPadding:
                                const EdgeInsets.symmetric(
                              vertical:
                                  18,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 24),

                      /// STATS

                      Row(
                        children: [
                          Expanded(
                            child:
                                _topCard(
                              "Approved",
                              approved
                                  .toString(),
                              Icons
                                  .verified_rounded,
                            ),
                          ),

                          const SizedBox(
                              width:
                                  12),

                          Expanded(
                            child:
                                _topCard(
                              "Pending",
                              pending
                                  .toString(),
                              Icons
                                  .schedule_rounded,
                            ),
                          ),

                          const SizedBox(
                              width:
                                  12),

                          Expanded(
                            child:
                                _topCard(
                              "Rejected",
                              rejected
                                  .toString(),
                              Icons
                                  .cancel_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                /// ======================================================
                /// LIST
                /// ======================================================

                Expanded(
                  child:
                      ListView.builder(
                    padding:
                        EdgeInsets.all(
                      isTablet
                          ? 24
                          : 16,
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

                      final documents =
                          (data['documents']
                                  as Map<
                                      String,
                                      dynamic>?) ??
                              {};

                      /// VALUES

                      final String
                          providerId =
                          data['providerId'] ??
                              "";

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
                          email =
                          business[
                                  'email'] ??
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
                          address =
                          business[
                                  'address'] ??
                              "";

                      final String
                          pincode =
                          business[
                                  'pincode'] ??
                              "";

                      final String
                          image =
                          business[
                                  'image'] ??
                              "";

                      final String
                          providerType =
                          data[
                                  'providerType'] ??
                              "Provider";

                      final String
                          status =
                          data['status'] ??
                              "pending";

                      final String
                          serviceType =
                          data[
                                  'serviceType'] ??
                              "";

                      final bool
                          ownTools =
                          service[
                                  'ownTools'] ??
                              false;

                      final bool
                          isActive =
                          data['isActive'] ??
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

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProviderProfilePage(
                                providerId:
                                    providerId,
                              ),
                            ),
                          );
                        },
                        child: Container(
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
                            color:
                                Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              30,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors
                                    .black
                                    .withOpacity(
                                  .05,
                                ),
                                blurRadius:
                                    16,
                                offset:
                                    const Offset(
                                  0,
                                  8,
                                ),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              /// ======================================================
                              /// TOP
                              /// ======================================================

                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Container(
                                    width:
                                        82,
                                    height:
                                        82,
                                    decoration:
                                        BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(
                                        26,
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
                                                    36,
                                              )
                                            : null,
                                  ),

                                  const SizedBox(
                                      width:
                                          16),

                                  Expanded(
                                    child:
                                        Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child:
                                                  Text(
                                                businessName,
                                                maxLines:
                                                    1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style:
                                                    const TextStyle(
                                                  fontSize:
                                                      20,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                            ),

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
                                                    isActive
                                                        ? const Color(
                                                            0xFFE9FCEF,
                                                          )
                                                        : const Color(
                                                            0xFFF3F4F6,
                                                          ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  30,
                                                ),
                                              ),
                                              child:
                                                  Text(
                                                isActive
                                                    ? "ACTIVE"
                                                    : "INACTIVE",
                                                style:
                                                    TextStyle(
                                                  color:
                                                      isActive
                                                          ? const Color(
                                                              0xFF16A34A,
                                                            )
                                                          : Colors.grey,
                                                  fontSize:
                                                      11,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(
                                            height:
                                                6),

                                        Text(
                                          ownerName,
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
                                                12),

                                        Wrap(
                                          spacing:
                                              8,
                                          runSpacing:
                                              8,
                                          children: [
                                            _tag(
                                              status
                                                  .toUpperCase(),
                                              getStatusBg(
                                                status,
                                              ),
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

                              /// ======================================================
                              /// QUICK INFO
                              /// ======================================================

                              Container(
                                padding:
                                    const EdgeInsets.all(
                                  16,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                    0xFFF8FAFF,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                    24,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child:
                                              _infoTile(
                                            Icons
                                                .phone_rounded,
                                            "Phone",
                                            phone,
                                          ),
                                        ),

                                        const SizedBox(
                                            width:
                                                12),

                                        Expanded(
                                          child:
                                              _infoTile(
                                            Icons
                                                .email_rounded,
                                            "Email",
                                            email,
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
                                              _infoTile(
                                            Icons
                                                .location_city_rounded,
                                            "Location",
                                            "$city, $state",
                                          ),
                                        ),

                                        const SizedBox(
                                            width:
                                                12),

                                        Expanded(
                                          child:
                                              _infoTile(
                                            Icons
                                                .calendar_today_rounded,
                                            "Joined",
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
                                              _infoTile(
                                            Icons
                                                .build_circle_rounded,
                                            "Tools",
                                            ownTools
                                                ? "Available"
                                                : "Not Available",
                                          ),
                                        ),

                                        const SizedBox(
                                            width:
                                                12),

                                        Expanded(
                                          child:
                                              _infoTile(
                                            Icons
                                                .miscellaneous_services_rounded,
                                            "Service",
                                            serviceType
                                                    .isEmpty
                                                ? "-"
                                                : serviceType,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              /// ======================================================
                              /// ADDRESS
                              /// ======================================================

                              if (address
                                  .isNotEmpty) ...[
                                const SizedBox(
                                    height:
                                        18),

                                _sectionTitle(
                                  "Address",
                                ),

                                const SizedBox(
                                    height:
                                        12),

                                Container(
                                  width: double
                                      .infinity,
                                  padding:
                                      const EdgeInsets.all(
                                    16,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(
                                      22,
                                    ),
                                    border:
                                        Border.all(
                                      color: Colors
                                          .grey
                                          .shade200,
                                    ),
                                  ),
                                  child: Text(
                                    "$address, $city, $state - $pincode",
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                      height:
                                          1.5,
                                    ),
                                  ),
                                ),
                              ],

                              /// ======================================================
                              /// CATEGORIES
                              /// ======================================================

                              if (categories
                                  .isNotEmpty) ...[
                                const SizedBox(
                                    height:
                                        18),

                                _sectionTitle(
                                  "Categories",
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
                                      List.generate(
                                    categories
                                        .length,
                                    (i) {
                                      return Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal:
                                              14,
                                          vertical:
                                              9,
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
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            fontSize:
                                                12,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],

                              /// ======================================================
                              /// DOCUMENTS
                              /// ======================================================

                              if (documents
                                  .isNotEmpty) ...[
                                const SizedBox(
                                    height:
                                        20),

                                _sectionTitle(
                                  "Uploaded Documents",
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
                                      documents.keys
                                          .map(
                                            (
                                              doc,
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
                                                    0xFFE9FCEF,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    18,
                                                  ),
                                                ),
                                                child:
                                                    Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .verified_rounded,
                                                      color:
                                                          Color(
                                                        0xFF16A34A,
                                                      ),
                                                      size:
                                                          18,
                                                    ),

                                                    const SizedBox(
                                                        width:
                                                            8),

                                                    Text(
                                                      doc,
                                                      style:
                                                          const TextStyle(
                                                        color:
                                                            Color(
                                                          0xFF16A34A,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          )
                                          .toList(),
                                ),
                              ],

                              /// ======================================================
                              /// BANK
                              /// ======================================================

                              const SizedBox(
                                  height:
                                      20),

                              _sectionTitle(
                                "Bank Details",
                              ),

                              const SizedBox(
                                  height:
                                      12),

                              Container(
                                width: double
                                    .infinity,
                                padding:
                                    const EdgeInsets.all(
                                  18,
                                ),
                                decoration:
                                    BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(
                                    24,
                                  ),
                                  border:
                                      Border.all(
                                    color: Colors
                                        .grey
                                        .shade200,
                                  ),
                                ),
                                child: Column(
                                  children: [
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

                              const SizedBox(
                                  height:
                                      18),

                              /// ======================================================
                              /// BUTTON
                              /// ======================================================

                              SizedBox(
                                width: double
                                    .infinity,
                                height: 56,
                                child:
                                    ElevatedButton
                                        .icon(
                                  onPressed:
                                      () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ProviderProfilePage(
                                          providerId:
                                              providerId,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons
                                        .edit_rounded,
                                  ),
                                  label: const Text(
                                    "Open Provider Profile",
                                  ),
                                  style:
                                      ElevatedButton.styleFrom(
                                    elevation:
                                        0,
                                    backgroundColor:
                                        const Color(
                                      0xFF4F46E5,
                                    ),
                                    foregroundColor:
                                        Colors
                                            .white,
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                        18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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

  /// ======================================================
  /// TOP CARD
  /// ======================================================

  Widget _topCard(
    String title,
    String count,
    IconData icon,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(
          .14,
        ),
        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),

          const SizedBox(height: 10),

          Text(
            count,
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize: 26,
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
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// ======================================================
  /// TAG
  /// ======================================================

  Widget _tag(
    String text,
    Color bg,
    Color textColor,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius:
            BorderRadius.circular(
          30,
        ),
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

  /// ======================================================
  /// INFO TILE
  /// ======================================================

  Widget _infoTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
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
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color:
                    const Color(
                  0xFF4F46E5,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors
                        .grey
                        .shade600,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            value.isEmpty
                ? "-"
                : value,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// ======================================================
  /// SECTION TITLE
  /// ======================================================

  Widget _sectionTitle(
    String title,
  ) {
    return Align(
      alignment:
          Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color:
              Colors.grey.shade800,
          fontWeight:
              FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  /// ======================================================
  /// BANK ROW
  /// ======================================================

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
            width: 95,
            child: Text(
              title,
              style: TextStyle(
                color:
                    Colors.grey
                        .shade700,
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
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

  /// ======================================================
  /// EMPTY
  /// ======================================================

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFEEF2FF,
              ),
              borderRadius:
                  BorderRadius.circular(
                32,
              ),
            ),
            child: const Icon(
              Icons
                  .storefront_outlined,
              size: 50,
              color:
                  Color(0xFF4F46E5),
            ),
          ),

          const SizedBox(
              height: 20),

          const Text(
            "No Providers Found",
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
              height: 8),

          Text(
            "Registered providers will appear here",
            style: TextStyle(
              color:
                  Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}