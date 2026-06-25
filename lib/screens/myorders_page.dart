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

  // ── Status config ────────────────────────────────────────────
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancel Order?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to cancel this booking?'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order cancelled'),
          backgroundColor: Colors.grey.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel: $e')),
      );
    }
  }

  // ── Info row ─────────────────────────────────────────────────
  Widget _infoRow(IconData icon, String text) {
    if (text.isEmpty || text == '-') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Order card ───────────────────────────────────────────────
  Widget _orderCard(QueryDocumentSnapshot doc) {
    final data        = doc.data() as Map<String, dynamic>;
    final schedule    = (data['schedule'] as Map<String, dynamic>?) ?? {};
    final location    = (data['location'] as Map<String, dynamic>?) ?? {};
    final rawStatus   = (data['status'] ?? 'pending').toString();
    final status      = rawStatus.toLowerCase();
    final cfg         = _statusConfig(status);

    final services = (data['services'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final providerName   = (data['providerName'] ?? '').toString();
    final providerUserId = (data['providerUserId'] ?? '').toString();
    final userName       = (data['userName'] ?? '').toString();
    final serviceType    = (data['serviceType'] ?? 'Service').toString();
    final cancelledBy    = (data['cancelledBy'] ?? '').toString();

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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: cfg.bgColor,
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
                const Spacer(),
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
                        color: cfg.bgColor,
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cfg.message,
                            style: TextStyle(
                              color: Colors.grey.shade600,
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
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Details
                if (services.isNotEmpty)
                  _infoRow(
                    Icons.miscellaneous_services_rounded,
                    services.join(', '),
                  ),
                _infoRow(
                  Icons.calendar_today_rounded,
                  _formatDate(schedule['date']),
                ),
                _infoRow(
                  Icons.access_time_rounded,
                  (schedule['time'] ?? '-').toString(),
                ),
                _infoRow(
                  Icons.location_on_outlined,
                  (location['address'] ?? '-').toString(),
                ),
                if (providerName.isNotEmpty)
                  _infoRow(
                    Icons.store_rounded,
                    'Provider: $providerName',
                  ),

                // ── Rejection / cancellation reason ──────────
                if (showReason) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
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
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
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
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${doc.id.split('_').last}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),

                    const Spacer(),

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
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: const Color(0xFFFCA5A5)),
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
    );
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        appBar: _buildAppBar(),
        body: const Center(child: Text('Please log in to view your orders')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: _buildAppBar(),
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
                    const Text(
                      'Something went wrong',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Sort latest first client-side — no composite index needed
          final orders =
              List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? [])
                ..sort((a, b) {
                  final aTs =
                      (a.data() as Map<String, dynamic>)['createdAt'];
                  final bTs =
                      (b.data() as Map<String, dynamic>)['createdAt'];
                  final aT =
                      aTs is Timestamp ? aTs.millisecondsSinceEpoch : 0;
                  final bT =
                      bTs is Timestamp ? bTs.millisecondsSinceEpoch : 0;
                  return bT.compareTo(aT);
                });

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No Orders Yet',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your bookings will appear here',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: orders.length,
            itemBuilder: (context, index) => _orderCard(orders[index]),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'My Orders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 18,
          ),
        ),
      );
}