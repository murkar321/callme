import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ApproveProvidersPage extends StatefulWidget {
  const ApproveProvidersPage({super.key});

  @override
  State<ApproveProvidersPage> createState() =>
      _ApproveProvidersPageState();
}

class _ApproveProvidersPageState
    extends State<ApproveProvidersPage> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  String search = "";

  /// ================= STREAM =================
  Stream<QuerySnapshot> pendingProvidersStream() {
    return firestore
        .collection("providers")
        .where(
          "status",
          isEqualTo: "pending",
        )
        .snapshots();
  }

  /// ================= APPROVE =================
  Future<void> approveProvider(
    String providerId,
  ) async {
    try {
      await firestore
          .collection("providers")
          .doc(providerId)
          .update({
        "status": "approved",
        "isActive": true,
        "updatedAt":
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,

          backgroundColor:
              const Color(0xFF16A34A),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),

          content: const Text(
            "Provider approved successfully",
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text("$e"),
        ),
      );
    }
  }

  /// ================= REJECT =================
  Future<void> rejectProvider(
    String providerId,
  ) async {
    String reason = "";

    await showDialog(
      context: context,

      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              28,
            ),
          ),

          child: Padding(
            padding:
                const EdgeInsets.all(22),

            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                Container(
                  width: 62,
                  height: 62,

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.red.withOpacity(
                      .10,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),

                  child: const Icon(
                    Icons.close_rounded,

                    color: Colors.red,

                    size: 30,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  "Reject Provider",

                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Provide a reason for rejection",

                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 22),

                TextField(
                  maxLines: 4,

                  decoration:
                      InputDecoration(
                    hintText:
                        "Enter rejection reason",

                    filled: true,

                    fillColor:
                        const Color(
                      0xFFF5F7FB,
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

                  onChanged: (value) {
                    reason = value;
                  },
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child:
                          OutlinedButton(
                        onPressed: () {
                          Navigator.pop(
                            ctx,
                          );
                        },

                        style:
                            OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 15,
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),

                        child:
                            const Text(
                          "Cancel",
                        ),
                      ),
                    ),

                    const SizedBox(
                        width: 12),

                    Expanded(
                      child:
                          ElevatedButton(
                        onPressed:
                            () async {
                          try {
                            await firestore
                                .collection(
                                    "providers")
                                .doc(
                                  providerId,
                                )
                                .update({
                              "status":
                                  "rejected",

                              "rejectReason":
                                  reason,

                              "isActive":
                                  false,

                              "updatedAt":
                                  FieldValue
                                      .serverTimestamp(),
                            });

                            if (!mounted) {
                              return;
                            }

                            Navigator.pop(
                              ctx,
                            );

                            ScaffoldMessenger.of(
                                    context)
                                .showSnackBar(
                              SnackBar(
                                behavior:
                                    SnackBarBehavior.floating,

                                backgroundColor:
                                    Colors.red,

                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    16,
                                  ),
                                ),

                                content:
                                    const Text(
                                  "Provider rejected",
                                ),
                              ),
                            );
                          } catch (e) {
                            Navigator.pop(
                              ctx,
                            );

                            ScaffoldMessenger.of(
                                    context)
                                .showSnackBar(
                              SnackBar(
                                content:
                                    Text("$e"),
                              ),
                            );
                          }
                        },

                        style:
                            ElevatedButton.styleFrom(
                          elevation: 0,

                          backgroundColor:
                              Colors.red,

                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 15,
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),

                        child:
                            const Text(
                          "Reject",

                          style:
                              TextStyle(
                            color:
                                Colors.white,
                            fontWeight:
                                FontWeight.bold,
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

  /// ================= SERVICE ICON =================
  IconData getServiceIcon(
    String service,
  ) {
    final value =
        service.toLowerCase();

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

    if (value.contains("water")) {
      return Icons.water_drop_rounded;
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
              pendingProvidersStream(),

          builder:
              (context, snapshot) {
            /// LOADING
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            /// ERROR
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error: ${snapshot.error}",
                ),
              );
            }

            final docs =
                snapshot.data?.docs ?? [];

            /// SEARCH FILTER
            final filtered =
                docs.where((doc) {
              final data =
                  doc.data()
                      as Map<String, dynamic>;

              final business =
                  (data['business']
                          as Map<
                              String,
                              dynamic>?) ??
                      {};

              final businessName =
                  (business['businessName'] ??
                          "")
                      .toString()
                      .toLowerCase();

              final owner =
                  (business['ownerName'] ??
                          "")
                      .toString()
                      .toLowerCase();

              final phone =
                  (business['phone'] ??
                          "")
                      .toString()
                      .toLowerCase();

              return businessName
                      .contains(
                    search,
                  ) ||
                  owner.contains(
                    search,
                  ) ||
                  phone.contains(
                    search,
                  );
            }).toList();

            /// EMPTY
            if (docs.isEmpty) {
              return _emptyState();
            }

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

                            child: const Icon(
                              Icons
                                  .verified_user_rounded,

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
                                  "Provider Approvals",

                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white,

                                    fontWeight:
                                        FontWeight.bold,

                                    fontSize: 22,
                                  ),
                                ),

                                const SizedBox(
                                    height:
                                        4),

                                Text(
                                  "${filtered.length} pending requests",

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

                      /// SEARCH
                      Container(
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,

                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                        ),

                        child: TextField(
                          onChanged:
                              (value) {
                            setState(() {
                              search = value
                                  .toLowerCase();
                            });
                          },

                          decoration:
                              const InputDecoration(
                            hintText:
                                "Search business, owner or phone",

                            border:
                                InputBorder.none,

                            prefixIcon:
                                Icon(
                              Icons
                                  .search_rounded,
                            ),

                            contentPadding:
                                EdgeInsets.symmetric(
                              vertical:
                                  17,
                            ),
                          ),
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

                            final categories =
                                List.from(
                              data['categories'] ??
                                  [],
                            );

                            final Timestamp?
                                createdAt =
                                data[
                                    'createdAt'];

                            final providerId =
                                doc.id;

                            final businessName =
                                business[
                                        'businessName'] ??
                                    "No Name";

                            final ownerName =
                                business[
                                        'ownerName'] ??
                                    "-";

                            final phone =
                                business[
                                        'phone'] ??
                                    "-";

                            final email =
                                business[
                                        'email'] ??
                                    "-";

                            final address =
                                business[
                                        'address'] ??
                                    "-";

                            final serviceType =
                                service[
                                        'serviceType'] ??
                                    data[
                                        'serviceType'] ??
                                    "-";

                            final providerType =
                                data[
                                        'providerType'] ??
                                    "Provider";

                            String appliedDate =
                                "-";

                            if (createdAt !=
                                null) {
                              appliedDate =
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
                                  28,
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
                                  /// ================= TOP =================
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,

                                    children: [
                                      Container(
                                        width: 74,
                                        height: 74,

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

                                        child: Icon(
                                          getServiceIcon(
                                            serviceType,
                                          ),

                                          color: Colors
                                              .white,

                                          size: 34,
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
                                              businessName,

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
                                                    10),

                                            Wrap(
                                              spacing:
                                                  8,

                                              runSpacing:
                                                  8,

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
                                                        Colors.orange.withOpacity(
                                                      .10,
                                                    ),

                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      30,
                                                    ),
                                                  ),

                                                  child:
                                                      const Text(
                                                    "PENDING",

                                                    style:
                                                        TextStyle(
                                                      color:
                                                          Colors.orange,

                                                      fontWeight:
                                                          FontWeight.bold,

                                                      fontSize:
                                                          11,
                                                    ),
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
                                                    providerType,

                                                    style:
                                                        const TextStyle(
                                                      color:
                                                          Color(
                                                        0xFF4F46E5,
                                                      ),

                                                      fontWeight:
                                                          FontWeight.w600,

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
                                                    .email_rounded,
                                                email,
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

                                        Row(
                                          children: [
                                            Expanded(
                                              child:
                                                  _compactInfo(
                                                Icons
                                                    .miscellaneous_services_rounded,
                                                serviceType,
                                              ),
                                            ),

                                            const SizedBox(
                                                width:
                                                    12),

                                            Expanded(
                                              child:
                                                  _compactInfo(
                                                Icons
                                                    .calendar_month_rounded,
                                                appliedDate,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(
                                            height:
                                                14),

                                        _compactInfo(
                                          Icons
                                              .account_balance_rounded,
                                          bank['accountHolder']
                                                  ?.toString() ??
                                              "-",
                                        ),

                                        const SizedBox(
                                            height:
                                                14),

                                        _compactInfo(
                                          Icons
                                              .badge_rounded,
                                          providerId,
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

                                    Align(
                                      alignment:
                                          Alignment
                                              .centerLeft,

                                      child:
                                          Text(
                                        "Categories",

                                        style:
                                            TextStyle(
                                          color: Colors
                                              .grey
                                              .shade700,

                                          fontWeight:
                                              FontWeight.w600,
                                        ),
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

                                                fontWeight:
                                                    FontWeight.w600,

                                                fontSize:
                                                    12,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],

                                  const SizedBox(
                                      height:
                                          22),

                                  /// ================= BUTTONS =================
                                  Row(
                                    children: [
                                      Expanded(
                                        child:
                                            OutlinedButton.icon(
                                          onPressed:
                                              () {
                                            rejectProvider(
                                              providerId,
                                            );
                                          },

                                          icon:
                                              const Icon(
                                            Icons
                                                .close_rounded,

                                            color:
                                                Colors.red,
                                          ),

                                          label:
                                              const Text(
                                            "Reject",

                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.red,

                                              fontWeight:
                                                  FontWeight.w600,
                                            ),
                                          ),

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
                                        ),
                                      ),

                                      const SizedBox(
                                          width:
                                              14),

                                      Expanded(
                                        child:
                                            ElevatedButton.icon(
                                          onPressed:
                                              () {
                                            approveProvider(
                                              providerId,
                                            );
                                          },

                                          icon:
                                              const Icon(
                                            Icons
                                                .check_rounded,

                                            color: Colors
                                                .white,
                                          ),

                                          label:
                                              const Text(
                                            "Approve",

                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.white,

                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),

                                          style:
                                              ElevatedButton.styleFrom(
                                            elevation:
                                                0,

                                            backgroundColor:
                                                const Color(
                                              0xFF16A34A,
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
                                        ),
                                      ),
                                    ],
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
            width: 96,
            height: 96,

            decoration:
                BoxDecoration(
              color: const Color(
                0xFFEEF2FF,
              ),

              borderRadius:
                  BorderRadius.circular(
                30,
              ),
            ),

            child: const Icon(
              Icons
                  .verified_user_rounded,

              size: 44,

              color: Color(
                0xFF4F46E5,
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "No Pending Providers",

            style: TextStyle(
              fontSize: 20,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "All provider requests are reviewed",

            style: TextStyle(
              color:
                  Colors.grey.shade600,
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
            "No Matching Providers",

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