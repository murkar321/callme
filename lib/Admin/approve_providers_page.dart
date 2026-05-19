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

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

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
  Future<void> approveProvider(String providerId) async {

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
          backgroundColor: Colors.green,
          behavior:
              SnackBarBehavior.floating,

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),

          content: const Text(
            "Provider Approved Successfully",
          ),
        ),
      );
    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: $e"),
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

              children: [

                const Text(
                  "Reject Provider",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  maxLines: 3,

                  decoration: InputDecoration(
                    hintText:
                        "Reason for rejection",

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

                  onChanged: (value) {
                    reason = value;
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

                        child:
                            const Text("Cancel"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {

                          try {

                            await firestore
                                .collection(
                                    "providers")
                                .doc(providerId)
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

                            Navigator.pop(ctx);

                            ScaffoldMessenger.of(
                                    context)
                                .showSnackBar(

                              SnackBar(
                                backgroundColor:
                                    Colors.red,

                                behavior:
                                    SnackBarBehavior
                                        .floating,

                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          14),
                                ),

                                content:
                                    const Text(
                                  "Provider Rejected",
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

                                content:
                                    Text("$e"),
                              ),
                            );
                          }
                        },

                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              Colors.red,
                        ),

                        child: const Text(
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
        title: const Text(
          "Provider Approvals",
        ),

        centerTitle: true,

        backgroundColor:
            Colors.transparent,

        elevation: 0,

        foregroundColor: Colors.black,
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

          if (!snapshot.hasData) {

            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final docs =
              snapshot.data!.docs;

          /// ================= EMPTY =================
          if (docs.isEmpty) {

            return Center(
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
                    "All provider requests reviewed",

                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          /// ================= LIST =================
          return ListView.builder(
            padding:
                const EdgeInsets.all(16),

            itemCount: docs.length,

            itemBuilder:
                (context, index) {

              final doc = docs[index];

              final data =
                  doc.data()
                      as Map<String, dynamic>;

              /// 🔥 NEW STRUCTURE SUPPORT
              final business =
                  (data['business']
                          as Map<String,
                              dynamic>?) ??
                      {};

              final bank =
                  (data['bank']
                          as Map<String,
                              dynamic>?) ??
                      {};

              final service =
                  (data['service']
                          as Map<String,
                              dynamic>?) ??
                      {};

              final List categories =
                  data['categories'] ?? [];

              final Timestamp? createdAt =
                  data['createdAt'];

              /// 🔥 READABLE IDS
              final providerId = doc.id;

              final businessName =
                  business['businessName'] ??
                      data['providerName'] ??
                      "No Name";

              final ownerName =
                  business['ownerName'] ??
                      data['ownerName'] ??
                      "-";

              final phone =
                  business['phone'] ??
                      data['phone'] ??
                      "-";

              final email =
                  business['email'] ?? "-";

              final address =
                  business['address'] ?? "-";

              final price =
                  service['price'] ?? "0";

              final serviceType =
                  data['serviceType'] ??
                      "Not Specified";

              final providerType =
                  data['providerType'] ??
                      "Provider";

              return Container(
                margin:
                    const EdgeInsets.only(
                        bottom: 18),

                padding:
                    const EdgeInsets.all(20),

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
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [

                    /// ================= HEADER =================
                    Row(
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
                                Colors.purple,
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
                                businessName,

                                style:
                                    TextStyle(
                                  fontSize:
                                      isMobile
                                          ? 18
                                          : 22,

                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              const SizedBox(
                                  height: 4),

                              Text(
                                providerType,

                                style:
                                    TextStyle(
                                  color: Colors
                                      .grey
                                      .shade700,
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
                                .withOpacity(.1),

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
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    /// ================= PROVIDER ID =================
                    _infoTile(
                      Icons.badge,
                      "Provider ID",
                      providerId,
                    ),

                    _infoTile(
                      Icons.person,
                      "Owner",
                      ownerName,
                    ),

                    _infoTile(
                      Icons.phone,
                      "Phone",
                      phone,
                    ),

                    _infoTile(
                      Icons.email,
                      "Email",
                      email,
                    ),

                    _infoTile(
                      Icons.location_on,
                      "Address",
                      address,
                    ),

                    _infoTile(
                      Icons.miscellaneous_services,
                      "Service Type",
                      serviceType,
                    ),

                    _infoTile(
                      Icons.currency_rupee,
                      "Starting Price",
                      "₹$price",
                    ),

                    _infoTile(
                      Icons.account_balance,
                      "Account Holder",
                      bank['accountHolder']
                              ?.toString() ??
                          "-",
                    ),

                    const SizedBox(height: 18),

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

                    const SizedBox(height: 22),

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
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),

                    /// ================= BUTTONS =================
                    Row(
                      children: [

                        Expanded(
                          child:
                              OutlinedButton.icon(
                            onPressed: () {
                              rejectProvider(
                                providerId,
                              );
                            },

                            icon: const Icon(
                              Icons.close,
                              color: Colors.red,
                            ),

                            label: const Text(
                              "Reject",

                              style: TextStyle(
                                color: Colors.red,
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
                                color: Colors.red,
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
                                providerId,
                              );
                            },

                            icon: const Icon(
                              Icons.check,
                              color:
                                  Colors.white,
                            ),

                            label: const Text(
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

                const SizedBox(height: 3),

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