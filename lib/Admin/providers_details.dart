import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../provider/provider_profile_page.dart';

class ProvidersPage extends StatefulWidget {
  const ProvidersPage({super.key});

  @override
  State<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  final CollectionReference providersRef =
      FirebaseFirestore.instance.collection("providers");

  String searchQuery = "";
  String statusFilter = "all";
  String typeFilter = "all";

  static const List<Map<String, dynamic>> kTypes = [
    {'key': 'all',        'label': 'All',        'icon': Icons.dashboard_rounded},
    {'key': 'individual', 'label': 'Individual', 'icon': Icons.person_rounded},
    {'key': 'agency',     'label': 'Agency',     'icon': Icons.business_rounded},
    {'key': 'business',   'label': 'Business',   'icon': Icons.corporate_fare_rounded},
  ];

  static const List<Map<String, dynamic>> kStatuses = [
    {'key': 'all',      'label': 'All',      'color': Color(0xFF4F46E5)},
    {'key': 'approved', 'label': 'Approved', 'color': Color(0xFF16A34A)},
    {'key': 'pending',  'label': 'Pending',  'color': Color(0xFFF59E0B)},
    {'key': 'rejected', 'label': 'Rejected', 'color': Color(0xFFDC2626)},
  ];

  // ─── Colour/icon helpers ──────────────────────────────────────────────────
  Color statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'approved': return const Color(0xFF16A34A);
      case 'rejected': return const Color(0xFFDC2626);
      case 'pending':  return const Color(0xFFF59E0B);
      default:         return const Color(0xFF4F46E5);
    }
  }

  Color statusBg(String s) {
    switch (s.toLowerCase()) {
      case 'approved': return const Color(0xFFE9FCEF);
      case 'rejected': return const Color(0xFFFEECEC);
      case 'pending':  return const Color(0xFFFFF5E5);
      default:         return const Color(0xFFEEF2FF);
    }
  }

  IconData statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'approved': return Icons.verified_rounded;
      case 'rejected': return Icons.cancel_rounded;
      case 'pending':  return Icons.schedule_rounded;
      default:         return Icons.help_outline_rounded;
    }
  }

  IconData serviceIcon(String s) {
    final v = s.toLowerCase();
    if (v.contains('water'))    return Icons.water_drop_rounded;
    if (v.contains('clean'))    return Icons.cleaning_services_rounded;
    if (v.contains('electric')) return Icons.electrical_services_rounded;
    if (v.contains('plumb'))    return Icons.plumbing_rounded;
    if (v.contains('salon'))    return Icons.content_cut_rounded;
    if (v.contains('civil'))    return Icons.construction_rounded;
    if (v.contains('laundry'))  return Icons.local_laundry_service_rounded;
    if (v.contains('hotel'))    return Icons.hotel_rounded;
    if (v.contains('resort'))   return Icons.beach_access_rounded;
    if (v.contains('educ'))     return Icons.school_rounded;
    return Icons.miscellaneous_services_rounded;
  }

  Color serviceColor(String s) {
    final v = s.toLowerCase();
    if (v.contains('clean'))    return const Color(0xFF0EA5E9);
    if (v.contains('plumb'))    return const Color(0xFF64748B);
    if (v.contains('electric')) return const Color(0xFFEAB308);
    if (v.contains('civil'))    return const Color(0xFFD97706);
    if (v.contains('laundry'))  return const Color(0xFF3B82F6);
    if (v.contains('water'))    return const Color(0xFF06B6D4);
    if (v.contains('salon'))    return const Color(0xFFEC4899);
    if (v.contains('hotel'))    return const Color(0xFFF59E0B);
    if (v.contains('educ'))     return const Color(0xFF8B5CF6);
    return const Color(0xFF4F46E5);
  }

  IconData typeIcon(String t) {
    switch (t.toLowerCase()) {
      case 'agency':     return Icons.business_rounded;
  case 'individual': return Icons.person_rounded;
      case 'business':   return Icons.corporate_fare_rounded;
      default:           return Icons.person_rounded;
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final bool isTablet = sw >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: providersRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _emptyState();
            }

            List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

            docs.sort((a, b) {
              final aT = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              final bT = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              return bT.compareTo(aT);
            });

            // Type counts for badges
            final Map<String, int> typeCounts = {'all': docs.length};
            for (final t in kTypes.skip(1)) {
              final k = t['key'] as String;
              typeCounts[k] = docs
                  .where((d) =>
                      (d['providerType'] ?? '').toString().toLowerCase() == k)
                  .length;
            }

            // Apply filters
            final filtered = docs.where((doc) {
              final d   = doc.data() as Map<String, dynamic>;
              final biz = (d['business'] as Map?)?.cast<String, dynamic>() ?? {};
              final name   = (biz['businessName'] ?? '').toString().toLowerCase();
              final phone  = (biz['phone'] ?? d['phone'] ?? '').toString().toLowerCase();
              final owner  = (biz['ownerName'] ?? d['ownerName'] ?? '').toString().toLowerCase();
              final svcT   = (d['serviceType'] ?? '').toString().toLowerCase();
              final pid    = (d['providerId'] ?? '').toString().toLowerCase();
              final status = (d['status'] ?? '').toString().toLowerCase();
              final ptype  = (d['providerType'] ?? '').toString().toLowerCase();

              final q = searchQuery.toLowerCase().trim();
              final matchSearch = q.isEmpty ||
                  name.contains(q) || phone.contains(q) ||
                  owner.contains(q) || svcT.contains(q) || pid.contains(q);
              final matchStatus = statusFilter == 'all' || status == statusFilter;
              final matchType   = typeFilter == 'all'   || ptype == typeFilter;

              return matchSearch && matchStatus && matchType;
            }).toList();

            final double listPad = isTablet ? 20.0 : 14.0;

            return Column(
              children: [
                _buildHeader(typeCounts, filtered.length, sw, isTablet),
                Expanded(
                  child: filtered.isEmpty
                      ? _noMatch()
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(listPad, 14, listPad, 24),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _providerCard(
                            filtered[i].data() as Map<String, dynamic>,
                            filtered[i].id,
                            sw,
                            isTablet,
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Header (no stats bar) ───────────────────────────────────────────────
  Widget _buildHeader(
      Map<String, int> typeCounts, int shown, double sw, bool isTablet) {
// used for sizing only
    final double hPad = isTablet ? 24.0 : 16.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Title row ──
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 56 : 48,
                  height: isTablet ? 56 : 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.storefront_rounded,
                      color: Colors.white, size: isTablet ? 28 : 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Providers',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 24 : 20)),
                      Text('$shown providers shown',
                          style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Search ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                onChanged: (v) => setState(() => searchQuery = v),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search name, phone, service, ID…',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: Color(0xFF4F46E5), size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () => setState(() => searchQuery = ''),
                          icon: Icon(Icons.close_rounded,
                              color: Colors.grey.shade500, size: 18))
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Provider Type tabs ──
          SizedBox(
            height: 68,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: hPad),
              children: kTypes.map((t) {
                final k        = t['key'] as String;
                final selected = typeFilter == k;
                final cnt      = typeCounts[k] ?? 0;
                return GestureDetector(
                  onTap: () => setState(() => typeFilter = k),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 66,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white
                          : Colors.white.withOpacity(.13),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(t['icon'] as IconData,
                            size: 18,
                            color: selected
                                ? const Color(0xFF4F46E5)
                                : Colors.white70),
                        const SizedBox(height: 3),
                        Text(t['label'] as String,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: selected
                                    ? const Color(0xFF4F46E5)
                                    : Colors.white70),
                            textAlign: TextAlign.center),
                        if (k != 'all') ...[
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF4F46E5)
                                  : Colors.white.withOpacity(.22),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('$cnt',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: selected
                                        ? Colors.white
                                        : Colors.white70)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // ── Status filter pills ──
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: hPad),
              children: kStatuses.map((s) {
                final k        = s['key'] as String;
                final selected = statusFilter == k;
                final color    = s['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => statusFilter = k),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white
                          : Colors.white.withOpacity(.13),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text(
                      (s['label'] as String).toUpperCase(),
                      style: TextStyle(
                          color: selected ? color : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 11),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ─── Provider Card ────────────────────────────────────────────────────────
  Widget _providerCard(Map<String, dynamic> data, String docId,
      double sw, bool isTablet) {
    final biz  = (data['business']  as Map?)?.cast<String, dynamic>() ?? {};
    final bank = (data['bank']      as Map?)?.cast<String, dynamic>() ?? {};
    final svc  = (data['service']   as Map?)?.cast<String, dynamic>() ?? {};
    final docsMap = (data['documents'] as Map?)?.cast<String, dynamic>() ?? {};

    final providerId          = (data['providerId']   ?? docId).toString();
    (data['providerName'] ?? '').toString();
    final businessName        = (biz['businessName']  ?? 'No Name').toString();
    final ownerName           = (biz['ownerName']     ?? data['ownerName'] ?? '').toString();
    final phone               = (biz['phone']         ?? data['phone'] ?? '').toString();
    final email               = (biz['email']         ?? '').toString();
    final city                = (biz['city']          ?? '').toString();
    final state               = (biz['state']         ?? '').toString();
    final address             = (biz['address']       ?? '').toString();
    final pincode             = (biz['pincode']       ?? '').toString();
    final image               = (biz['image']         ?? '').toString();
    final providerType        = (data['providerType'] ?? 'Provider').toString();
    final status              = (data['status']       ?? 'pending').toString();
    final serviceType         = (data['serviceType']  ?? '').toString();
    final userId              = (data['userId']       ?? '').toString();
    final ownTools            = svc['ownTools'] ?? false;
    final isActive            = data['isActive'] ?? false;
    final agreementAccepted   = data['agreementAccepted'] ?? false;
    final List categories     = List.from(data['categories'] ?? []);

    final Timestamp? createdAt           = data['createdAt'];
    final Timestamp? updatedAt           = data['updatedAt'];
    final Timestamp? agreementAcceptedAt = data['agreementAcceptedAt'];

    String fmt(Timestamp? t, {String pattern = 'dd MMM yyyy'}) =>
        t == null ? '-' : DateFormat(pattern).format(t.toDate());

    final svcColor  = serviceColor(serviceType);
    final double br = isTablet ? 28.0 : 22.0;
    final double ip = isTablet ? 18.0 : 14.0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProviderProfilePage(providerId: providerId)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(br),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 14,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Coloured strip ──
            Container(
              padding: EdgeInsets.all(ip),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [svcColor, svcColor.withOpacity(.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(br)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Container(
                    width: isTablet ? 72 : 60,
                    height: isTablet ? 72 : 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.2),
                      borderRadius: BorderRadius.circular(isTablet ? 22 : 18),
                      image: image.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(image), fit: BoxFit.cover)
                          : null,
                    ),
                    child: image.isEmpty
                        ? Icon(serviceIcon(serviceType),
                            color: Colors.white, size: isTablet ? 32 : 26)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(businessName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isTablet ? 18 : 16)),
                        if (ownerName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(ownerName,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          children: [
                            _pill(statusIcon(status), status.toUpperCase()),
                            _pill(typeIcon(providerType), providerType),
                            _pill(
                              isActive
                                  ? Icons.circle
                                  : Icons.circle_outlined,
                              isActive ? 'ACTIVE' : 'INACTIVE',
                            ),
                            if (agreementAccepted)
                              _pill(Icons.handshake_rounded, 'AGREED'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Padding(
              padding: EdgeInsets.all(ip),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact grid (2-column)
                  _sectionLabel('Contact & Service'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _infoTile(Icons.phone_rounded, 'Phone', phone)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _infoTile(Icons.email_rounded, 'Email', email)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _infoTile(
                            Icons.location_city_rounded,
                            'Location',
                            [city, state]
                                .where((s) => s.isNotEmpty)
                                .join(', '))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _infoTile(
                            Icons.miscellaneous_services_rounded,
                            'Service',
                            serviceType.isEmpty ? '-' : serviceType)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _infoTile(Icons.build_circle_rounded, 'Tools',
                            ownTools ? 'Available' : 'Not available')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _infoTile(Icons.calendar_today_rounded,
                            'Joined', fmt(createdAt))),
                  ]),

                  // Timeline
                  const SizedBox(height: 16),
                  _sectionLabel('Timeline'),
                  const SizedBox(height: 8),
                  _timelineRow([
                    ('Registered', fmt(createdAt, pattern: 'dd MMM yy')),
                    ('Agreement',  fmt(agreementAcceptedAt, pattern: 'dd MMM yy')),
                    ('Updated',    fmt(updatedAt, pattern: 'dd MMM yy')),
                  ], svcColor),

                  // Address
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionLabel('Address'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_rounded,
                              color: svcColor, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              [address, city, state, pincode]
                                  .where((s) => s.isNotEmpty)
                                  .join(', '),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Categories
                  if (categories.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionLabel('Categories'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: categories.map((c) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: svcColor.withOpacity(.08),
                            borderRadius: BorderRadius.circular(30),
                            border:
                                Border.all(color: svcColor.withOpacity(.22)),
                          ),
                          child: Text(c.toString(),
                              style: TextStyle(
                                  color: svcColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11)),
                        );
                      }).toList(),
                    ),
                  ],

                  // Documents
                  const SizedBox(height: 16),
                  _sectionLabel('Documents'),
                  const SizedBox(height: 8),
                  docsMap.isNotEmpty
                      ? Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: docsMap.keys.map((k) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE9FCEF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_rounded,
                                      color: Color(0xFF16A34A), size: 14),
                                  const SizedBox(width: 5),
                                  Text(k,
                                      style: const TextStyle(
                                          color: Color(0xFF16A34A),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ],
                              ),
                            );
                          }).toList(),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5E5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Color(0xFFF59E0B), size: 16),
                              SizedBox(width: 8),
                              Text('No documents uploaded yet',
                                  style: TextStyle(
                                      color: Color(0xFFB45309),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                            ],
                          ),
                        ),

                  // Bank
                  const SizedBox(height: 16),
                  _sectionLabel('Bank Details'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        _bankRow('Holder',  bank['accountHolder'] ?? '-'),
                        _bankRow('Account', bank['accountNumber'] ?? '-'),
                        _bankRow('IFSC',    bank['ifsc']          ?? '-'),
                        _bankRow('UPI',     bank['upi']           ?? '-'),
                      ],
                    ),
                  ),

                  // Agreement
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: agreementAccepted
                          ? const Color(0xFFE9FCEF)
                          : const Color(0xFFFEECEC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          agreementAccepted
                              ? Icons.handshake_rounded
                              : Icons.close_rounded,
                          color: agreementAccepted
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                agreementAccepted
                                    ? 'Agreement Accepted'
                                    : 'Agreement Not Accepted',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: agreementAccepted
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDC2626)),
                              ),
                              if (agreementAccepted &&
                                  agreementAcceptedAt != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  fmt(agreementAcceptedAt,
                                      pattern: 'dd MMM yyyy • hh:mm a'),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF16A34A)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // User ID
                  if (userId.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: userId));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('User ID copied')));
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0FF),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: const Color(0xFFDDD9FF)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.link_rounded,
                                color: Color(0xFF4F46E5), size: 16),
                            const SizedBox(width: 8),
                            const Text('User ID: ',
                                style: TextStyle(
                                    color: Color(0xFF4F46E5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                            Expanded(
                              child: Text(userId,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Color(0xFF3730A3),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                            ),
                            const Icon(Icons.copy_rounded,
                                color: Color(0xFF4F46E5), size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Open Profile button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProviderProfilePage(
                                providerId: providerId)),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Open Provider Profile',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Widgets ─────────────────────────────────────────────────────────────
  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(.2),
          borderRadius: BorderRadius.circular(40)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String t) {
    return Row(
      children: [
        Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 7),
        Text(t,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937))),
      ],
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: const Color(0xFF4F46E5)),
            const SizedBox(width: 5),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(value.isEmpty ? '-' : value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }

  Widget _bankRow(String title, String value) {
    final isEmpty = value.isEmpty || value == '-';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(title,
                style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(isEmpty ? '—' : value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isEmpty
                        ? const Color(0xFFD1D5DB)
                        : const Color(0xFF1F2937))),
          ),
        ],
      ),
    );
  }

  Widget _timelineRow(List<(String, String)> items, Color color) {
    return Row(
      children: items.asMap().entries.map((entry) {
        final i      = entry.key;
        final item   = entry.value;
        final hasVal = item.$2 != '-';
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: hasVal
                            ? color.withOpacity(.12)
                            : const Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: hasVal
                                ? color.withOpacity(.35)
                                : const Color(0xFFE5E7EB)),
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: hasVal
                                    ? color
                                    : const Color(0xFF9CA3AF))),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(item.$1,
                        style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 2),
                    Text(item.$2,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: hasVal
                                ? const Color(0xFF1F2937)
                                : const Color(0xFFD1D5DB)),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              if (i < items.length - 1)
                Expanded(
                  child: Container(
                    height: 1.5,
                    margin: const EdgeInsets.only(bottom: 34),
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(28)),
            child: const Icon(Icons.storefront_outlined,
                size: 44, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(height: 16),
          const Text('No Providers Found',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Registered providers will appear here',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _noMatch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('No matching providers',
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          const SizedBox(height: 6),
          Text('Adjust filters or search term',
              style:
                  TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }
}

