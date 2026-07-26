import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:callme/provider/order_service.dart';

// =============================================================
// STATUS CONFIG MODEL
// =============================================================
class _StatusConfig {
  final Color color;
  final Color bgColor;
  final IconData icon;
  final String label;
  final String message;

  const _StatusConfig({
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.label,
    required this.message,
  });
}

// =============================================================
// FIX (NEW): payment-method display config, mirrors the icon/color
// pattern _statusConfig() already uses. Reads `payment.method` off
// the order doc — the same field OrderService.placeOrder() writes
// (PaymentMethod.upi/cash/card/wallet/enquiry) — so this can never
// drift out of sync with what's actually stored.
// =============================================================
class _PaymentMethodConfig {
  final Color color;
  final IconData icon;
  final String label;

  const _PaymentMethodConfig({
    required this.color,
    required this.icon,
    required this.label,
  });
}

_PaymentMethodConfig _paymentMethodConfig(String method) {
  switch (method.toLowerCase()) {
    case 'upi':
      return const _PaymentMethodConfig(
        color: Color(0xFF6C47FF),
        icon: Icons.bolt_rounded,
        label: 'UPI',
      );
    case 'card':
      return const _PaymentMethodConfig(
        color: Color(0xFF0066FF),
        icon: Icons.credit_card_rounded,
        label: 'Card',
      );
    case 'cash':
      return const _PaymentMethodConfig(
        color: Color(0xFFFF8C00),
        icon: Icons.handshake_rounded,
        label: 'Cash',
      );
    case 'wallet':
      return const _PaymentMethodConfig(
        color: Color(0xFF00C896),
        icon: Icons.account_balance_wallet_rounded,
        label: 'Wallet',
      );
    case 'enquiry':
      return const _PaymentMethodConfig(
        color: Color(0xFF8B5CF6),
        icon: Icons.help_rounded,
        label: 'Enquiry',
      );
    default:
      return _PaymentMethodConfig(
        color: Colors.grey.shade600,
        icon: Icons.payments_rounded,
        label: method.isEmpty ? 'Unknown' : method,
      );
  }
}

// =============================================================
// MY ORDERS PAGE  —  StatefulWidget for proper stream lifecycle
// =============================================================
class MyOrdersPage extends StatefulWidget {
  final String phone;

  const MyOrdersPage({super.key, required this.phone});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  // ── Stream ──────────────────────────────────────────────────
  Stream<QuerySnapshot>? _ordersStream;

  // Statuses a customer is allowed to swipe-delete. Mirrors
  // OrderService._deletableStatuses — kept here too (not imported,
  // since that one's private) purely so the swipe can bounce back
  // with an explanatory message BEFORE making a round trip to
  // Firestore, instead of only finding out after OrderService throws.
  static const Set<String> _deletableStatuses = {
    'completed',
    'rejected',
    'cancelled',
  };

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
  }

  void _showSnack(String message, {SnackBarAction? action, Color? bg}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: action,
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  // ── Status config ────────────────────────────────────────────
  // bgColor values here are the LIGHT-mode tints. In dark mode the
  // card uses cfg.color at low opacity instead (see _orderCard),
  // so these pastel backgrounds never have to double as dark colors.
  _StatusConfig _statusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const _StatusConfig(
          color: Color(0xFF00C896),
          bgColor: Color(0xFFE6FBF5),
          icon: Icons.check_circle_rounded,
          label: 'ACCEPTED',
          message: 'Provider confirmed — they will contact you soon',
        );
      case 'completed':
        return const _StatusConfig(
          color: Color(0xFF3B82F6),
          bgColor: Color(0xFFEFF6FF),
          icon: Icons.verified_rounded,
          label: 'COMPLETED',
          message: 'Service completed successfully',
        );
      case 'rejected':
        return const _StatusConfig(
          color: Color(0xFFEF4444),
          bgColor: Color(0xFFFEF2F2),
          icon: Icons.cancel_rounded,
          label: 'REJECTED',
          message: 'Provider rejected this request',
        );
      case 'cancelled':
        return const _StatusConfig(
          color: Color(0xFF6B7280),
          bgColor: Color(0xFFF3F4F6),
          icon: Icons.remove_circle_rounded,
          label: 'CANCELLED',
          message: 'This order has been cancelled',
        );
      case 'enquiry':
        return const _StatusConfig(
          color: Color(0xFF8B5CF6),
          bgColor: Color(0xFFF5F3FF),
          icon: Icons.help_rounded,
          label: 'ENQUIRY',
          message: 'Enquiry sent — awaiting provider response',
        );
      default: // pending
        return const _StatusConfig(
          color: Color(0xFFF59E0B),
          bgColor: Color(0xFFFFFBEB),
          icon: Icons.schedule_rounded,
          label: 'PENDING',
          message: 'Waiting for provider to respond',
        );
    }
  }

  // ── Format date ──────────────────────────────────────────────
  String _formatDate(dynamic ts) {
    try {
      if (ts is Timestamp) {
        final d = ts.toDate();
        const months = [
          '',
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        return '${d.day} ${months[d.month]} ${d.year}';
      }
    } catch (_) {}
    return '-';
  }

  // ── Resolve decline / cancel reason ─────────────────────────
  // Priority: declineReason (canonical) → cancelReason (legacy)
  //           → providerCancelNote (extra legacy) → ''
  String _resolveReason(Map<String, dynamic> data) {
    final fields = [
      'declineReason',
      'cancelReason',
      'providerCancelNote',
    ];
    for (final field in fields) {
      final val = (data[field] ?? '').toString().trim();
      if (val.isNotEmpty) return val;
    }
    return '';
  }

  // ── Cancel order ─────────────────────────────────────────────
  Future<void> _cancelOrder({
    required String orderId,
    required String providerUserId,
    required String userName,
    required String serviceType,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF232030) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel Order?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : null,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this booking?',
          style: TextStyle(color: isDark ? Colors.white70 : null),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await OrderService.userCancelOrder(
        orderId: orderId,
        providerUserId: providerUserId,
        userName: userName,
        serviceType: serviceType,
      );

      if (!mounted) return;
      _showSnack('Order cancelled', bg: Colors.grey.shade700);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to cancel: $e');
    }
  }

  // ── FIX (NEW): pin / unpin ───────────────────────────────────
  Future<void> _togglePin(String orderId, bool currentlyPinned) async {
    try {
      await OrderService.setOrderPinned(
        orderId: orderId,
        pinned: !currentlyPinned,
      );
    } catch (e) {
      _showSnack('Failed to update pin: $e');
    }
  }

  // ── FIX (NEW): delete with Undo, guarded to terminal statuses ──
  // only. OrderService.deleteOrder() re-checks status itself (the
  // authoritative check), but checking here too lets the swipe bounce
  // back immediately with a clear reason instead of round-tripping to
  // Firestore first.
  Future<void> _deleteWithUndo(QueryDocumentSnapshot doc, String status) async {
    if (!_deletableStatuses.contains(status)) {
      _showSnack(
        'You can delete this order once it\'s completed, rejected, or cancelled.',
      );
      return;
    }

    final docId = doc.id;
    final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);

    try {
      await OrderService.deleteOrder(orderId: docId);
    } catch (e) {
      _showSnack('Failed to delete: $e');
      return;
    }

    _showSnack(
      'Order deleted',
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () async {
          try {
            await FirebaseFirestore.instance
                .collection('orders')
                .doc(docId)
                .set(data);
          } catch (e) {
            debugPrint('[MyOrdersPage] Undo failed for $docId: $e');
          }
        },
      ),
    );
  }

  // ── Info row ─────────────────────────────────────────────────
  Widget _infoRow(IconData icon, String text, bool isDark) {
    if (text.isEmpty || text == '-') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.white54 : Colors.grey.shade500),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade800,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FIX (NEW): payment method row — chip with icon/label plus a
  // Paid/Pending badge (skipped for enquiries, which are never paid).
  Widget _paymentRow(Map<String, dynamic> data, bool isEnquiry, bool isDark) {
    if (isEnquiry) return const SizedBox.shrink();

    final payment = (data['payment'] as Map<String, dynamic>?) ?? {};
    final method  = (payment['method'] ?? '').toString();
    if (method.isEmpty) return const SizedBox.shrink();

    final paid = payment['paid'] == true;
    final cfg  = _paymentMethodConfig(method);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 16, color: isDark ? Colors.white54 : Colors.grey.shade500),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cfg.color.withOpacity(isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cfg.icon, size: 12, color: cfg.color),
                const SizedBox(width: 4),
                Text(
                  cfg.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: cfg.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (paid ? const Color(0xFF00C896) : const Color(0xFFF59E0B))
                  .withOpacity(isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              paid ? 'Paid' : 'Payment Pending',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: paid ? const Color(0xFF00C896) : const Color(0xFFF59E0B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Order card ───────────────────────────────────────────────
  Widget _orderCard(QueryDocumentSnapshot doc, bool isDark) {
    final data        = doc.data() as Map<String, dynamic>;
    final schedule    = (data['schedule'] as Map<String, dynamic>?) ?? {};
    final location    = (data['location'] as Map<String, dynamic>?) ?? {};
    final rawStatus   = (data['status'] ?? 'pending').toString();
    final status      = rawStatus.toLowerCase();
    final cfg         = _statusConfig(status);
    final isPinned    = data['pinned'] == true;
    final isDeletable = _deletableStatuses.contains(status);

    // Dark-mode variant of the status banner/box background: instead of
    // reusing the light pastel tint (which would glow oddly on a dark
    // card), it's the status accent color blended at low opacity.
    final Color statusBg = isDark ? cfg.color.withOpacity(0.16) : cfg.bgColor;
    final Color cardBg = isDark ? const Color(0xFF232030) : Colors.white;
    final Color titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final Color messageColor = isDark ? Colors.white60 : Colors.grey.shade600;

    final services = (data['services'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final providerName   = (data['providerName'] ?? '').toString();
    final providerUserId = (data['providerUserId'] ?? '').toString();
    final userName       = (data['userName'] ?? '').toString();
    final serviceType    = (data['serviceType'] ?? 'Service').toString();
    final cancelledBy    = (data['cancelledBy'] ?? '').toString();
    final isEnquiry      = data['isEnquiry'] == true;

    // ── Resolve reason — checks declineReason first (canonical),
    //    then falls back to legacy fields.
    final reason = _resolveReason(data);

    final canCancel  = status == 'pending' || status == 'accepted';
    final showReason =
        reason.isNotEmpty && (status == 'rejected' || status == 'cancelled');

    // Label for the reason box header
    String reasonLabel() {
      if (status == 'rejected') return 'Rejection Reason';
      if (cancelledBy == 'provider') return 'Cancelled by Provider';
      if (cancelledBy == 'user') return 'Cancelled by You';
      return 'Cancellation Reason';
    }

    // FIX (NEW): Dismissible wraps the whole card so a swipe animates
    // the entire tile smoothly, same real-app feel as
    // notification_page.dart's list. Swipe start→end (right) pins,
    // swipe end→start (left) deletes — but only when the order has
    // reached a terminal state; otherwise it bounces back with an
    // explanation instead of silently doing nothing.
    return Dismissible(
      key: ValueKey(doc.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.amber.shade600,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 22),
        child: Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDeletable ? Colors.red : Colors.grey.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        child: Icon(
          isDeletable ? Icons.delete_outline : Icons.lock_outline,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _togglePin(doc.id, isPinned);
          return false; // never actually removes the tile
        }
        // endToStart = delete swipe
        if (!isDeletable) {
          _showSnack(
            'You can delete this order once it\'s completed, rejected, or cancelled.',
          );
          return false;
        }
        return true;
      },
      onDismissed: (_) => _deleteWithUndo(doc, status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: isPinned
              ? Border.all(color: Colors.amber.shade600, width: 1.4)
              : (isDark ? Border.all(color: Colors.white12) : null),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [

            // ── Status banner ────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(cfg.icon, color: cfg.color, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    cfg.label,
                    style: TextStyle(
                      color: cfg.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (isPinned) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.push_pin, size: 13, color: Colors.amber.shade700),
                  ],
                  const Spacer(),
                  // FIX (NEW): explicit pin toggle button — some
                  // people never discover swipe gestures, so this
                  // guarantees pin/delete are reachable by tap too.
                  GestureDetector(
                    onTap: () => _togglePin(doc.id, isPinned),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 16,
                        color: cfg.color.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(data['createdAt']),
                    style: TextStyle(
                      color: cfg.color.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // ── Card body ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Service icon + status message
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.home_repair_service_rounded,
                          color: cfg.color,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              serviceType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cfg.message,
                              style: TextStyle(
                                color: messageColor,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Divider(height: 1, color: isDark ? Colors.white12 : null),
                  const SizedBox(height: 14),

                  // Details
                  if (services.isNotEmpty)
                    _infoRow(
                      Icons.miscellaneous_services_rounded,
                      services.join(', '),
                      isDark,
                    ),
                  _infoRow(
                    Icons.calendar_today_rounded,
                    _formatDate(schedule['date']),
                    isDark,
                  ),
                  _infoRow(
                    Icons.access_time_rounded,
                    (schedule['time'] ?? '-').toString(),
                    isDark,
                  ),
                  _infoRow(
                    Icons.location_on_outlined,
                    (location['address'] ?? '-').toString(),
                    isDark,
                  ),
                  if (providerName.isNotEmpty)
                    _infoRow(
                      Icons.store_rounded,
                      'Provider: $providerName',
                      isDark,
                    ),

                  // FIX (NEW): payment method + paid/pending status.
                  _paymentRow(data, isEnquiry, isDark),

                  // ── Rejection / cancellation reason ──────────
                  if (showReason) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFEF4444).withOpacity(0.12)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFFEF4444).withOpacity(0.4)
                              : const Color(0xFFFCA5A5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFFEF4444),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                reasonLabel(),
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            reason,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFFB91C1C),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Action row
                  Row(
                    children: [
                      // Order ID chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${doc.id.split('_').last}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),

                      const Spacer(),

                      // FIX (NEW): explicit Delete button once the
                      // order is in a terminal state — swipe-to-delete
                      // still works too, but this makes it discoverable
                      // without relying on the gesture.
                      if (isDeletable) ...[
                        GestureDetector(
                          onTap: () => _deleteWithUndo(doc, status),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 15,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Cancel button — only for pending / accepted
                      if (canCancel)
                        GestureDetector(
                          onTap: () => _cancelOrder(
                            orderId: doc.id,
                            providerUserId: providerUserId,
                            userName: userName,
                            serviceType: serviceType,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFFEF4444).withOpacity(0.12)
                                  : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFFEF4444).withOpacity(0.4)
                                    : const Color(0xFFFCA5A5),
                              ),
                            ),
                            child: const Text(
                              'Cancel Order',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = Theme.of(context).scaffoldBackgroundColor;

    if (user == null) {
      return Scaffold(
        backgroundColor: pageBg,
        appBar: _buildAppBar(isDark),
        body: Center(
          child: Text(
            'Please log in to view your orders',
            style: TextStyle(color: isDark ? Colors.white70 : null),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: pageBg,
      appBar: _buildAppBar(isDark),
      body: StreamBuilder<QuerySnapshot>(
        stream: _ordersStream,
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 60, color: Colors.red.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'Something went wrong',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // FIX (NEW): sort pinned-first, newest-first within each
          // group — same client-side approach as notification_page.dart,
          // since Firestore can't orderBy two fields without an index
          // covering every existing doc.
          final orders =
              List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? [])
                ..sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;

                  final aPinned = aData['pinned'] == true;
                  final bPinned = bData['pinned'] == true;
                  if (aPinned != bPinned) return aPinned ? -1 : 1;

                  final aTs = aData['createdAt'];
                  final bTs = bData['createdAt'];
                  final aT = aTs is Timestamp ? aTs.millisecondsSinceEpoch : 0;
                  final bT = bTs is Timestamp ? bTs.millisecondsSinceEpoch : 0;
                  return bT.compareTo(aT);
                });

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 80,
                      color: isDark ? Colors.white24 : Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No Orders Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your bookings will appear here',
                    style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          final pinnedCount =
              orders.where((d) => (d.data() as Map<String, dynamic>)['pinned'] == true).length;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final showPinnedHeader = index == 0 && pinnedCount > 0;
              final showOthersHeader =
                  pinnedCount > 0 && index == pinnedCount && pinnedCount < orders.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showPinnedHeader) _sectionHeader('Pinned', isDark),
                  if (showOthersHeader) _sectionHeader('Others', isDark),
                  _orderCard(orders[index], isDark),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white54 : Colors.grey,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) => AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1B1922) : Colors.white,
        surfaceTintColor: isDark ? const Color(0xFF1B1922) : Colors.white,
        centerTitle: true,
        title: Text(
          'My Orders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
          ),
        ),
      );
}