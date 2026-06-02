import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  final String providerId;

  const NotificationPage({
    super.key,
    required this.providerId,
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool notificationsEnabled = true;

  Future<void> _markAllAsRead() async {
    final docs = await FirebaseFirestore.instance
        .collection('notifications')
        .where('providerId', isEqualTo: widget.providerId)
        .where('read', isEqualTo: false)
        .get();

    for (var doc in docs.docs) {
      await doc.reference.update({'read': true});
    }
  }

  String _formatTime(dynamic value) {
    try {
      if (value == null) return '';

      if (value is Timestamp) {
        final date = value.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }

      return value.toString();
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await _markAllAsRead();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Marked all as read"),
                  ),
                );
              }
            },
          )
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('providerId', isEqualTo: widget.providerId)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("Something went wrong"));
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No Notifications Yet",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final isRead = data['read'] ?? false;

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Stack(
                    children: [
                      const CircleAvatar(
                        child: Icon(Icons.notifications),
                      ),
                      if (!isRead)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                    ],
                  ),

                  title: Text(
                    data['title'] ?? '',
                    style: TextStyle(
                      fontWeight:
                          isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(data['body'] ?? ''),

                  trailing: Text(
                    _formatTime(data['createdAt']),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  onTap: () async {
                    await docs[index].reference.update({'read': true});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}