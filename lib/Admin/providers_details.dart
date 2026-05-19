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
      FirebaseFirestore.instance.collection(
    "providers",
  );

  /// ================= STATUS COLOR =================
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {

      case "approved":
        return Colors.green;

      case "rejected":
        return Colors.red;

      case "pending":
        return Colors.orange;

      default:
        return Colors.blue;
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
      return Icons.cleaning_services_rounded;
    }

    if (value.contains("electric")) {
      return Icons.electrical_services_rounded;
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
          const Color(0xfff5f7fb),

      appBar: AppBar(
        elevation: 0,

        centerTitle: true,

        backgroundColor:
            Colors.white,

        foregroundColor:
            Colors.black,

        title: const Text(
          "Service Providers",

          style: TextStyle(
            fontSize: 22,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body:
          StreamBuilder<QuerySnapshot>(

        stream:
            providersRef.snapshots(),

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

          /// EMPTY
          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {

            return const Center(
              child: Text(
                "No Providers Found",

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

          return Column(
            children: [

              /// ================= TOP CARD =================
              Container(
                margin:
                    const EdgeInsets.all(
                        16),

                padding:
                    const EdgeInsets.all(
                        20),

                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(
                    colors: [
                      Color(0xff2563eb),
                      Color(0xff7c3aed),
                    ],
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    24,
                  ),
                ),

                child: Row(
                  children: [

                    Container(
                      padding:
                          const EdgeInsets
                              .all(14),

                      decoration:
                          BoxDecoration(
                        color: Colors
                            .white
                            .withOpacity(
                                .15),

                        shape:
                            BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons
                            .storefront_rounded,

                        color:
                            Colors.white,

                        size: 32,
                      ),
                    ),

                    const SizedBox(
                        width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [

                          const Text(
                            "Total Providers",

                            style:
                                TextStyle(
                              color:
                                  Colors.white70,

                              fontSize:
                                  15,
                            ),
                          ),

                          const SizedBox(
                              height: 6),

                          Text(
                            docs.length
                                .toString(),

                            style:
                                const TextStyle(
                              color:
                                  Colors.white,

                              fontSize:
                                  30,

                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /// ================= PROVIDERS LIST =================
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 14,
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

                    final String email =
                        business['email'] ??
                            "";

                    final String phone =
                        business['phone'] ??
                            "";

                    final String city =
                        business['city'] ??
                            "";

                    final String state =
                        business['state'] ??
                            "";

                    final String image =
                        business['image'] ??
                            "";

                    final String providerType =
                        profile[
                                'providerType'] ??
                            data[
                                'providerType'] ??
                            "Provider";

                    final String status =
                        profile['status'] ??
                            data['status'] ??
                            "pending";

                    final String
                        serviceType =
                        service[
                                'serviceType'] ??
                            "";

                    final String price =
                        service['price']
                                ?.toString() ??
                            "";

                    final bool ownTools =
                        service[
                                'ownTools'] ??
                            false;

                    final List categories =
                        List.from(
                      data['categories'] ??
                          [],
                    );

                    final Timestamp?
                        createdAt =
                        data['createdAt'];

                    String joinedDate =
                        "";

                    if (createdAt !=
                        null) {

                      joinedDate =
                          DateFormat(
                        'dd MMM yyyy • hh:mm a',
                      ).format(
                        createdAt
                            .toDate(),
                      );
                    }

                    return Container(
                      margin:
                          const EdgeInsets
                              .only(
                        bottom: 18,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,

                        borderRadius:
                            BorderRadius
                                .circular(
                          26,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors
                                .black
                                .withOpacity(
                                    .05),

                            blurRadius:
                                12,

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

                            /// ================= TOP =================
                            Row(
                              children: [

                                Container(
                                  height: 72,
                                  width: 72,

                                  decoration:
                                      BoxDecoration(

                                    borderRadius:
                                        BorderRadius.circular(
                                      22,
                                    ),

                                    image:
                                        image.isNotEmpty
                                            ? DecorationImage(
                                                image:
                                                    NetworkImage(
                                                  image,
                                                ),

                                                fit: BoxFit
                                                    .cover,
                                              )
                                            : null,

                                    gradient:
                                        image.isEmpty
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(
                                                      0xff2563eb),
                                                  Color(
                                                      0xff7c3aed),
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

                                              color: Colors
                                                  .white,

                                              size: 34,
                                            )
                                          : null,
                                ),

                                const SizedBox(
                                    width:
                                        16),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,

                                    children: [

                                      Text(
                                        businessName,

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
                                              15,
                                        ),
                                      ),

                                      const SizedBox(
                                          height:
                                              8),

                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal:
                                              14,

                                          vertical:
                                              7,
                                        ),

                                        decoration:
                                            BoxDecoration(
                                          color: getStatusColor(
                                            status,
                                          ).withOpacity(
                                              .12),

                                          borderRadius:
                                              BorderRadius.circular(
                                            30,
                                          ),
                                        ),

                                        child:
                                            Text(
                                          status
                                              .toUpperCase(),

                                          style:
                                              TextStyle(
                                            color:
                                                getStatusColor(
                                              status,
                                            ),

                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                                height: 20),

                            Divider(
                              color: Colors
                                  .grey
                                  .shade200,
                            ),

                            const SizedBox(
                                height: 16),

                            /// ================= INFO =================
                            _infoTile(
                              icon: Icons
                                  .phone_rounded,

                              title:
                                  "Phone",

                              value: phone,
                            ),

                            const SizedBox(
                                height: 14),

                            _infoTile(
                              icon: Icons
                                  .email_rounded,

                              title:
                                  "Email",

                              value: email,
                            ),

                            const SizedBox(
                                height: 14),

                            _infoTile(
                              icon: Icons
                                  .location_on_rounded,

                              title:
                                  "Location",

                              value:
                                  "$city, $state",
                            ),

                            const SizedBox(
                                height: 14),

                            _infoTile(
                              icon: Icons
                                  .miscellaneous_services,

                              title:
                                  "Service Type",

                              value:
                                  serviceType,
                            ),

                            const SizedBox(
                                height: 14),

                            _infoTile(
                              icon: Icons
                                  .currency_rupee_rounded,

                              title:
                                  "Service Price",

                              value:
                                  "₹$price",
                            ),

                            const SizedBox(
                                height: 14),

                            _infoTile(
                              icon: Icons
                                  .build_circle_rounded,

                              title:
                                  "Own Tools",

                              value:
                                  ownTools
                                      ? "Available"
                                      : "Not Available",
                            ),

                            const SizedBox(
                                height: 14),

                            _infoTile(
                              icon: Icons
                                  .business_center_rounded,

                              title:
                                  "Provider Type",

                              value:
                                  providerType,
                            ),

                            const SizedBox(
                                height: 14),

                            _infoTile(
                              icon: Icons
                                  .calendar_month_rounded,

                              title:
                                  "Joined On",

                              value:
                                  joinedDate,
                            ),

                            const SizedBox(
                                height: 20),

                            /// ================= CATEGORIES =================
                            if (categories
                                .isNotEmpty) ...[

                              const Text(
                                "Categories",

                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,

                                  fontSize:
                                      16,
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
                                    List.generate(
                                  categories
                                      .length,

                                  (index) {

                                    return Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal:
                                            14,

                                        vertical:
                                            8,
                                      ),

                                      decoration:
                                          BoxDecoration(
                                        color: Colors
                                            .blue
                                            .withOpacity(
                                                .08),

                                        borderRadius:
                                            BorderRadius.circular(
                                          30,
                                        ),
                                      ),

                                      child:
                                          Text(
                                        categories[
                                                index]
                                            .toString(),

                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.blue,

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
                                height: 22),

                            /// ================= BANK =================
                            Container(
                              width:
                                  double
                                      .infinity,

                              padding:
                                  const EdgeInsets
                                      .all(
                                16,
                              ),

                              decoration:
                                  BoxDecoration(
                                color: Colors
                                    .grey
                                    .shade100,

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
                                            .account_balance,

                                        color:
                                            Colors.indigo,
                                      ),

                                      SizedBox(
                                          width:
                                              10),

                                      Text(
                                        "Bank Details",

                                        style:
                                            TextStyle(
                                          fontWeight:
                                              FontWeight.bold,

                                          fontSize:
                                              16,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                      height:
                                          18),

                                  _bankTile(
                                    "Account Holder",

                                    bank['accountHolder'] ??
                                        "",
                                  ),

                                  _bankTile(
                                    "Account Number",

                                    bank['accountNumber'] ??
                                        "",
                                  ),

                                  _bankTile(
                                    "IFSC Code",

                                    bank['ifsc'] ??
                                        "",
                                  ),

                                  _bankTile(
                                    "UPI ID",

                                    bank['upi'] ??
                                        "",
                                  ),
                                ],
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

            size: 20,

            color: Colors.indigo,
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

                style: const TextStyle(
                  fontSize: 15,

                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ================= BANK TILE =================
  Widget _bankTile(
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

          Expanded(
            flex: 2,

            child: Text(
              title,

              style: TextStyle(
                color:
                    Colors.grey.shade700,

                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),

          Expanded(
            flex: 3,

            child: Text(
              value.isEmpty
                  ? "-"
                  : value,

              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}