import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() =>
      _UsersPageState();
}

class _UsersPageState
    extends State<UsersPage> {
  final CollectionReference usersRef =
      FirebaseFirestore.instance
          .collection("users");

  String search = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7FB),

      body: SafeArea(
        child: Column(
          children: [
            /// ================= HEADER =================
            Container(
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
                    Color(0xFF5B5FEF),
                    Color(0xFF8B5CF6),
                  ],
                  begin:
                      Alignment.topLeft,
                  end:
                      Alignment.bottomRight,
                ),

                borderRadius:
                    BorderRadius.only(
                  bottomLeft:
                      Radius.circular(30),
                  bottomRight:
                      Radius.circular(30),
                ),
              ),

              child: Column(
                children: [
                  /// TOP BAR
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,

                        decoration:
                            BoxDecoration(
                          color: Colors
                              .white
                              .withOpacity(
                            .15,
                          ),

                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),

                        child: const Icon(
                          Icons.people_alt,
                          color:
                              Colors.white,
                          size: 24,
                        ),
                      ),

                      const SizedBox(
                          width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            Text(
                              "Users Dashboard",

                              style:
                                  TextStyle(
                                color:
                                    Colors
                                        .white,
                                fontSize:
                                    22,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            SizedBox(
                                height: 3),

                            Text(
                              "Manage all registered users",

                              style:
                                  TextStyle(
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
                      height: 22),

                  /// SEARCH BAR
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
                      onChanged: (value) {
                        setState(() {
                          search = value
                              .toLowerCase();
                        });
                      },

                      style:
                          const TextStyle(
                        fontSize: 15,
                      ),

                      decoration:
                          InputDecoration(
                        border:
                            InputBorder.none,

                        hintText:
                            "Search users...",

                        hintStyle:
                            TextStyle(
                          color: Colors
                              .grey.shade500,
                        ),

                        prefixIcon:
                            const Icon(
                          Icons.search,
                          color:
                              Color(
                            0xFF5B5FEF,
                          ),
                        ),

                        suffixIcon:
                            search.isNotEmpty
                                ? IconButton(
                                    onPressed:
                                        () {
                                      setState(
                                        () {
                                          search =
                                              "";
                                        },
                                      );
                                    },

                                    icon:
                                        const Icon(
                                      Icons
                                          .close,
                                      size:
                                          20,
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
                ],
              ),
            ),

            /// ================= USERS LIST =================
            Expanded(
              child: StreamBuilder<
                  QuerySnapshot>(
                stream: usersRef
                    .orderBy(
                      "createdAt",
                      descending: true,
                    )
                    .snapshots(),

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
                      child: Text(
                        "Error: ${snapshot.error}",
                      ),
                    );
                  }

                  /// EMPTY
                  if (!snapshot
                          .hasData ||
                      snapshot
                          .data!
                          .docs
                          .isEmpty) {
                    return _emptyState(
                      "No Users Found",
                    );
                  }

                  final docs =
                      snapshot.data!.docs;

                  /// SEARCH FILTER
                  final filtered =
                      docs.where((doc) {
                    final data =
                        doc.data()
                            as Map<String,
                                dynamic>;

                    final name =
                        (data['name'] ??
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

                    return name
                            .contains(
                                search) ||
                        email.contains(
                            search) ||
                        phone.contains(
                            search);
                  }).toList();

                  if (filtered.isEmpty) {
                    return _emptyState(
                      "No Matching Users",
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
                        (context, index) {
                      final data =
                          filtered[index]
                                  .data()
                              as Map<
                                  String,
                                  dynamic>;

                      /// SAFE DATA
                      final String uid =
                          data['uid'] ??
                              filtered[
                                      index]
                                  .id;

                      final String name =
                          data['name'] ??
                              "No Name";

                      final String email =
                          data['email'] ??
                              "No Email";

                      final String phone =
                          data['phone'] ??
                              "-";

                      final String address =
                          data['address'] ??
                              "-";

                      final String photo =
                          data['photo'] ??
                              "";

                      final bool isActive =
                          data['isActive'] ??
                              true;

                      final List providers =
                          data['providers'] ??
                              [];

                      final Timestamp?
                          createdAt =
                          data[
                                  'createdAt']
                              as Timestamp?;

                      String joinedDate =
                          "-";

                      if (createdAt !=
                          null) {
                        joinedDate =
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
                          bottom: 16,
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
                                  12,

                              offset:
                                  const Offset(
                                0,
                                5,
                              ),
                            ),
                          ],
                        ),

                        child: Column(
                          children: [
                            /// TOP SECTION
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,

                                  backgroundColor:
                                      const Color(
                                    0xFFEEF0FF,
                                  ),

                                  backgroundImage:
                                      photo.isNotEmpty
                                          ? NetworkImage(
                                              photo,
                                            )
                                          : null,

                                  child: photo
                                          .isEmpty
                                      ? const Icon(
                                          Icons
                                              .person,
                                          size:
                                              28,
                                          color:
                                              Color(
                                            0xFF5B5FEF,
                                          ),
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
                                        name,

                                        maxLines:
                                            1,

                                        overflow:
                                            TextOverflow
                                                .ellipsis,

                                        style:
                                            const TextStyle(
                                          fontSize:
                                              17,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(
                                          height:
                                              4),

                                      Text(
                                        email,

                                        maxLines:
                                            1,

                                        overflow:
                                            TextOverflow
                                                .ellipsis,

                                        style:
                                            TextStyle(
                                          color: Colors
                                              .grey
                                              .shade700,

                                          fontSize:
                                              13,
                                        ),
                                      ),
                                    ],
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
                                    color: isActive
                                        ? Colors.green.withOpacity(
                                            .10)
                                        : Colors.red.withOpacity(
                                            .10),

                                    borderRadius:
                                        BorderRadius.circular(
                                      30,
                                    ),
                                  ),

                                  child:
                                      Text(
                                    isActive
                                        ? "ACTIVE"
                                        : "BLOCKED",

                                    style:
                                        TextStyle(
                                      color: isActive
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

                            const SizedBox(
                                height:
                                    18),

                            /// QUICK INFO
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
                                              .phone,
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
                                              .calendar_today,
                                          joinedDate,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                      height:
                                          14),

                                  _compactInfo(
                                    Icons
                                        .location_on,
                                    address,
                                  ),
                                ],
                              ),
                            ),

                            /// PROVIDERS
                            if (providers
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
                                  "Linked Providers",

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
                              ),

                              const SizedBox(
                                  height:
                                      12),

                              Wrap(
                                spacing: 8,
                                runSpacing: 8,

                                children:
                                    providers
                                        .map(
                                  (
                                    provider,
                                  ) {
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
                                          0xFFEEF0FF,
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
                                          const Icon(
                                            Icons
                                                .business_center,
                                            size:
                                                14,
                                            color:
                                                Color(
                                              0xFF5B5FEF,
                                            ),
                                          ),

                                          const SizedBox(
                                              width:
                                                  6),

                                          Text(
                                            provider
                                                .toString(),

                                            style:
                                                const TextStyle(
                                              color:
                                                  Color(
                                                0xFF5B5FEF,
                                              ),

                                              fontWeight:
                                                  FontWeight.w600,

                                              fontSize:
                                                  12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ).toList(),
                              ),
                            ],

                            const SizedBox(
                                height:
                                    16),

                            /// UID
                            Container(
                              width: double
                                  .infinity,

                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal:
                                    14,
                                vertical:
                                    12,
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
                                  16,
                                ),
                              ),

                              child: Row(
                                children: [
                                  const Icon(
                                    Icons
                                        .verified_user,
                                    size:
                                        18,
                                    color:
                                        Color(
                                      0xFF5B5FEF,
                                    ),
                                  ),

                                  const SizedBox(
                                      width:
                                          10),

                                  Expanded(
                                    child:
                                        Text(
                                      uid,

                                      maxLines:
                                          1,

                                      overflow:
                                          TextOverflow
                                              .ellipsis,

                                      style:
                                          const TextStyle(
                                        fontSize:
                                            13,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
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
            color:
                Colors.white,

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
              0xFF5B5FEF,
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
              value,

              maxLines: 2,

              overflow:
                  TextOverflow
                      .ellipsis,

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

  /// ================= EMPTY STATE =================
  Widget _emptyState(
    String title,
  ) {
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
                0xFFEEF0FF,
              ),

              borderRadius:
                  BorderRadius.circular(
                28,
              ),
            ),

            child: const Icon(
              Icons.people_outline,
              size: 42,
              color:
                  Color(0xFF5B5FEF),
            ),
          ),

          const SizedBox(
              height: 18),

          Text(
            title,

            style: const TextStyle(
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