import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final CollectionReference usersRef =
      FirebaseFirestore.instance.collection("users");

  String search = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          "All Users",
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
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xff4f46e5),
                  Color(0xff7c3aed),
                ],
              ),

              borderRadius: BorderRadius.circular(24),
            ),

            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),

                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.people_alt_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                const SizedBox(width: 16),

                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        "Manage Registered Users",

                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),

                      SizedBox(height: 6),

                      Text(
                        "Users Dashboard",

                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
                const EdgeInsets.symmetric(horizontal: 16),

            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(18),

                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(.04),

                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),

              child: TextField(
                onChanged: (value) {
                  setState(() {
                    search = value.toLowerCase();
                  });
                },

                decoration: const InputDecoration(
                  hintText:
                      "Search by name, email or phone",

                  border: InputBorder.none,

                  prefixIcon: Icon(
                    Icons.search_rounded,
                  ),

                  contentPadding:
                      EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          /// ================= USERS =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: usersRef
                  .orderBy(
                    "createdAt",
                    descending: true,
                  )
                  .snapshots(),

              builder: (context, snapshot) {
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

                /// EMPTY
                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No Users Found",

                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                /// FILTER SEARCH
                final filtered = docs.where((doc) {
                  final data =
                      doc.data()
                          as Map<String, dynamic>;

                  final String name =
                      (data['name'] ?? "")
                          .toString()
                          .toLowerCase();

                  final String email =
                      (data['email'] ?? "")
                          .toString()
                          .toLowerCase();

                  final String phone =
                      (data['phone'] ?? "")
                          .toString()
                          .toLowerCase();

                  return name.contains(search) ||
                      email.contains(search) ||
                      phone.contains(search);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      "No Matching Users",
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),

                  itemCount: filtered.length,

                  itemBuilder: (context, index) {
                    final data =
                        filtered[index].data()
                            as Map<String, dynamic>;

                    /// ================= SAFE DATA =================
                    final String uid =
                        data['uid'] ??
                            filtered[index].id;

                    final String name =
                        data['name'] ??
                            "No Name";

                    final String email =
                        data['email'] ??
                            "No Email";

                    final String phone =
                        data['phone'] ??
                            "No Phone";

                    final String address =
                        data['address'] ??
                            "No Address";

                    final String photo =
                        data['photo'] ??
                            "";

                    final bool isActive =
                        data['isActive'] ?? true;

                    final List providers =
                        data['providers'] ?? [];

                    final Timestamp? createdAt =
                        data['createdAt']
                            as Timestamp?;

                    String joinedDate = "-";

                    if (createdAt != null) {
                      joinedDate = DateFormat(
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

                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius:
                            BorderRadius.circular(
                          26,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(.05),

                            blurRadius: 12,

                            offset:
                                const Offset(0, 5),
                          ),
                        ],
                      ),

                      child: Padding(
                        padding:
                            const EdgeInsets.all(18),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            /// ================= TOP =================
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 36,

                                  backgroundColor:
                                      Colors.indigo
                                          .withOpacity(.1),

                                  backgroundImage:
                                      photo.isNotEmpty
                                          ? NetworkImage(
                                              photo,
                                            )
                                          : null,

                                  child: photo.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 34,
                                          color:
                                              Colors.indigo,
                                        )
                                      : null,
                                ),

                                const SizedBox(width: 16),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,

                                    children: [
                                      Text(
                                        name,

                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .bold,

                                          fontSize: 20,
                                        ),
                                      ),

                                      const SizedBox(
                                          height: 6),

                                      Text(
                                        email,

                                        style: TextStyle(
                                          color: Colors
                                              .grey
                                              .shade700,
                                        ),
                                      ),

                                      const SizedBox(
                                          height: 6),

                                      Container(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),

                                        decoration:
                                            BoxDecoration(
                                          color: isActive
                                              ? Colors.green
                                                  .withOpacity(
                                                      .1)
                                              : Colors.red
                                                  .withOpacity(
                                                      .1),

                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            30,
                                          ),
                                        ),

                                        child: Text(
                                          isActive
                                              ? "ACTIVE"
                                              : "BLOCKED",

                                          style:
                                              TextStyle(
                                            color: isActive
                                                ? Colors
                                                    .green
                                                : Colors
                                                    .red,

                                            fontWeight:
                                                FontWeight
                                                    .bold,

                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            Divider(
                              color:
                                  Colors.grey.shade200,
                            ),

                            const SizedBox(height: 16),

                            /// ================= INFO =================
                            _infoTile(
                              icon:
                                  Icons.phone_rounded,

                              title: "Phone",

                              value: phone,
                            ),

                            const SizedBox(height: 14),

                            _infoTile(
                              icon:
                                  Icons.location_on_rounded,

                              title: "Address",

                              value: address,
                            ),

                            const SizedBox(height: 14),

                            _infoTile(
                              icon:
                                  Icons.verified_user_rounded,

                              title: "User ID",

                              value: uid,
                            ),

                            const SizedBox(height: 14),

                            _infoTile(
                              icon:
                                  Icons.calendar_month_rounded,

                              title: "Joined On",

                              value: joinedDate,
                            ),

                            /// ================= PROVIDERS =================
                            if (providers.isNotEmpty) ...[
                              const SizedBox(height: 22),

                              const Text(
                                "Linked Providers",

                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),

                              const SizedBox(height: 12),

                              Wrap(
                                spacing: 10,
                                runSpacing: 10,

                                children:
                                    providers.map((provider) {
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
                                          .indigo
                                          .withOpacity(
                                              .08),

                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        30,
                                      ),
                                    ),

                                    child: Row(
                                      mainAxisSize:
                                          MainAxisSize.min,

                                      children: [
                                        const Icon(
                                          Icons.link_rounded,
                                          size: 16,
                                          color:
                                              Colors.indigo,
                                        ),

                                        const SizedBox(
                                            width: 6),

                                        Text(
                                          provider
                                              .toString(),

                                          style:
                                              const TextStyle(
                                            color: Colors
                                                .indigo,

                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
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
          padding: const EdgeInsets.all(10),

          decoration: BoxDecoration(
            color:
                Colors.indigo.withOpacity(.08),

            borderRadius:
                BorderRadius.circular(14),
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
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value.isEmpty ? "-" : value,

                style: const TextStyle(
                  fontWeight: FontWeight.w600,
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