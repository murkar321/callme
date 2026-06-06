// notification_page.dart
//
// Production-ready notification inbox.
// • Real-time Firestore stream filtered by current user's UID (receiverId field)
// • Per-notification read/unread state — tapping marks as read instantly,
//   which also decrements the badge on HomePage in real time
// • "Mark all as read" action with unread count badge in AppBar
// • Swipe-to-dismiss deletes the notification document
// • Role-aware icons per notification type
// • Friendly relative timestamps
// • Empty-state illustration

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ─── Callback typedef ─────────────────────────────────────────────────────────
typedef NotificationTapCallback = void Function(Map<String, dynamic> data);

// ─── NotificationPage ─────────────────────────────────────────────────────────
class NotificationPage extends StatefulWidget {
  /// Optional callback fired when a notification tile is tapped.
  /// Use this to navigate: e.g. push to /provider/bookings based on data['type'].
  final NotificationTapCallback? onNotificationTap;

  const NotificationPage({super.key, this.onNotificationTap});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  // ── Mark all unread → read ────────────────────────────────────────────────
  Future<void> _markAllAsRead() async {
    if (_uid == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: _uid)
        .where('read', isEqualTo: false)
        .get();

    if (snap.docs.isEmpty) {
      _showSnack('All notifications are already read.');
      return;
    }

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
    _showSnack('Marked ${snap.docs.length} notification(s) as read.');
  }

  // ── Delete a single notification ─────────────────────────────────────────
  Future<void> _deleteNotification(DocumentReference ref) async {
    await ref.delete();
  }

  // ── Mark a single notification as read ───────────────────────────────────
  // This is called on tile tap. Updating 'read' → true in Firestore causes
  // the unread stream in HomePage to emit a lower count, clearing the badge.
  Future<void> _markAsRead(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    if (data['read'] == true) return;
    await doc.reference.update({'read': true});
  }

  // ── Friendly relative timestamp ───────────────────────────────────────────
  String _relativeTime(dynamic value) {
    if (value == null) return '';
    DateTime date;
    if (value is Timestamp) {
      date = value.toDate();
    } else {
      return value.toString();
    }

    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }

  // ── Icon + colour per notification type ──────────────────────────────────
  ({IconData icon, Color color}) _typeStyle(String? type) {
    switch (type) {
      case 'new_booking':
        return (icon: Icons.shopping_bag_outlined, color: Colors.indigo);
      case 'booking_accepted':
        return (icon: Icons.check_circle_outline, color: Colors.green);
      case 'booking_rejected':
        return (icon: Icons.cancel_outlined, color: Colors.red);
      case 'provider_registered':
        return (
          icon: Icons.store_mall_directory_outlined,
          color: Colors.orange
        );
      case 'registration_approved':
        return (icon: Icons.verified_outlined, color: Colors.teal);
      case 'registration_rejected':
        return (icon: Icons.block_outlined, color: Colors.deepOrange);
      default:
        return (icon: Icons.notifications_outlined, color: Colors.blueGrey);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // ── Shared unread stream (used in AppBar badge + mark-all button) ──────
    final unreadStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: _uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          // ── Mark-all button with live unread count badge ───────────────
          StreamBuilder<int>(
            stream: unreadStream,
            builder: (context, snap) {
              final unreadCount = snap.data ?? 0;

              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Mark all as read',
                    icon: const Icon(Icons.done_all_rounded),
                    onPressed: unreadCount > 0 ? _markAllAsRead : null,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          constraints: const BoxConstraints(
                              minWidth: 18, minHeight: 18),
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: colorScheme.surface, width: 1.5),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: TextStyle(
                              color: colorScheme.onError,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),

      // ── Main notification list ─────────────────────────────────────────
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('receiverId', isEqualTo: _uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: colorScheme.error),
                  const SizedBox(height: 12),
                  Text('Something went wrong',
                      style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text(
                    snapshot.error.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Loading state
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          // Empty state
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 80,
                    color: colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "We'll let you know when something happens.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.outlineVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Notification list
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 72,
              color: colorScheme.outlineVariant.withOpacity(0.4),
            ),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['read'] == true;
              final type = data['type'] as String?;
              final style = _typeStyle(type);

              return _NotificationTile(
                data: data,
                isRead: isRead,
                icon: style.icon,
                iconColor: style.color,
                relativeTime: _relativeTime(data['createdAt']),
                onTap: () async {
                  // Marking as read updates Firestore, which causes the
                  // HomePage's StreamBuilder badge to update automatically.
                  await _markAsRead(doc);
                  if (widget.onNotificationTap != null) {
                    widget.onNotificationTap!(data);
                  }
                },
                onDismiss: () => _deleteNotification(doc.reference),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Individual notification tile ─────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isRead;
  final IconData icon;
  final Color iconColor;
  final String relativeTime;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.data,
    required this.isRead,
    required this.icon,
    required this.iconColor,
    required this.relativeTime,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dismissible(
      key: ValueKey(data['createdAt']?.toString() ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: colorScheme.errorContainer,
        child: Icon(Icons.delete_outline_rounded,
            color: colorScheme.onErrorContainer),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: isRead ? Colors.transparent : iconColor.withOpacity(0.06),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isRead
                      ? colorScheme.surfaceContainerHighest
                      : iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isRead ? colorScheme.outline : iconColor,
                ),
              ),
              const SizedBox(width: 14),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row + unread dot
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['title'] ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isRead
                                  ? FontWeight.w400
                                  : FontWeight.w700,
                              color: isRead
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              color: iconColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Body
                    Text(
                      data['body'] ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    // Timestamp
                    Text(
                      relativeTime,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}