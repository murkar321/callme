import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UsersPage extends StatelessWidget {
  UsersPage({super.key});

  final CollectionReference usersRef =
      FirebaseFirestore.instance.collection("users");

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

      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          // LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // EMPTY
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

          return Column(
            children: [

              // TOP STATS CARD
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff4f46e5),
                      Color(0xff7c3aed),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.people_alt_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const Text(
                            "Total Registered Users",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            docs.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // USERS LIST
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {

                    final data =
                        docs[index].data() as Map<String, dynamic>;

                    final String name =
                        data['name'] ?? "No Name";

                    final String email =
                        data['email'] ?? "No Email";

                    final String phone =
                        data['phone'] ?? "No Phone";

                    final String address =
                        data['address'] ?? "No Address";

                    final String uid =
                        data['uid'] ?? "";

                    final String photo =
                        data['photo'] ?? "";

                    final Timestamp? createdAt =
                        data['createdAt'];

                    String joinedDate = "";

                    if (createdAt != null) {
                      joinedDate = DateFormat(
                        'dd MMM yyyy • hh:mm a',
                      ).format(createdAt.toDate());
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [

                            // TOP USER INFO
                            Row(
                              children: [

                                // PROFILE IMAGE
                                CircleAvatar(
                                  radius: 34,
                                  backgroundColor:
                                      Colors.grey.shade200,
                                  backgroundImage: photo.isNotEmpty
                                      ? NetworkImage(photo)
                                      : null,
                                  child: photo.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 34,
                                        )
                                      : null,
                                ),

                                const SizedBox(width: 16),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [

                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),

                                      const SizedBox(height: 6),

                                      Row(
                                        children: [

                                          Icon(
                                            Icons.email_rounded,
                                            size: 16,
                                            color:
                                                Colors.grey.shade600,
                                          ),

                                          const SizedBox(width: 6),

                                          Expanded(
                                            child: Text(
                                              email,
                                              style: TextStyle(
                                                color: Colors
                                                    .grey.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),

                                      Row(
                                        children: [

                                          Icon(
                                            Icons.phone,
                                            size: 16,
                                            color:
                                                Colors.grey.shade600,
                                          ),

                                          const SizedBox(width: 6),

                                          Text(
                                            phone,
                                            style: TextStyle(
                                              color: Colors
                                                  .grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            Divider(
                              color: Colors.grey.shade200,
                            ),

                            const SizedBox(height: 12),

                            // ADDRESS
                            _infoTile(
                              icon: Icons.location_on_rounded,
                              title: "Address",
                              value: address,
                            ),

                            const SizedBox(height: 14),

                            // UID
                            _infoTile(
                              icon: Icons.verified_user_rounded,
                              title: "User UID",
                              value: uid,
                            ),

                            const SizedBox(height: 14),

                            // JOIN DATE
                            _infoTile(
                              icon: Icons.calendar_month_rounded,
                              title: "Joined On",
                              value: joinedDate,
                            ),

                            const SizedBox(height: 18),

                            // PROVIDERS
                            if (data['providers'] != null)
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: List.generate(
                                  (data['providers'] as List).length,
                                  (i) {

                                    final provider =
                                        data['providers'][i];

                                    return Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo
                                            .withOpacity(.08),
                                        borderRadius:
                                            BorderRadius.circular(30),
                                      ),
                                      child: Row(
                                        mainAxisSize:
                                            MainAxisSize.min,
                                        children: [

                                          const Icon(
                                            Icons.login,
                                            size: 16,
                                            color: Colors.indigo,
                                          ),

                                          const SizedBox(width: 6),

                                          Text(
                                            provider.toString(),
                                            style: const TextStyle(
                                              color: Colors.indigo,
                                              fontWeight:
                                                  FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
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

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(.08),
            borderRadius: BorderRadius.circular(14),
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                value,
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