import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String search = "";
  String statusFilter = "all";
  String serviceFilter = "all";

  final TextEditingController searchController = TextEditingController();

  // ─── 9 services ───────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> kServices = [
    {'key': 'all',        'label': 'All',       'icon': Icons.dashboard_rounded},
    {'key': 'cleaning',   'label': 'Cleaning',  'icon': Icons.cleaning_services},
    {'key': 'plumbing',   'label': 'Plumbing',  'icon': Icons.plumbing},
    {'key': 'education',  'label': 'Education', 'icon': Icons.school_rounded},
    {'key': 'hotel',      'label': 'Hotel',     'icon': Icons.hotel_rounded},
    {'key': 'resorts',    'label': 'Resorts',   'icon': Icons.beach_access_rounded},
    {'key': 'laundry',    'label': 'Laundry',   'icon': Icons.local_laundry_service},
    {'key': 'water',      'label': 'Water',     'icon': Icons.water_drop_rounded},
    {'key': 'salon',      'label': 'Salon',     'icon': Icons.content_cut},
    {'key': 'civil', 'label': 'Civil','icon': Icons.construction},
  ];

  static const List<String> kStatuses = [
    'all', 'pending', 'accepted', 'completed', 'cancelled', 'rejected'
  ];

  // ─── Stream ────────────────────────────────────────────────────────────────
  Stream<QuerySnapshot<Map<String, dynamic>>> ordersStream() =>
      firestore.collection("orders").snapshots();

  // ─── Helpers ───────────────────────────────────────────────────────────────
  Color statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'accepted':  return const Color(0xFF16A34A);
      case 'completed': return const Color(0xFF2563EB);
      case 'cancelled': return const Color(0xFFDC2626);
      case 'rejected':  return const Color(0xFFEF4444);
      default:          return const Color(0xFFF59E0B);
    }
  }

  IconData statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'accepted':  return Icons.check_circle_rounded;
      case 'completed': return Icons.task_alt_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      case 'rejected':  return Icons.remove_circle_rounded;
      default:          return Icons.pending_actions_rounded;
    }
  }

  IconData serviceIcon(String s) {
    final v = s.toLowerCase();
    if (v.contains('clean'))    return Icons.cleaning_services;
    if (v.contains('plumb'))    return Icons.plumbing;
    if (v.contains('educ'))     return Icons.school_rounded;
    if (v.contains('hotel'))    return Icons.hotel_rounded;
    if (v.contains('resort'))   return Icons.beach_access_rounded;
    if (v.contains('laundry'))  return Icons.local_laundry_service;
    if (v.contains('water'))    return Icons.water_drop_rounded;
    if (v.contains('salon'))    return Icons.content_cut;
    if (v.contains('electric')) return Icons.electrical_services;
    return Icons.miscellaneous_services;
  }

  Color serviceColor(String s) {
    final v = s.toLowerCase();
    if (v.contains('clean'))    return const Color(0xFF0EA5E9);
    if (v.contains('plumb'))    return const Color(0xFF64748B);
    if (v.contains('educ'))     return const Color(0xFF8B5CF6);
    if (v.contains('hotel'))    return const Color(0xFFF59E0B);
    if (v.contains('resort'))   return const Color(0xFF10B981);
    if (v.contains('laundry'))  return const Color(0xFF3B82F6);
    if (v.contains('water'))    return const Color(0xFF06B6D4);
    if (v.contains('salon'))    return const Color(0xFFEC4899);
    if (v.contains('electric')) return const Color(0xFFEAB308);
    return const Color(0xFF6366F1);
  }

  /// Extract providerName from either top-level or nested provider map
  String _providerName(Map<String, dynamic> data) {
    final top = (data['providerName'] ?? '').toString().trim();
    if (top.isNotEmpty) return top;
    final nested = (data['provider']?['providerName'] ?? '').toString().trim();
    if (nested.isNotEmpty) return nested;
    return 'Not Assigned';
  }

  /// Extract userName from either top-level or nested user map
  String _userName(Map<String, dynamic> data) {
    final top = (data['userName'] ?? '').toString().trim();
    if (top.isNotEmpty) return top;
    return (data['user']?['name'] ?? 'Unknown User').toString();
  }

  /// Extract address from top-level or nested location map
  String _address(Map<String, dynamic> data) {
    final top = (data['address'] ?? '').toString().trim();
    if (top.isNotEmpty) return top;
    return (data['location']?['address'] ?? '-').toString();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FB),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: ordersStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(snapshot.error.toString(), textAlign: TextAlign.center),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _emptyState();
            }

            var docs = snapshot.data!.docs;

            // Sort newest first
            docs.sort((a, b) {
              final aT = a.data()['createdAt'];
              final bT = b.data()['createdAt'];
              if (aT is Timestamp && bT is Timestamp) {
                return bT.toDate().compareTo(aT.toDate());
              }
              return 0;
            });

            // Filter
            final filtered = docs.where((doc) {
              final d = doc.data();
              final svc = (d['serviceType'] ?? d['serviceName'] ?? '').toString().toLowerCase();
              final status = (d['status'] ?? 'pending').toString().toLowerCase();
              final uname = _userName(d).toLowerCase();
              final email = (d['email'] ?? d['user']?['email'] ?? '').toString().toLowerCase();
              final phone = (d['phone'] ?? d['user']?['phone'] ?? '').toString().toLowerCase();
              final prov  = _providerName(d).toLowerCase();
              final oid   = (d['orderId'] ?? doc.id).toString().toLowerCase();

              final matchSearch = search.isEmpty ||
                  uname.contains(search) ||
                  email.contains(search) ||
                  phone.contains(search) ||
                  svc.contains(search) ||
                  prov.contains(search) ||
                  oid.contains(search);

              final matchStatus  = statusFilter == 'all' || status == statusFilter;
              final matchService = serviceFilter == 'all' || svc.contains(serviceFilter);

              return matchSearch && matchStatus && matchService;
            }).toList();

            // Count per service for badges
            Map<String, int> svcCounts = {'all': docs.length};
            for (final svc in kServices.skip(1)) {
              final k = svc['key'] as String;
              svcCounts[k] = docs.where((d) {
                final t = (d.data()['serviceType'] ?? d.data()['serviceName'] ?? '').toString().toLowerCase();
                return t.contains(k);
              }).length;
            }

            return Column(
              children: [
                _buildHeader(filtered.length, svcCounts),
                Expanded(
                  child: filtered.isEmpty
                      ? _noMatch()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) => _orderCard(filtered[i].data(), filtered[i].id),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Order Card ────────────────────────────────────────────────────────────
  Widget _orderCard(Map<String, dynamic> d, String docId) {
    final orderId     = (d['orderId'] ?? docId).toString();
    final userName    = _userName(d);
    final email       = (d['email']   ?? d['user']?['email']  ?? '-').toString();
    final phone       = (d['phone']   ?? d['user']?['phone']  ?? '-').toString();
    final service     = (d['serviceType'] ?? d['serviceName'] ?? 'Service').toString();
    final providerName = _providerName(d);
    final address     = _address(d);
    final status      = (d['status'] ?? 'pending').toString();
    final paid        = d['payment']?['paid'] ?? false;
    final payMethod   = (d['payment']?['method'] ?? '-').toString().toUpperCase();
    final amount      = d['totalAmount'] ?? d['payment']?['totalAmount'] ?? 0;
    final services    = (d['services'] as List?)?.cast<dynamic>() ?? [];
    final time        = d['schedule']?['time'] ?? d['time'] ?? '-';
    final providerId  = (d['providerId'] ?? d['provider']?['providerId'] ?? '-').toString();
    final visitType   = (d['visitType'] ?? '-').toString();
    final note        = (d['note'] ?? d['location']?['note'] ?? '').toString();
    final isCompleted = d['isCompleted'] ?? false;
    final isAssigned  = d['isAssigned'] ?? false;
    final lastActionBy = (d['lastActionBy'] ?? '-').toString();

    final Timestamp? schedDate  = d['schedule']?['date'] ?? d['date'];
    final Timestamp? createdAt  = d['createdAt'];
    final Timestamp? acceptedAt = d['acceptedAt'];
    final Timestamp? completedAt = d['completedAt'];
    final Timestamp? updatedAt  = d['updatedAt'];

    String fmt(Timestamp? t, {String pattern = 'dd MMM yyyy'}) =>
        t == null ? '-' : DateFormat(pattern).format(t.toDate());

    final svcColor = serviceColor(service);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          // ── Coloured top strip ──
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [svcColor, svcColor.withOpacity(.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(serviceIcon(service), color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          letterSpacing: .4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        userName,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _badge(
                            statusIcon(status),
                            status.toUpperCase(),
                            Colors.white,
                            Colors.white.withOpacity(.22),
                          ),
                          _badge(
                            paid ? Icons.check_circle_outline : Icons.unpublished_outlined,
                            paid ? 'PAID' : 'UNPAID',
                            Colors.white,
                            Colors.white.withOpacity(.22),
                          ),
                          if (isAssigned)
                            _badge(Icons.engineering_rounded, 'ASSIGNED', Colors.white, Colors.white.withOpacity(.22)),
                          if (isCompleted)
                            _badge(Icons.task_alt_rounded, 'DONE', Colors.white, Colors.white.withOpacity(.22)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Amount Banner ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Amount', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                          const SizedBox(height: 4),
                          Text(
                            '₹${amount.toString()}',
                            style: TextStyle(
                              color: svcColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: svcColor.withOpacity(.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          payMethod,
                          style: TextStyle(color: svcColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ── Timeline Row ──
                _sectionTitle('Timeline'),
                const SizedBox(height: 10),
                _timelineRow([
                  ('Created',   fmt(createdAt, pattern: 'dd MMM yy • hh:mm a')),
                  ('Accepted',  fmt(acceptedAt, pattern: 'dd MMM yy • hh:mm a')),
                  ('Completed', fmt(completedAt, pattern: 'dd MMM yy • hh:mm a')),
                ], svcColor),

                const SizedBox(height: 18),

                // ── Customer Info ──
                _sectionTitle('Customer'),
                const SizedBox(height: 10),
                _infoGrid([
                  (Icons.person_rounded,      'Name',    userName),
                  (Icons.phone_rounded,        'Phone',   phone),
                  (Icons.email_rounded,        'Email',   email),
                  (Icons.location_on_rounded,  'Address', address),
                  if (note.isNotEmpty)
                    (Icons.note_rounded,       'Note',    note),
                  if (visitType.isNotEmpty && visitType != '-')
                    (Icons.directions_walk_rounded, 'Visit Type', visitType),
                ]),

                const SizedBox(height: 18),

                // ── Provider Info ──
                _sectionTitle('Provider'),
                const SizedBox(height: 10),
                _infoGrid([
                  (Icons.engineering_rounded,   'Provider',    providerName),
                  (Icons.badge_rounded,          'Provider ID', providerId),
                  (Icons.schedule_rounded,       'Visit Time',  '${fmt(schedDate)} • $time'),
                  (Icons.update_rounded,         'Updated',     fmt(updatedAt, pattern: 'dd MMM yy • hh:mm a')),
                  (Icons.person_pin_circle_rounded, 'Last Action', lastActionBy.toUpperCase()),
                ]),

                const SizedBox(height: 18),

                // ── Order Meta ──
                _sectionTitle('Order Details'),
                const SizedBox(height: 10),
                _infoGrid([
                  (Icons.receipt_long_rounded, 'Order ID', orderId),
                  (Icons.calendar_month_rounded, 'Created', fmt(createdAt, pattern: 'dd MMM yyyy • hh:mm a')),
                ]),

                // ── Services List ──
                if (services.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _sectionTitle('Selected Services'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: services.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: svcColor.withOpacity(.08),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: svcColor.withOpacity(.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 13, color: svcColor),
                            const SizedBox(width: 6),
                            Text(
                              item.toString(),
                              style: TextStyle(
                                color: svcColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Timeline Row ──────────────────────────────────────────────────────────
  Widget _timelineRow(List<(String, String)> items, Color color) {
    return Row(
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: item.$2 == '-' ? const Color(0xFFF3F4F6) : color.withOpacity(.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: item.$2 == '-' ? const Color(0xFFE5E7EB) : color.withOpacity(.4),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: item.$2 == '-' ? const Color(0xFF9CA3AF) : color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.$1,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: item.$2 == '-' ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 42),
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Info Grid ─────────────────────────────────────────────────────────────
  Widget _infoGrid(List<(IconData, String, String)> items) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.$1, size: 16, color: const Color(0xFF4F46E5)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.$2, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        item.$3.isEmpty ? '-' : item.$3,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Section Title ─────────────────────────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
      ],
    );
  }

  // ─── Badge ─────────────────────────────────────────────────────────────────
  Widget _badge(IconData icon, String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(40)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(int count, Map<String, int> svcCounts) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Orders Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                      Text('$count orders shown', style: const TextStyle(color: Colors.white60, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              height: 52,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: TextField(
                controller: searchController,
                onChanged: (v) => setState(() => search = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search by name, phone, email, order ID…',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: search.isNotEmpty
                      ? IconButton(
                          onPressed: () { searchController.clear(); setState(() => search = ''); },
                          icon: const Icon(Icons.close_rounded),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Service filter ──
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: kServices.map((svc) {
                final k = svc['key'] as String;
                final selected = serviceFilter == k;
                final cnt = svcCounts[k] ?? 0;
                return GestureDetector(
                  onTap: () => setState(() => serviceFilter = k),
                  child: Container(
                    width: 68,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.white.withOpacity(.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          svc['icon'] as IconData,
                          size: 22,
                          color: selected ? const Color(0xFF4F46E5) : Colors.white70,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          svc['label'] as String,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: selected ? const Color(0xFF4F46E5) : Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (k != 'all') ...[
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFF4F46E5) : Colors.white.withOpacity(.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$cnt',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: selected ? Colors.white : Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // ── Status filter ──
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: kStatuses.map((s) {
                final selected = statusFilter == s;
                return GestureDetector(
                  onTap: () => setState(() => statusFilter = s),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.white.withOpacity(.15),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text(
                      s.toUpperCase(),
                      style: TextStyle(
                        color: selected ? statusColor(s == 'all' ? 'x' : s) : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }

  // ─── Empty / No Match ──────────────────────────────────────────────────────
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(28)),
            child: const Icon(Icons.shopping_bag_outlined, size: 40, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(height: 16),
          const Text('No Orders Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _noMatch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('No matching orders', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 6),
          Text('Try adjusting the filters or search term', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }
}