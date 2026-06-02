import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'provider_profile_page.dart';

class BusinessDashboardPage extends StatefulWidget {
  final String providerId;
  final String businessName;
  final String serviceType;

  const BusinessDashboardPage({
    super.key,
    required this.providerId,
    required this.businessName,
    required this.serviceType,
  });

  @override
  State<BusinessDashboardPage> createState() =>
      _BusinessDashboardPageState();
}

class _BusinessDashboardPageState
    extends State<BusinessDashboardPage>
    with SingleTickerProviderStateMixin {

  // =====================================================
  // CONSTANTS
  // =====================================================

  static const Color _primary   = Color(0xFF0F172A);
  static const Color _accent    = Color(0xFF6366F1);
  static const Color _accentSoft= Color(0xFFEEF2FF);
  static const Color _surface   = Color(0xFFFAFAFC);
  static const Color _card      = Colors.white;

  // =====================================================
  // STATE
  // =====================================================

  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final User? _user             = FirebaseAuth.instance.currentUser;

  late TabController _tabController;

  int _availableCount = 0;
  int _myJobsCount    = 0;

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // =====================================================
  // NORMALIZE
  // =====================================================

  String _n(String v) => v.trim().toLowerCase();

  // =====================================================
  // STREAMS
  // =====================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>> _providerStream() =>
      _db.collection("providers").doc(widget.providerId).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> _availableJobs() =>
      _db
          .collection("orders")
          .orderBy("createdAt", descending: true)
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> _myJobs() =>
      _db
          .collection("orders")
          .where("providerUserId", isEqualTo: _user?.uid ?? "")
          .orderBy("createdAt", descending: true)
          .snapshots();

  // =====================================================
  // ACCEPT ORDER
  // + FCM notification to this provider confirming accept
  // =====================================================

  Future<void> _acceptOrder(String orderId, Map<String, dynamic> orderData) async {
    try {
      final ref = _db.collection("orders").doc(orderId);

      await _db.runTransaction((tx) async {
        final snap   = await tx.get(ref);
        final data   = snap.data() ?? {};
        final assigned = (data["providerUserId"] ?? "").toString();

        if (assigned.isNotEmpty) {
          throw Exception("Already assigned");
        }

        tx.update(ref, {
          "providerId":     widget.providerId,
          "providerUserId": _user?.uid ?? "",
          "providerName":   widget.businessName,
          "status":         "accepted",
          "isAssigned":     true,
          "updatedAt":      FieldValue.serverTimestamp(),
          "lastActionBy":   "provider",
        });
      });

      // Notify provider (self-confirmation) via FCM
      await _sendProviderFcm(
        title:   "✅ Job Accepted",
        body:    "You accepted a ${widget.serviceType} job from "
                 "${orderData['userName'] ?? 'a customer'}. "
                 "Head to My Jobs to track it.",
        type:    "order_accepted",
        orderId: orderId,
      );

      // Also notify the user their order was accepted
      await _notifyUser(
        userId:  (orderData['userId'] ?? "").toString(),
        orderId: orderId,
        title:   "🎉 Provider Accepted Your Order!",
        body:    "${widget.businessName} has accepted your "
                 "${widget.serviceType} booking.",
        type:    "order_accepted",
      );

      _showSnack("Job accepted successfully!", Colors.green);
    } catch (_) {
      _showSnack("This job was already taken.", Colors.red);
    }
  }

  // =====================================================
  // COMPLETE ORDER
  // =====================================================

  Future<void> _completeOrder(String orderId, Map<String, dynamic> orderData) async {
    await _db.collection("orders").doc(orderId).update({
      "status":       "completed",
      "isCompleted":  true,
      "updatedAt":    FieldValue.serverTimestamp(),
      "lastActionBy": "provider",
    });

    await _notifyUser(
      userId:  (orderData['userId'] ?? "").toString(),
      orderId: orderId,
      title:   "✅ Service Completed",
      body:    "Your ${widget.serviceType} service by "
               "${widget.businessName} has been completed!",
      type:    "order_completed",
    );

    _showSnack("Order marked as completed.", Colors.green);
  }

  // =====================================================
  // CANCEL ORDER
  // =====================================================

  Future<void> _cancelOrder(String orderId, String note,
      Map<String, dynamic> orderData) async {
    await _db.collection("orders").doc(orderId).update({
      "status":             "cancelled",
      "providerCancelNote": note.isEmpty
          ? "Provider cancelled this booking"
          : note,
      "cancelledBy":        "provider",
      "providerId":         "",
      "providerUserId":     "",
      "providerName":       "",
      "isAssigned":         false,
      "updatedAt":          FieldValue.serverTimestamp(),
      "lastActionBy":       "provider",
    });

    await _notifyUser(
      userId:  (orderData['userId'] ?? "").toString(),
      orderId: orderId,
      title:   "❌ Booking Cancelled",
      body:    "${widget.businessName} cancelled your booking. "
               "Reason: ${note.isEmpty ? 'Not specified' : note}",
      type:    "order_cancelled",
    );

    _showSnack("Order cancelled.", Colors.orange);
  }

  // =====================================================
  // FCM — SEND TO THIS PROVIDER (self)
  // Used to confirm actions on provider's own device.
  // =====================================================

  Future<void> _sendProviderFcm({
    required String title,
    required String body,
    required String type,
    required String orderId,
  }) async {
    try {
      final doc = await _db
          .collection("providers")
          .doc(widget.providerId)
          .get();

      final token = (doc.data()?["fcmToken"] ?? "").toString().trim();
      if (token.isEmpty) return;

      // In-app notification
      await _db.collection("notifications").add({
        "userType":   "provider",
        "providerId": widget.providerId,
        "orderId":    orderId,
        "title":      title,
        "body":       body,
        "type":       type,
        "read":       false,
        "createdAt":  FieldValue.serverTimestamp(),
      });

      // FCM queue (Cloud Function picks this up)
      await _db.collection("fcm_queue").add({
        "token":      token,
        "title":      title,
        "body":       body,
        "type":       type,
        "orderId":    orderId,
        "providerId": widget.providerId,
        "sent":       false,
        "createdAt":  FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("PROVIDER FCM ERROR: $e");
    }
  }

  // =====================================================
  // FCM — NOTIFY USER about order status change
  // =====================================================

  Future<void> _notifyUser({
    required String userId,
    required String orderId,
    required String title,
    required String body,
    required String type,
  }) async {
    if (userId.isEmpty) return;

    try {
      // In-app notification
      await _db.collection("notifications").add({
        "userType":  "user",
        "userId":    userId,
        "orderId":   orderId,
        "title":     title,
        "body":      body,
        "type":      type,
        "read":      false,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Get user FCM token from users collection
      final userDocs = await _db
          .collection("users")
          .where("firebaseUid", isEqualTo: userId)
          .limit(1)
          .get();

      if (userDocs.docs.isEmpty) return;

      final token =
          (userDocs.docs.first.data()["fcmToken"] ?? "").toString().trim();

      if (token.isEmpty) return;

      await _db.collection("fcm_queue").add({
        "token":     token,
        "title":     title,
        "body":      body,
        "type":      type,
        "orderId":   orderId,
        "userId":    userId,
        "sent":      false,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("USER NOTIFY ERROR: $e");
    }
  }

  // =====================================================
  // CANCEL DIALOG
  // =====================================================

  Future<void> _showCancelDialog(
      String orderId, Map<String, dynamic> orderData) async {
    final ctrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:        Colors.red.withOpacity(.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.cancel_outlined,
                    color: Colors.red, size: 28),
              ),
              const SizedBox(height: 16),

              const Text(
                "Cancel Job",
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Tell the customer why you're cancelling.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 18),

              TextField(
                controller: ctrl,
                maxLines:   4,
                decoration: InputDecoration(
                  hintText:  "Cancellation reason (optional)...",
                  filled:    true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Keep Job"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        await _cancelOrder(
                            orderId, ctrl.text.trim(), orderData);
                        if (mounted) Navigator.pop(ctx);
                      },
                      child: const Text("Cancel Job",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // SNACKBAR
  // =====================================================

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // =====================================================
  // STATUS HELPERS
  // =====================================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "accepted":  return const Color(0xFF10B981);
      case "completed": return const Color(0xFF3B82F6);
      case "cancelled": return const Color(0xFFEF4444);
      case "enquiry":   return const Color(0xFFF59E0B);
      default:          return _accent;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case "accepted":  return Icons.check_circle_rounded;
      case "completed": return Icons.verified_rounded;
      case "cancelled": return Icons.cancel_rounded;
      case "enquiry":   return Icons.help_rounded;
      default:          return Icons.schedule_rounded;
    }
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _providerStream(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: _surface,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final provider = snap.data?.data() ?? {};

        // ── WAITING FOR APPROVAL STATE ────────────────────

        if (provider["status"] != "approved") {
          return Scaffold(
            backgroundColor: _surface,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding:      const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color:        _accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.hourglass_top_rounded,
                        size:  56,
                        color: _accent,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      "Pending Approval",
                      style: TextStyle(
                        fontSize:   26,
                        fontWeight: FontWeight.bold,
                        color:      _primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Your account is under review.\n"
                      "You'll receive a notification once approved.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:    Colors.grey.shade600,
                        fontSize: 15,
                        height:   1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color:        _accentSoft,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: _accent.withOpacity(.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              color:  Colors.orange,
                              shape:  BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Status: Under Review",
                            style: TextStyle(
                              color:      _accent,
                              fontWeight: FontWeight.w600,
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

        // ── MAIN DASHBOARD ────────────────────────────────

        return Scaffold(
          backgroundColor: _surface,
          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildJobsList(_availableJobs(), isAvailable: true),
                    _buildJobsList(_myJobs(),         isAvailable: false),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =====================================================
  // HEADER
  // =====================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      decoration: const BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        children: [

          // ── TOP ROW ──────────────────────────────────

          Row(
            children: [
              // Business icon
              Container(
                width:  58,
                height: 58,
                decoration: BoxDecoration(
                  color:        Colors.white.withOpacity(.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(.15)),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size:  26,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 7, height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ADE80),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.serviceType,
                          style: TextStyle(
                            color:    Colors.white.withOpacity(.65),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Profile button
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProviderProfilePage(providerId: widget.providerId),
                  ),
                ),
                child: Container(
                  width:  50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(.12),
                    border: Border.all(
                        color: Colors.white.withOpacity(.2)),
                  ),
                  child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── STATS ROW ─────────────────────────────────

          Row(
            children: [
              _headerStat("Available", _availableCount, const Color(0xFF818CF8)),
              const SizedBox(width: 12),
              _headerStat("My Jobs",   _myJobsCount,    const Color(0xFF34D399)),
            ],
          ),

          const SizedBox(height: 20),

          // ── TAB BAR ───────────────────────────────────

          Container(
            height: 52,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color:        Colors.white.withOpacity(.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.circular(13),
              ),
              indicatorSize:          TabBarIndicatorSize.tab,
              dividerColor:           Colors.transparent,
              labelColor:             _accent,
              unselectedLabelColor:   Colors.white60,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: "Available Jobs"),
                Tab(text: "My Jobs"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color:        Colors.white.withOpacity(.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(.10)),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color:        color.withOpacity(.20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  "$count",
                  style: TextStyle(
                    color:      color,
                    fontWeight: FontWeight.bold,
                    fontSize:   15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color:    Colors.white.withOpacity(.75),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // JOBS LIST
  // =====================================================

  Widget _buildJobsList(
    Stream<QuerySnapshot<Map<String, dynamic>>> stream, {
    required bool isAvailable,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: _accent));
        }

        final allDocs = snapshot.data!.docs;

        // Filter
        final docs = allDocs.where((doc) {
          final data     = doc.data();
          final status   = _n(data["status"]      ?? "");
          final assigned = (data["providerUserId"] ?? "").toString();
          final orderSvc = _n(data["serviceType"]  ?? "");
          final mySvc    = _n(widget.serviceType);

          if (isAvailable) {
            return (status == "pending" || status == "enquiry") &&
                assigned.isEmpty &&
                orderSvc == mySvc;
          }
          return assigned == (_user?.uid ?? "");
        }).toList();

        // Update header counts
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            if (isAvailable) _availableCount = docs.length;
            else             _myJobsCount    = docs.length;
          });
        });

        if (docs.isEmpty) {
          return _emptyState(isAvailable);
        }

        return ListView.builder(
          padding:   const EdgeInsets.fromLTRB(16, 20, 16, 24),
          itemCount: docs.length,
          itemBuilder: (_, i) => _jobCard(docs[i], isAvailable),
        );
      },
    );
  }

  // =====================================================
  // JOB CARD
  // =====================================================

  Widget _jobCard(
      DocumentSnapshot<Map<String, dynamic>> doc, bool isAvailable) {
    final data      = doc.data()!;
    final status    = (data["status"]   ?? "pending").toString();
    final payment   = (data["payment"]  as Map<String, dynamic>?) ?? {};
    final location  = (data["location"] as Map<String, dynamic>?) ?? {};
    final schedule  = (data["schedule"] as Map<String, dynamic>?) ?? {};
    final createdAt = data["createdAt"] as Timestamp?;

    final String dateStr = createdAt != null
        ? DateFormat("dd MMM yyyy • hh:mm a").format(createdAt.toDate())
        : "-";

    final Color  sColor = _statusColor(status);
    final double amount =
        (payment["totalAmount"] ?? 0).toDouble();

    return Container(
      margin:  const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color:        _card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(.05),
            blurRadius: 16,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [

          // ── CARD TOP — status stripe ───────────────

          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color:        sColor.withOpacity(.06),
              borderRadius: const BorderRadius.only(
                topLeft:  Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Icon(_statusIcon(status), color: sColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color:      sColor,
                    fontWeight: FontWeight.bold,
                    fontSize:   12,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: TextStyle(
                    color:    Colors.grey.shade400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // ── CARD BODY ──────────────────────────────

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Customer name + service tag
                Row(
                  children: [
                    Container(
                      width:  46,
                      height: 46,
                      decoration: BoxDecoration(
                        color:        _accentSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          (data["userName"] ?? "U")
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            color:      _accent,
                            fontWeight: FontWeight.bold,
                            fontSize:   20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data["userName"] ?? "Unknown Customer",
                            style: const TextStyle(
                              fontSize:   17,
                              fontWeight: FontWeight.bold,
                              color:      _primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.serviceType,
                            style: TextStyle(
                              color:    Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                _divider(),
                const SizedBox(height: 16),

                // Info rows
                _infoRow(Icons.phone_rounded,
                    data["phone"] ?? "-"),
                const SizedBox(height: 10),
                _infoRow(Icons.location_on_rounded,
                    location["address"] ?? "-"),
                const SizedBox(height: 10),
                _infoRow(Icons.schedule_rounded,
                    "${schedule["time"] ?? "-"}  ·  $dateStr"),

                if ((data["note"] ?? "").toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _infoRow(Icons.notes_rounded, data["note"]),
                ],

                const SizedBox(height: 18),

                // Amount banner
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color:        _primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.currency_rupee_rounded,
                          color: Colors.white70, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        "Total Amount",
                        style: TextStyle(
                          color:    Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "₹${amount % 1 == 0 ? amount.toInt() : amount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color:      Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize:   22,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── ACTION BUTTONS ─────────────────────

                if (isAvailable)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _acceptOrder(doc.id, data),
                          icon:  const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18),
                          label: const Text("Accept Job",
                              style: TextStyle(
                                  color:      Colors.white,
                                  fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            elevation:       0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => _showCancelDialog(doc.id, data),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),

                if (!isAvailable && status == "accepted")
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _completeOrder(doc.id, data),
                          icon:  const Icon(Icons.verified_rounded,
                              color: Colors.white, size: 18),
                          label: const Text("Mark Complete",
                              style: TextStyle(
                                  color:      Colors.white,
                                  fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            elevation:       0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => _showCancelDialog(doc.id, data),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),

                if (!isAvailable && status == "completed")
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:        const Color(0xFF3B82F6).withOpacity(.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_rounded,
                            color: Color(0xFF3B82F6), size: 18),
                        SizedBox(width: 8),
                        Text(
                          "Job Completed",
                          style: TextStyle(
                            color:      Color(0xFF3B82F6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // EMPTY STATE
  // =====================================================

  Widget _emptyState(bool isAvailable) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color:        _accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAvailable
                    ? Icons.work_outline_rounded
                    : Icons.assignment_outlined,
                size:  52,
                color: _accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isAvailable ? "No Available Jobs" : "No Jobs Yet",
              style: const TextStyle(
                fontSize:   22,
                fontWeight: FontWeight.bold,
                color:      _primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isAvailable
                  ? "New ${widget.serviceType} orders will appear here automatically."
                  : "Jobs you accept will show up here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color:    Colors.grey.shade500,
                fontSize: 14,
                height:   1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // HELPERS
  // =====================================================

Widget _infoRow(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color:        _accentSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _accent, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              value.isEmpty ? "-" : value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize:   14,
                color:      Color(0xFF374151),
                height:     1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
        height: 1,
        color:  const Color(0xFFF1F5F9),
      );
}
