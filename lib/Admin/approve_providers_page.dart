import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApproveProvidersPage extends StatefulWidget {
  const ApproveProvidersPage({super.key});

  @override
  State<ApproveProvidersPage> createState() =>
      _ApproveProvidersPageState();
}

class _ApproveProvidersPageState
    extends State<ApproveProvidersPage> {

  final CollectionReference providersRef =
      FirebaseFirestore.instance.collection(
          "providers");

  /// ================= STREAM =================
  Stream<QuerySnapshot>
      pendingProvidersStream() {

    return providersRef
        .where(
          "status",
          isEqualTo: "pending",
        )
        .snapshots();
  }

  /// ================= APPROVE =================
  Future<void> approveProvider(
    String id,
  ) async {

    try {

      await providersRef.doc(id).update({

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
              Colors.green,

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
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
          behavior:
              SnackBarBehavior.floating,

          backgroundColor: Colors.red,

          content: Text(
            "Error: $e",
          ),
        ),
      );
    }
  }

  /// ================= REJECT =================
  Future<void> rejectProvider(
    String id,
  ) async {

    String reason = "";

    await showDialog(
      context: context,

      builder: (ctx) {

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),

          child: Padding(
            padding:
                const EdgeInsets.all(22),

            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Row(
                  children: [

                    Container(
                      padding:
                          const EdgeInsets
                              .all(10),

                      decoration:
                          BoxDecoration(
                        color: Colors.red
                            .withOpacity(.1),

                        shape:
                            BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.red,
                      ),
                    ),

                    const SizedBox(width: 12),

                    const Text(
                      "Reject Provider",

                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                TextField(
                  maxLines: 3,

                  decoration:
                      InputDecoration(
                    hintText:
                        "Enter rejection reason...",

                    filled: true,

                    fillColor:
                        Colors.grey.shade100,

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                              16),

                      borderSide:
                          BorderSide.none,
                    ),
                  ),

                  onChanged: (val) {
                    reason = val;
                  },
                ),

                const SizedBox(height: 24),

                Row(
                  children: [

                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                        },

                        style:
                            OutlinedButton
                                .styleFrom(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 14,
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    14),
                          ),
                        ),

                        child:
                            const Text("Cancel"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {

                          try {

                            await providersRef
                                .doc(id)
                                .update({

                              "status":
                                  "rejected",

                              "isActive":
                                  false,

                              "rejectReason":
                                  reason,

                              "updatedAt":
                                  FieldValue
                                      .serverTimestamp(),
                            });

                            if (!mounted) {
                              return;
                            }

                            Navigator.pop(ctx);

                            ScaffoldMessenger.of(
                                    context)
                                .showSnackBar(

                              SnackBar(
                                behavior:
                                    SnackBarBehavior
                                        .floating,

                                backgroundColor:
                                    Colors.red,

                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          14),
                                ),

                                content:
                                    const Text(
                                  "Provider rejected",
                                ),
                              ),
                            );
                          } catch (e) {

                            Navigator.pop(ctx);

                            ScaffoldMessenger.of(
                                    context)
                                .showSnackBar(

                              SnackBar(
                                backgroundColor:
                                    Colors.red,

                                content: Text(
                                  "Error: $e",
                                ),
                              ),
                            );
                          }
                        },

                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              Colors.red,

                          elevation: 0,

                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 14,
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    14),
                          ),
                        ),

                        child:
                            const Text(
                          "Reject",
                          style: TextStyle(
                            color: Colors.white,
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

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {

    final size =
        MediaQuery.of(context).size;

    final bool isMobile =
        size.width < 700;

    return Scaffold(
      backgroundColor:
          const Color(0xfff5f7fb),

      appBar: AppBar(
        elevation: 0,

        backgroundColor:
            Colors.transparent,

        foregroundColor: Colors.black,

        centerTitle: true,

        title: const Text(
          "Provider Approvals",

          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream:
            pendingProvidersStream(),

        builder:
            (context, snapshot) {

          if (snapshot.hasError) {

            return Center(
              child: Text(
                "Error: ${snapshot.error}",
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {

            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final docs =
              snapshot.data?.docs ?? [];

          /// ================= EMPTY =================
          if (docs.isEmpty) {

            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(30),

                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,

                  children: [

                    Container(
                      padding:
                          const EdgeInsets
                              .all(24),

                      decoration:
                          BoxDecoration(
                        color: Colors.blue
                            .withOpacity(.1),

                        shape:
                            BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons
                            .verified_user_rounded,

                        size: 60,
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(
                        height: 24),

                    const Text(
                      "No Pending Providers",

                      style: TextStyle(
                        fontSize: 24,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                        height: 10),

                    Text(
                      "All provider requests have been reviewed",

                      textAlign:
                          TextAlign.center,

                      style: TextStyle(
                        color: Colors
                            .grey.shade600,

                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          /// ================= LIST =================
          return ListView.builder(
            padding:
                const EdgeInsets.all(16),

            physics:
                const BouncingScrollPhysics(),

            itemCount: docs.length,

            itemBuilder:
                (context, index) {

              final doc = docs[index];

              final data =
                  doc.data()
                      as Map<String, dynamic>;

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
                  (data['categories']
                          as List?) ??
                      [];

              final createdAt =
                  data['createdAt']
                      as Timestamp?;

              final String serviceType =
                  service['serviceType'] ??
                      "Not specified";

              final String providerType =
                  data['providerType'] ??
                      "Not specified";

              return Container(
                margin:
                    const EdgeInsets.only(
                        bottom: 18),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                          28),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(.04),

                      blurRadius: 10,

                      offset:
                          const Offset(0, 4),
                    ),
                  ],
                ),

                child: Padding(
                  padding:
                      const EdgeInsets.all(
                          20),

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
                            padding:
                                const EdgeInsets
                                    .all(14),

                            decoration:
                                BoxDecoration(
                              gradient:
                                  LinearGradient(
                                colors: [
                                  Colors.blue
                                      .shade400,
                                  Colors
                                      .purple,
                                ],
                              ),

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          18),
                            ),

                            child: const Icon(
                              Icons.business,
                              color:
                                  Colors.white,
                              size: 28,
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
                                  business[
                                          'businessName'] ??
                                      "No Name",

                                  style:
                                      TextStyle(
                                    fontSize:
                                        isMobile
                                            ? 18
                                            : 20,

                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                    height:
                                        6),

                                Text(
                                  providerType,

                                  style:
                                      TextStyle(
                                    color: Colors
                                        .grey
                                        .shade700,

                                    fontWeight:
                                        FontWeight
                                            .w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),

                            decoration:
                                BoxDecoration(
                              color: Colors
                                  .orange
                                  .withOpacity(
                                      .1),

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          30),
                            ),

                            child: const Text(
                              "PENDING",

                              style: TextStyle(
                                color:
                                    Colors.orange,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                          height: 22),

                      /// ================= OWNER =================
                      _infoTile(
                        Icons.person,
                        "Owner",
                        business[
                                'ownerName'] ??
                            "-",
                      ),

                      _infoTile(
                        Icons.phone,
                        "Phone",
                        business['phone'] ??
                            "-",
                      ),

                      _infoTile(
                        Icons.email,
                        "Email",
                        business['email'] ??
                            "-",
                      ),

                      _infoTile(
                        Icons.location_on,
                        "Address",
                        business[
                                'address'] ??
                            "-",
                      ),

                      _infoTile(
                        Icons.miscellaneous_services,
                        "Service",
                        serviceType,
                      ),

                      _infoTile(
                        Icons.currency_rupee,
                        "Price",
                        "₹${service['price'] ?? "0"}",
                      ),

                      _infoTile(
                        Icons
                            .account_balance,
                        "Account Holder",
                        bank[
                                'accountHolder'] ??
                            "-",
                      ),

                      _infoTile(
                        Icons.numbers,
                        "Account Number",
                        bank[
                                'accountNumber'] ??
                            "-",
                      ),

                      const SizedBox(
                          height: 16),

                      /// ================= CATEGORIES =================
                      if (categories.isNotEmpty)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,

                          children:
                              categories.map(
                            (e) {

                              return Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),

                                decoration:
                                    BoxDecoration(
                                  color: Colors
                                      .blue
                                      .withOpacity(
                                          .08),

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              30),
                                ),

                                child: Text(
                                  e.toString(),

                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                              );
                            },
                          ).toList(),
                        ),

                      const SizedBox(
                          height: 22),

                      /// ================= DATE =================
                      if (createdAt != null)

                        Row(
                          children: [

                            Icon(
                              Icons.access_time,
                              size: 18,
                              color: Colors
                                  .grey
                                  .shade600,
                            ),

                            const SizedBox(
                                width: 8),

                            Text(
                              "Applied on ${createdAt.toDate().toString().split(" ")[0]}",

                              style: TextStyle(
                                color: Colors
                                    .grey
                                    .shade700,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(
                          height: 24),

                      /// ================= BUTTONS =================
                      Row(
                        children: [

                          Expanded(
                            child:
                                OutlinedButton.icon(
                              onPressed: () {
                                rejectProvider(
                                  doc.id,
                                );
                              },

                              icon: const Icon(
                                Icons.close,
                                color:
                                    Colors.red,
                              ),

                              label:
                                  const Text(
                                "Reject",
                                style: TextStyle(
                                  color:
                                      Colors.red,
                                ),
                              ),

                              style:
                                  OutlinedButton
                                      .styleFrom(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical: 14,
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
                                          16),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                              width: 14),

                          Expanded(
                            child:
                                ElevatedButton.icon(
                              onPressed: () {
                                approveProvider(
                                  doc.id,
                                );
                              },

                              icon: const Icon(
                                Icons.check,
                                color:
                                    Colors.white,
                              ),

                              label:
                                  const Text(
                                "Approve",

                                style: TextStyle(
                                  color:
                                      Colors.white,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              style:
                                  ElevatedButton
                                      .styleFrom(
                                backgroundColor:
                                    Colors.green,

                                elevation: 0,

                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical: 14,
                                ),

                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          16),
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
    );
  }

  /// ================= INFO TILE =================
  Widget _infoTile(
    IconData icon,
    String title,
    String value,
  ) {

    return Padding(
      padding:
          const EdgeInsets.only(
              bottom: 12),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Container(
            padding:
                const EdgeInsets.all(10),

            decoration:
                BoxDecoration(
              color:
                  Colors.grey.shade100,

              borderRadius:
                  BorderRadius.circular(
                      12),
            ),

            child: Icon(
              icon,
              size: 20,
              color: Colors.black87,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [

                Text(
                  title,

                  style: TextStyle(
                    color:
                        Colors.grey.shade600,

                    fontSize: 13,
                  ),
                ),

                const SizedBox(
                    height: 3),

                Text(
                  value,

                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w600,

                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}