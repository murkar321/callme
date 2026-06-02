import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() =>
      _NotificationPageState();
}

class _NotificationPageState
    extends State<NotificationPage> {
  bool notificationsEnabled = true;

  final String uid =
      FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _markAllAsRead() async {
    final docs =
        await FirebaseFirestore.instance
            .collection('notifications')
            .where(
              'userId',
              isEqualTo: uid,
            )
            .where(
              'isRead',
              isEqualTo: false,
            )
            .get();

    for (var doc in docs.docs) {
      await doc.reference.update({
        'isRead': true,
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {});
  }

  String _formatTime(
    Timestamp? timestamp,
  ) {
    if (timestamp == null) return '';

    final date = timestamp.toDate();

    return
        '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Notifications',
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await _markAllAsRead();

              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'All notifications marked as read',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(
              Icons.done_all,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Container(
            margin:
                const EdgeInsets.all(16),
            padding:
                const EdgeInsets.all(16),
            decoration:
                BoxDecoration(
              color:
                  Theme.of(
                    context,
                  )
                      .colorScheme
                      .surfaceContainerHighest,
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active,
                ),

                const SizedBox(
                  width: 12,
                ),

                const Expanded(
                  child: Text(
                    'Enable Push Notifications',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                Switch(
                  value:
                      notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      notificationsEnabled =
                          value;
                    });
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: StreamBuilder<
                  QuerySnapshot>(
                stream:
                    FirebaseFirestore
                        .instance
                        .collection(
                          'notifications',
                        )
                        .where(
                          'userId',
                          isEqualTo: uid,
                        )
                        .orderBy(
                          'createdAt',
                          descending:
                              true,
                        )
                        .snapshots(),
                builder: (
                  context,
                  snapshot,
                ) {
                  if (snapshot
                          .connectionState ==
                      ConnectionState
                          .waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot
                          .hasData ||
                      snapshot
                          .data!
                          .docs
                          .isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(
                          height: 120,
                        ),
                        Icon(
                          Icons
                              .notifications_none_rounded,
                          size: 80,
                        ),
                        SizedBox(
                          height: 12,
                        ),
                        Center(
                          child: Text(
                            'No Notifications Yet',
                            style:
                                TextStyle(
                              fontSize:
                                  18,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final notifications =
                      snapshot
                          .data!
                          .docs;

                  return ListView.builder(
                    padding:
                        const EdgeInsets
                            .only(
                      bottom: 20,
                    ),
                    itemCount:
                        notifications
                            .length,
                    itemBuilder:
                        (
                          context,
                          index,
                        ) {
                      final data =
                          notifications[
                                  index]
                              .data()
                              as Map<
                                  String,
                                  dynamic>;

                      final isRead =
                          data['isRead'] ??
                              false;

                      return Card(
                        margin:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              16,
                          vertical:
                              6,
                        ),
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                        ),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets
                                  .all(
                            14,
                          ),
                          leading:
                              Stack(
                            children: [
                              CircleAvatar(
                                radius:
                                    24,
                                child:
                                    const Icon(
                                  Icons
                                      .notifications,
                                ),
                              ),

                              if (!isRead)
                                Positioned(
                                  right:
                                      0,
                                  top:
                                      0,
                                  child:
                                      Container(
                                    width:
                                        12,
                                    height:
                                        12,
                                    decoration:
                                        const BoxDecoration(
                                      color:
                                          Colors.red,
                                      shape:
                                          BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          title: Text(
                            data['title'] ??
                                '',
                            style:
                                TextStyle(
                              fontWeight:
                                  isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                            ),
                          ),

                          subtitle:
                              Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              top: 6,
                            ),
                            child: Text(
                              data['body'] ??
                                  '',
                            ),
                          ),

                          trailing:
                              Text(
                            _formatTime(
                              data['createdAt'],
                            ),
                            style:
                                TextStyle(
                              color:
                                  Colors.grey
                                      .shade600,
                              fontSize:
                                  12,
                            ),
                          ),

                          onTap: () async {
                            await notifications[
                                    index]
                                .reference
                                .update({
                              'isRead':
                                  true,
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}