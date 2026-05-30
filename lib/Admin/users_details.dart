import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  String search = "";

  final TextEditingController
      searchController =
      TextEditingController();

  /// ================= USERS STREAM =================
  Stream<QuerySnapshot<Map<String, dynamic>>>
      usersStream() {
    return firestore
        .collection("users")
        .snapshots();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F7FC),

      body: SafeArea(
        child: Column(
          children: [
            /// ================= HEADER =================
            _buildHeader(),

            /// ================= USERS =================
            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<
                      Map<String, dynamic>>>(
                stream: usersStream(),

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
                          "Firestore Error\n\n${snapshot.error}",

                          textAlign:
                              TextAlign.center,

                          style:
                              const TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w600,
                          ),
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
                    return _emptyState(
                      "No Users Found",
                    );
                  }

                  List<
                          QueryDocumentSnapshot<
                              Map<String,
                                  dynamic>>>
                      docs =
                      snapshot.data!.docs;

                  /// ================= SORT SAFELY =================
                  docs.sort((a, b) {
                    final aTime =
                        a.data()['createdAt'];
                    final bTime =
                        b.data()['createdAt'];

                    if (aTime is Timestamp &&
                        bTime is Timestamp) {
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

                    final uid =
                        (data['uid'] ??
                                doc.id)
                            .toString()
                            .toLowerCase();

                    return name.contains(
                            search) ||
                        email.contains(
                            search) ||
                        phone.contains(
                            search) ||
                        uid.contains(
                            search);
                  }).toList();

                  if (filtered.isEmpty) {
                    return _emptyState(
                      "No Matching Users",
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {});
                    },

                    child: ListView.builder(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),

                      physics:
                          const BouncingScrollPhysics(),

                      itemCount:
                          filtered.length,

                      itemBuilder:
                          (context, index) {
                        final doc =
                            filtered[index];

                        final data =
                            doc.data();

                        /// ================= SAFE DATA =================
                        final String uid =
                            data['uid'] ??
                                doc.id;

                        final String name =
                            data['name'] ??
                                "Unknown User";

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
                            data['isActive'] ??
                                true;

                        final List providers =
                            data['providers'] ??
                                [];

                        final Timestamp?
                            createdAt =
                            data['createdAt'];

                        String joinedDate =
                            "N/A";

                        if (createdAt !=
                            null) {
                          joinedDate =
                              DateFormat(
                            "dd MMM yyyy",
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
                              children: [
                                /// ================= TOP =================
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [
                                    /// PROFILE
                                    Container(
                                      width:
                                          65,
                                      height:
                                          65,

                                      decoration:
                                          BoxDecoration(
                                        gradient:
                                            const LinearGradient(
                                          colors: [
                                            Color(
                                              0xFF6D5DF6,
                                            ),
                                            Color(
                                              0xFF8E7CFF,
                                            ),
                                          ],
                                        ),

                                        borderRadius:
                                            BorderRadius.circular(
                                          22,
                                        ),
                                      ),

                                      child:
                                          ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(
                                          22,
                                        ),

                                        child: photo
                                                .isNotEmpty
                                            ? Image.network(
                                                photo,
                                                fit: BoxFit
                                                    .cover,

                                                errorBuilder:
                                                    (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return const Icon(
                                                    Icons.person,
                                                    color:
                                                        Colors.white,
                                                    size:
                                                        32,
                                                  );
                                                },
                                              )
                                            : const Icon(
                                                Icons
                                                    .person,
                                                color:
                                                    Colors.white,
                                                size:
                                                    32,
                                              ),
                                      ),
                                    ),

                                    const SizedBox(
                                        width:
                                            14),

                                    /// DETAILS
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
                                                  18,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
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
                                              color: isActive
                                                  ? Colors.green.withOpacity(
                                                      .12)
                                                  : Colors.red.withOpacity(
                                                      .12),

                                              borderRadius:
                                                  BorderRadius.circular(
                                                50,
                                              ),
                                            ),

                                            child:
                                                Text(
                                              isActive
                                                  ? "ACTIVE USER"
                                                  : "BLOCKED USER",

                                              style:
                                                  TextStyle(
                                                color: isActive
                                                    ? Colors.green
                                                    : Colors.red,

                                                fontSize:
                                                    11,

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
                                    height:
                                        20),

                                /// ================= INFO BOX =================
                                Container(
                                  padding:
                                      const EdgeInsets.all(
                                    16,
                                  ),

                                  decoration:
                                      BoxDecoration(
                                    color:
                                        const Color(
                                      0xFFF7F8FD,
                                    ),

                                    borderRadius:
                                        BorderRadius.circular(
                                      22,
                                    ),
                                  ),

                                  child:
                                      Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child:
                                                _infoTile(
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
                                                _infoTile(
                                              Icons
                                                  .calendar_month,
                                              joinedDate,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(
                                          height:
                                              14),

                                      _infoTile(
                                        Icons
                                            .location_on,
                                        address,
                                      ),
                                    ],
                                  ),
                                ),

                                /// ================= PROVIDERS =================
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
                                        fontWeight:
                                            FontWeight
                                                .bold,

                                        color: Colors
                                            .grey
                                            .shade800,

                                        fontSize:
                                            14,
                                      ),
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
                                        providers
                                            .map(
                                      (
                                        provider,
                                      ) {
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
                                            gradient:
                                                const LinearGradient(
                                              colors: [
                                                Color(
                                                  0xFFEEF0FF,
                                                ),
                                                Color(
                                                  0xFFE7E9FF,
                                                ),
                                              ],
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
                                              const Icon(
                                                Icons
                                                    .business_center,
                                                size:
                                                    15,

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
                                                      FontWeight.w700,

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
                                        18),

                                /// ================= UID =================
                                Container(
                                  width: double
                                      .infinity,

                                  padding:
                                      const EdgeInsets.all(
                                    14,
                                  ),

                                  decoration:
                                      BoxDecoration(
                                    border:
                                        Border.all(
                                      color: Colors
                                          .grey
                                          .shade200,
                                    ),

                                    borderRadius:
                                        BorderRadius.circular(
                                      18,
                                    ),
                                  ),

                                  child:
                                      Row(
                                    children: [
                                      const Icon(
                                        Icons
                                            .verified_user,
                                        color:
                                            Color(
                                          0xFF5B5FEF,
                                        ),

                                        size:
                                            18,
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
                                            fontWeight:
                                                FontWeight.w600,

                                            fontSize:
                                                13,
                                          ),
                                        ),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= HEADER =================
  Widget _buildHeader() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        24,
      ),

      decoration:
          const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF5B5FEF),
            Color(0xFF8B5CF6),
          ],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius:
            BorderRadius.only(
          bottomLeft:
              Radius.circular(34),
          bottomRight:
              Radius.circular(34),
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
                      .withOpacity(.15),

                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),

                child: const Icon(
                  Icons.people_alt_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      "Users Dashboard",

                      style: TextStyle(
                        color:
                            Colors.white,

                        fontSize: 24,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      "Manage all registered users",

                      style: TextStyle(
                        color:
                            Colors.white70,

                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

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

              onChanged: (value) {
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
                    "Search users by name, email or phone",

                prefixIcon:
                    const Icon(
                  Icons.search,
                  color:
                      Color(0xFF5B5FEF),
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
        ],
      ),
    );
  }

  /// ================= INFO TILE =================
  Widget _infoTile(
    IconData icon,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Container(
          padding:
              const EdgeInsets.all(9),

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
            size: 17,
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
              top: 3,
            ),

            child: Text(
              value,

              maxLines: 3,

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

  /// ================= EMPTY =================
  Widget _emptyState(
    String title,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Container(
            width: 95,
            height: 95,

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

            child: const Icon(
              Icons.people_outline,
              size: 42,
              color:
                  Color(0xFF5B5FEF),
            ),
          ),

          const SizedBox(height: 18),

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