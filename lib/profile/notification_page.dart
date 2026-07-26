import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// FIX: import bannerStyleForType alongside NotificationType. This is the
// SAME icon/color function notification_service.dart uses for its
// in-app banner and FCM foreground alerts. Previously this page kept
// its own hand-copied switch statement (_style()) which had drifted out
// of sync — it was missing the workStarted case (used by the new
// "Start Work" OTP feature in business_dashboard_page.dart), so those
// notifications fell through to the generic default icon here even
// though they rang and popped up correctly everywhere else.
//
// By calling the shared function directly instead of maintaining a
// second copy, this page can never go out of sync again — any new
// NotificationType added in notification_service.dart automatically
// gets the right icon/color here too, with zero extra work.
import 'package:callme/profile/notification_service.dart'
    show bannerStyleForType;

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

  // ═══════════════════════════════════════════════════════════
  // NEW: multi-select mode (long-press a tile to enter it, tap
  // other tiles to add/remove them — same pattern as Gmail/WhatsApp).
  // ═══════════════════════════════════════════════════════════
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

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

  void _showSnack(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
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

  // ═══════════════════════════════════════════════════════════
  // NEW: pin / unpin. Stored as a plain `pinned` bool field on the
  // notification doc so it survives app restarts and syncs across
  // devices, same as `read`. Missing/older docs default to false via
  // `data['pinned'] == true` everywhere it's read.
  // ═══════════════════════════════════════════════════════════
  Future<void> _setPinned(String docId, bool pinned) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .update({'pinned': pinned});
    } catch (e) {
      debugPrint('[NOTIF-PAGE] Pin update failed for $docId: $e');
      _showSnack('Failed to update pin');
    }
  }

  Future<void> _togglePinSelected() async {
    if (_selectedIds.isEmpty) return;
    final ids = _selectedIds.toList();

    // If every selected item is already pinned, this action unpins
    // them all; otherwise it pins everything selected. Mirrors how
    // Gmail's "star" bulk action behaves.
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where(FieldPath.documentId, whereIn: ids.length > 10 ? ids.sublist(0, 10) : ids)
        .get();
    final allPinned = snap.docs.every((d) => (d.data())['pinned'] == true);
    final newValue = !allPinned;

    final batch = FirebaseFirestore.instance.batch();
    for (final id in ids) {
      batch.update(
        FirebaseFirestore.instance.collection('notifications').doc(id),
        {'pinned': newValue},
      );
    }
    await batch.commit();
    _showSnack(newValue ? 'Pinned' : 'Unpinned');
    _exitSelectionMode();
  }

  // Delete with a brief "Undo" window instead of an instant, silent
  // removal — makes single deletes (swipe or long-press) feel like a
  // real app instead of a destructive dead-end.
  Future<void> _deleteWithUndo(DocumentSnapshot doc) async {
    final docId = doc.id;
    final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);

    try {
      await FirebaseFirestore.instance.collection('notifications').doc(docId).delete();
    } catch (e) {
      debugPrint('[NOTIF-PAGE] Delete failed for $docId: $e');
      _showSnack('Failed to delete notification');
      return;
    }

    _showSnack(
      'Notification deleted',
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async {
          try {
            await FirebaseFirestore.instance
                .collection('notifications')
                .doc(docId)
                .set(data);
          } catch (e) {
            debugPrint('[NOTIF-PAGE] Undo failed for $docId: $e');
          }
        },
      ),
    );
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${_selectedIds.length} notification'
            '${_selectedIds.length == 1 ? '' : 's'}?'),
        content: const Text('This action cannot be undone.'),
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

    final ids = _selectedIds.toList();
    final batch = FirebaseFirestore.instance.batch();
    for (final id in ids) {
      batch.delete(FirebaseFirestore.instance.collection('notifications').doc(id));
    }
    try {
      await batch.commit();
      _showSnack('${ids.length} notifications deleted');
    } catch (e) {
      debugPrint('[NOTIF-PAGE] Bulk delete failed: $e');
      _showSnack('Failed to delete notifications');
    }
    _exitSelectionMode();
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

  // FIX: _style() removed. Use the shared bannerStyleForType() from
  // notification_service.dart instead — see import comment above.

  // ─── Selection-mode helpers ──────────────────────────────────
  void _enterSelectionMode(String docId) {
    setState(() {
      _selectionMode = true;
      _selectedIds
        ..clear()
        ..add(docId);
    });
  }

  void _toggleSelected(String docId) {
    setState(() {
      if (_selectedIds.contains(docId)) {
        _selectedIds.remove(docId);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(docId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    // NEW: PopScope so the hardware/gesture back button exits
    // selection mode first instead of leaving the page — matches
    // how Gmail/WhatsApp handle back-during-selection.
    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectionMode) _exitSelectionMode();
      },
      child: StreamBuilder<QuerySnapshot>(
        stream: _notifStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('[NOTIF-PAGE] Firestore error: ${snapshot.error}');
            return Scaffold(
              appBar: AppBar(title: const Text('Notifications')),
              body: Center(
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
              ),
            );
          }

          if (!snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(title: const Text('Notifications')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          final docs = snapshot.data!.docs.toList();

          // NEW: pinned items float to the top (like WhatsApp pinned
          // chats), newest-first within each group. Done client-side
          // since Firestore can't orderBy two fields without a doc
          // that has both indexed together on every existing row.
          docs.sort((a, b) {
            final ad = a.data() as Map<String, dynamic>;
            final bd = b.data() as Map<String, dynamic>;
            final ap = ad['pinned'] == true;
            final bp = bd['pinned'] == true;
            if (ap != bp) return ap ? -1 : 1;
            final at = ad['createdAt'];
            final bt = bd['createdAt'];
            final ams = at is Timestamp ? at.millisecondsSinceEpoch : 0;
            final bms = bt is Timestamp ? bt.millisecondsSinceEpoch : 0;
            return bms.compareTo(ams);
          });

          final pinnedCount =
              docs.where((d) => (d.data() as Map<String, dynamic>)['pinned'] == true).length;

          return Scaffold(
            appBar: _buildAppBar(docs),
            body: docs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No notifications yet'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final showPinnedHeader = index == 0 && pinnedCount > 0;
                      final showOthersHeader =
                          pinnedCount > 0 && index == pinnedCount && pinnedCount < docs.length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showPinnedHeader) _sectionHeader('Pinned'),
                          if (showOthersHeader) _sectionHeader('Others'),
                          _buildTile(doc),
                        ],
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // NEW: AppBar swaps smoothly (AnimatedSwitcher) between the normal
  // header and the selection header instead of just snapping.
  PreferredSizeWidget _buildAppBar(List<QueryDocumentSnapshot> docs) {
    if (_selectionMode) {
      final selectedDocs =
          docs.where((d) => _selectedIds.contains(d.id)).toList();
      final allPinned = selectedDocs.isNotEmpty &&
          selectedDocs.every((d) => (d.data() as Map<String, dynamic>)['pinned'] == true);

      return AppBar(
        key: const ValueKey('selection-appbar'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitSelectionMode,
        ),
        title: Text('${_selectedIds.length} selected'),
        actions: [
          IconButton(
            tooltip: allPinned ? 'Unpin' : 'Pin',
            icon: Icon(allPinned ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: _togglePinSelected,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteSelected,
          ),
        ],
      );
    }

    return AppBar(
      key: const ValueKey('normal-appbar'),
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
    );
  }

  Widget _buildTile(QueryDocumentSnapshot doc) {
    final docId = doc.id;
    final data = doc.data() as Map<String, dynamic>;
    final isRead = data['read'] == true;
    final isPinned = data['pinned'] == true;
    final isSelected = _selectedIds.contains(docId);
    final style = bannerStyleForType(data['type'] as String?);

    final businessName = (data['businessName'] ?? '').toString().trim();
    final serviceType = (data['serviceType'] ?? '').toString().trim();
    final hasServiceInfo = businessName.isNotEmpty || serviceType.isNotEmpty;

    return Dismissible(
      key: ValueKey(docId),
      direction: _selectionMode
          ? DismissDirection.none
          : DismissDirection.horizontal,
      // Swipe start→end (left→right): pin/unpin. Doesn't remove the
      // tile — confirmDismiss returns false so it springs back after
      // toggling, same feel as Gmail's archive swipe.
      background: Container(
        color: Colors.amber.shade600,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            color: Colors.white),
      ),
      // Swipe end→start (right→left): delete, with Undo.
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _setPinned(docId, !isPinned);
          return false;
        }
        return true;
      },
      onDismissed: (_) => _deleteWithUndo(doc),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.10)
            : (isRead ? null : Colors.blue.withOpacity(0.04)),
        child: ListTile(
          onTap: () async {
            if (_selectionMode) {
              _toggleSelected(docId);
              return;
            }
            await _markAsRead(doc);
            widget.onNotificationTap?.call(data);
          },
          onLongPress: () {
            if (_selectionMode) {
              _toggleSelected(docId);
            } else {
              _enterSelectionMode(docId);
            }
          },
          leading: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: _selectionMode
                ? CircleAvatar(
                    key: const ValueKey('checkbox'),
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.withOpacity(0.2),
                    child: Icon(
                      isSelected ? Icons.check : Icons.circle_outlined,
                      color: isSelected ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                  )
                : CircleAvatar(
                    key: const ValueKey('icon'),
                    backgroundColor: style.color.withOpacity(0.15),
                    child: Icon(style.icon, color: style.color),
                  ),
          ),
          title: Row(
            children: [
              if (isPinned) ...[
                Icon(Icons.push_pin, size: 13, color: Colors.amber.shade700),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  data['title'] as String? ?? '',
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.w400 : FontWeight.bold,
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
              if (hasServiceInfo) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (serviceType.isNotEmpty)
                      _serviceChip(Icons.miscellaneous_services_rounded, serviceType),
                    if (businessName.isNotEmpty)
                      _serviceChip(Icons.storefront_rounded, businessName),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Text(
                _relativeTime(data['createdAt']),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Small chip used to surface which service/business a notification
  // (booking, approval, rejection) relates to.
  Widget _serviceChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.indigo),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}