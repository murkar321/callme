import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:callme/profile/notification_service.dart' show NotificationType;

typedef NotificationTapCallback = void Function(Map<String, dynamic> data);

class NotificationPage extends StatefulWidget {
  final NotificationTapCallback? onNotificationTap;

  const NotificationPage({
    super.key,
    this.onNotificationTap,
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String? _uid;
  Stream<QuerySnapshot>? _notifStream;
  Stream<int>? _unreadStream;

  @override
  void initState() {
    super.initState();
    _setupStreams(FirebaseAuth.instance.currentUser?.uid);
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) setState(() => _setupStreams(user?.uid));
    });
  }

  void _setupStreams(String? uid) {
    _uid = uid;
    if (uid == null) {
      _notifStream = null;
      _unreadStream = null;
      return;
    }

    _notifStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    _unreadStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((e) => e.docs.length);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _markAsRead(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    if (data['read'] == true) return;
    await doc.reference.update({'read': true});
  }

  Future<void> _markAllAsRead() async {
    if (_uid == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: _uid)
        .where('read', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
    _showSnack('${snap.docs.length} notifications marked as read');
  }

  /// Deletes a single notification from Firestore by document ID.
  /// Uses the document ID directly (not the captured DocumentSnapshot)
  /// so the correct record is always deleted even if the list shifts
  /// during a dismiss animation.
  Future<void> _deleteById(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .delete();
    } catch (e) {
      debugPrint('[NOTIF-PAGE] Delete failed for $docId: $e');
      _showSnack('Failed to delete notification');
    }
  }

  Future<void> _deleteAllNotifications() async {
    if (_uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete all notifications?'),
        content: const Text(
          'This action will permanently remove all notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('notifications')
          .where('receiverId', isEqualTo: _uid)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      _showSnack('${snap.docs.length} notifications deleted');
    } catch (e) {
      debugPrint('[NOTIF-PAGE] Delete-all failed: $e');
      _showSnack('Failed to delete notifications');
    }
  }

  String _relativeTime(dynamic value) {
    if (value is! Timestamp) return '';
    final date = value.toDate();
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  ({IconData icon, Color color}) _style(String? type) {
    switch (type) {
      case NotificationType.newBooking:
        return (icon: Icons.event_available_outlined, color: Colors.blue);
      case NotificationType.bookingAccepted:
        return (icon: Icons.check_circle_outline, color: Colors.green);
      case NotificationType.bookingRejected:
        return (icon: Icons.cancel_outlined, color: Colors.red);
      case NotificationType.providerRegistered:
        return (icon: Icons.store_mall_directory_outlined, color: Colors.orange);
      case NotificationType.registrationApproved:
        return (icon: Icons.verified_outlined, color: Colors.green);
      case NotificationType.registrationRejected:
        return (icon: Icons.block_outlined, color: Colors.red);
      case NotificationType.serviceCompleted:
        return (icon: Icons.task_alt_outlined, color: Colors.teal);
      default:
        return (
          icon: Icons.notifications_active_outlined,
          color: Colors.indigo
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          StreamBuilder<int>(
            stream: _unreadStream,
            builder: (context, snapshot) {
              final unread = snapshot.data ?? 0;
              return IconButton(
                onPressed: unread > 0 ? _markAllAsRead : null,
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.done_all),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: _deleteAllNotifications,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notifStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('[NOTIF-PAGE] Firestore error: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    const Text(
                      'Failed to load notifications',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      snapshot.error.toString(),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'If this says "failed-precondition", create the\n'
                      'composite index shown in the Firestore console.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No notifications yet'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc   = docs[index];
              // Capture the stable document ID immediately so Dismissible
              // and long-press dialogs always delete the correct record,
              // even if the list reorders before the callback fires.
              final docId  = doc.id;
              final data   = doc.data() as Map<String, dynamic>;
              final isRead = data['read'] == true;
              final style  = _style(data['type'] as String?);

              return Dismissible(
                key: ValueKey(docId),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                // Delete by ID — not by captured DocumentSnapshot reference —
                // so the right document is removed even if the list shifted.
                onDismissed: (_) => _deleteById(docId),
                child: ListTile(
                  tileColor: isRead ? null : Colors.blue.withOpacity(0.04),
                  onTap: () async {
                    await _markAsRead(doc);
                    widget.onNotificationTap?.call(data);
                  },
                  onLongPress: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete notification'),
                        content: const Text(
                          'Do you want to delete this notification?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _deleteById(docId);
                    }
                  },
                  leading: CircleAvatar(
                    backgroundColor: style.color.withOpacity(0.15),
                    child: Icon(style.icon, color: style.color),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['title'] as String? ?? '',
                          style: TextStyle(
                            fontWeight:
                                isRead ? FontWeight.w400 : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(data['body'] as String? ?? ''),
                      const SizedBox(height: 4),
                      Text(
                        _relativeTime(data['createdAt']),
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
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
}