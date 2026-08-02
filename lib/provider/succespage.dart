import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'provider_dashboard.dart';
// for notifyProviderOfDecision

class SuccessPage extends StatefulWidget {
  final String businessName;
  final String providerType;
  final String serviceType;

  const SuccessPage({
    super.key,
    required this.businessName,
    required this.providerType,
    required this.serviceType,
  });

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final User?             _user = FirebaseAuth.instance.currentUser;

  // Tracks the previous status so we can detect transitions
  String? _previousStatus;

  // Whether we've already notified admin for this registration session
  bool _adminNotified = false;

  // Stream of the provider document
  late final Stream<QuerySnapshot> _providerStream;
  StreamSubscription<QuerySnapshot>? _statusSub;

  @override
  void initState() {
    super.initState();

    _providerStream = _db
        .collection('providers')
        .where('userId', isEqualTo: _user?.uid ?? '')
        .limit(1)
        .snapshots();

    // Listen for status transitions (pending → approved/rejected)
    _statusSub = _providerStream.listen((snap) {
      if (snap.docs.isEmpty) return;
      final data   = snap.docs.first.data() as Map<String, dynamic>;
      final status = (data['status'] ?? 'pending').toString();

      // First snapshot: seed previousStatus and optionally notify admin
      if (_previousStatus == null) {
        _previousStatus = status;
        if (status == 'pending' && !_adminNotified) {
          _notifyAdminOfRegistration(snap.docs.first.id, data);
        }
        return;
      }

      // Status transition detected
      if (_previousStatus != status) {
        _previousStatus = status;
        if (status == 'approved' || status == 'rejected') {
          _handleStatusChange(status);
        }
      }
    });
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }

  // =====================================================
  // NOTIFY ADMIN — fires when provider first registers
  // Writes to notifications (receiverId = adminUid) and
  // queues FCM push so admin gets notified even if app is closed.
  // =====================================================

  Future<void> _notifyAdminOfRegistration(
      String providerId, Map<String, dynamic> data) async {
    _adminNotified = true;

    try {
      final business     = (data['business'] as Map<String, dynamic>?) ?? {};
      final businessName = (business['businessName'] ?? data['providerName'] ?? widget.businessName).toString();
      final ownerName    = (business['ownerName']    ?? '').toString();
      final serviceType  = (data['serviceType']      ?? widget.serviceType).toString();
      final phone        = (business['phone']        ?? '').toString();

      const title = '🆕 New Provider Registration';
      final body  =
          '$businessName by $ownerName registered as a '
          '$serviceType provider and is awaiting approval.';

      // Read admin FCM token from admin_config/fcm
      final configDoc  = await _db.doc('admin_config/fcm').get();
      final adminToken = (configDoc.data()?['token'] ?? '').toString().trim();
      final adminUid   = (configDoc.data()?['adminUid'] ?? '').toString().trim();

      // In-app notification for admin
      if (adminUid.isNotEmpty) {
        await _db.collection('notifications').add({
          'receiverId':   adminUid,           // ← admin's Auth UID
          'role':         'admin',
          'providerId':   providerId,
          'businessName': businessName,
          'ownerName':    ownerName,
          'phone':        phone,
          'serviceType':  serviceType,
          'title':        title,
          'body':         body,
          'type':         'provider_registered',
          'read':         false,
          'createdAt':    FieldValue.serverTimestamp(),
        });
      }

      // FCM push to admin device
      if (adminToken.isNotEmpty) {
        await _db.collection('fcm_queue').add({
          'token':        adminToken,
          'receiverId':   adminUid,
          'title':        title,
          'body':         body,
          'type':         'provider_registered',
          'providerId':   providerId,
          'businessName': businessName,
          'ownerName':    ownerName,
          'serviceType':  serviceType,
          'phone':        phone,
          'data': {
            'type':       'provider_registered',
            'providerId': providerId,
          },
          'sent':      false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('[SuccessPage] Admin notified of registration');
    } catch (e) {
      debugPrint('[SuccessPage] _notifyAdminOfRegistration error: $e');
    }
  }

  // =====================================================
  // HANDLE STATUS CHANGE — show provider an in-app alert
  // The actual notification doc was already written by
  // AdminDashboard.notifyProviderOfDecision() when admin tapped
  // Approve/Reject. This method shows the UI response.
  // =====================================================

  void _handleStatusChange(String newStatus) {
    if (!mounted) return;

    final isApproved = newStatus == 'approved';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B1922) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1D2E);
    final subColor = isDark ? Colors.white60 : Colors.grey[600];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (isApproved ? Colors.green : Colors.red)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isApproved
                    ? Icons.verified_rounded
                    : Icons.cancel_rounded,
                color: isApproved ? Colors.green : Colors.red,
                size:  56,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isApproved ? 'You are Approved!' : 'Registration Rejected',
              style: TextStyle(
                fontSize:   20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isApproved
                  ? 'Congratulations! Your business has been approved. '
                    'You can now start accepting orders.'
                  : 'Sorry, your registration was not approved. '
                    'Please contact support for more information.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:    subColor,
                fontSize: 14,
                height:   1.5,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isApproved ? Colors.green : Colors.grey,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                isApproved ? 'Go to Dashboard' : 'OK',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // STATUS COLOR HELPER
  // =====================================================

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default:         return Colors.orange;
    }
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121016) : const Color(0xFFF4F6FA);
    final cardBg = isDark ? const Color(0xFF1B1922) : Colors.white;
    final textHigh = isDark ? Colors.white : const Color(0xFF1A1D2E);
    final textMid = isDark ? Colors.white60 : Colors.grey[600];
    final textLow = isDark ? Colors.white38 : Colors.grey[500];

    return Scaffold(
      backgroundColor: bgColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: _providerStream,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.data!.docs.isEmpty) {
            return Center(
              child: Text('Provider not found',
                  style: TextStyle(color: textHigh)),
            );
          }

          final doc  = snap.data!.docs.first;
          final data = doc.data() as Map<String, dynamic>;

          final status      = data['status'] ?? 'pending';
          final providerId  = doc.id;
          final statusColor = _statusColor(status);

          // Resolve business name safely from both schema locations
          final business     = (data['business'] as Map<String, dynamic>?) ?? {};
          final businessName =
              (business['businessName'] ?? data['providerName'] ?? widget.businessName).toString();
          final resolvedServiceType =
              (data['serviceType'] ?? widget.serviceType).toString();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size:  80,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Registration Submitted',
                    style: TextStyle(
                      fontSize:   26,
                      fontWeight: FontWeight.bold,
                      color: textHigh,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Your business is under review.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textMid),
                  ),

                  const SizedBox(height: 28),

                  // Info card
                  Container(
                    width:   double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color:        cardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          businessName,
                          style: TextStyle(
                            fontSize:   20,
                            fontWeight: FontWeight.bold,
                            color: textHigh,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Type: ${data['providerType'] ?? widget.providerType}',
                            style: TextStyle(color: textMid)),
                        Text('Service: $resolvedServiceType',
                            style: TextStyle(color: textMid)),
                        const SizedBox(height: 12),

                        // Status chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color:        statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color:      statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // Waiting message while pending
                        if (status == 'pending') ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width:  14,
                                height: 14,
                                child:  CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Waiting for admin approval...',
                                style: TextStyle(
                                  color:    textLow,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Dashboard button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (status != 'approved') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Waiting for admin approval. '
                                "You'll be notified once approved."),
                            ),
                          );
                          return;
                        }

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BusinessDashboardPage(
                              providerId:   providerId,
                              businessName: businessName,
                              serviceType:  resolvedServiceType,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Go to Dashboard'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}