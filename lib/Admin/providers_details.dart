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
  final CollectionReference _providersRef =
      FirebaseFirestore.instance.collection('providers');

  // Created once and held — not recreated inside build() — so typing in the
  // search box or tapping a filter chip doesn't tear down and resubscribe
  // to the whole `providers` collection on every keystroke.
  late final Stream<QuerySnapshot> _providersStream = _providersRef.snapshots();

  // ── Search & Filter State ─────────────────────────────────────────────────
  String _search = '';
  String _statusFilter = 'all';
  String _typeFilter = 'all';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // ── Cached docs ────────────────────────────────────────────────────────────
  List<QueryDocumentSnapshot> _allDocs = [];

  // ── Buffers the latest snapshot so no update is ever dropped, and so a
  //    status/field change on a provider shows up immediately even when the
  //    total number of provider documents hasn't changed. ───────────────────
  List<QueryDocumentSnapshot>? _pendingDocs;
  bool _syncScheduled = false;

  // ── Constants ─────────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> _kTypes = [
    {'key': 'all',        'label': 'All',        'icon': Icons.dashboard_rounded},
    {'key': 'individual', 'label': 'Individual', 'icon': Icons.person_rounded},
    {'key': 'agency',     'label': 'Agency',     'icon': Icons.business_rounded},
    {'key': 'business',   'label': 'Business',   'icon': Icons.corporate_fare_rounded},
  ];

  static const List<Map<String, dynamic>> _kStatuses = [
    {'key': 'all',      'label': 'All',      'color': Color(0xFF4F46E5)},
    {'key': 'approved', 'label': 'Approved', 'color': Color(0xFF16A34A)},
    {'key': 'pending',  'label': 'Pending',  'color': Color(0xFFF59E0B)},
    {'key': 'rejected', 'label': 'Rejected', 'color': Color(0xFFDC2626)},
  ];

  /// Provider documents aren't consistently shaped: `serviceType` shows up
  /// as a top-level field on some docs and nested under `service.serviceType`
  /// on others (confirmed on production provider CIV-118139). Every place
  /// that reads a provider's service category goes through this helper so
  /// filtering, counts, and the card itself always agree with each other
  /// regardless of which shape a given document happens to use.
  String _providerServiceType(Map<String, dynamic> d) {
    final top = (d['serviceType'] ?? '').toString().trim();
    if (top.isNotEmpty) return top;
    final nested = (d['service'] as Map?)?['serviceType'];
    return (nested ?? '').toString().trim();
  }

  // ── Computed filtered list ─────────────────────────────────────────────────
  List<QueryDocumentSnapshot> get _filtered {
    final q = _search.toLowerCase().trim();
    return _allDocs.where((doc) {
      final d   = doc.data() as Map<String, dynamic>;
      final biz = (d['business'] as Map?)?.cast<String, dynamic>() ?? {};

      final name   = (biz['businessName'] ?? '').toString().toLowerCase();
      final phone  = (biz['phone'] ?? d['phone'] ?? '').toString().toLowerCase();
      final owner  = (biz['ownerName'] ?? d['ownerName'] ?? '').toString().toLowerCase();
      final svcT   = _providerServiceType(d).toLowerCase();
      final pid    = (d['providerId'] ?? '').toString().toLowerCase();
      final status = (d['status'] ?? '').toString().trim().toLowerCase();
      final ptype  = (d['providerType'] ?? '').toString().trim().toLowerCase();

      final matchSearch = q.isEmpty ||
          name.contains(q)  ||
          phone.contains(q) ||
          owner.contains(q) ||
          svcT.contains(q)  ||
          pid.contains(q);
      final matchStatus = _statusFilter == 'all' || status == _statusFilter;
      final matchType   = _typeFilter   == 'all' || ptype  == _typeFilter;

      return matchSearch && matchStatus && matchType;
    }).toList();
  }

  Map<String, int> get _typeCounts {
    final counts = <String, int>{'all': _allDocs.length};
    for (final t in _kTypes.skip(1)) {
      final k = t['key'] as String;
      counts[k] = _allDocs.where((doc) {
        final d = doc.data() as Map<String, dynamic>;
        return (d['providerType'] ?? '').toString().trim().toLowerCase() == k;
      }).length;
    }
    return counts;
  }

  // ── Colour / Icon helpers ──────────────────────────────────────────────────
  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'approved': return const Color(0xFF16A34A);
      case 'rejected': return const Color(0xFFDC2626);
      case 'pending':  return const Color(0xFFF59E0B);
      default:         return const Color(0xFF4F46E5);
    }
  }

  Color _statusBg(String s) {
    switch (s.toLowerCase()) {
      case 'approved': return const Color(0xFFE9FCEF);
      case 'rejected': return const Color(0xFFFEECEC);
      case 'pending':  return const Color(0xFFFFF5E5);
      default:         return const Color(0xFFEEF2FF);
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'approved': return Icons.verified_rounded;
      case 'rejected': return Icons.cancel_rounded;
      case 'pending':  return Icons.schedule_rounded;
      default:         return Icons.help_outline_rounded;
    }
  }

  IconData _serviceIcon(String s) {
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

  Color _serviceColor(String s) {
    final v = s.toLowerCase();
    if (v.contains('clean'))    return const Color(0xFF0EA5E9);
    if (v.contains('plumb'))    return const Color(0xFF64748B);
    if (v.contains('electric')) return const Color(0xFFEAB308);
    if (v.contains('civil'))    return const Color(0xFFD97706);
    if (v.contains('laundry'))  return const Color(0xFF3B82F6);
    if (v.contains('water'))    return const Color(0xFF06B6D4);
    if (v.contains('salon'))    return const Color(0xFFEC4899);
    if (v.contains('hotel'))    return const Color(0xFFF59E0B);
    if (v.contains('resort'))   return const Color(0xFF10B981);
    if (v.contains('educ'))     return const Color(0xFF8B5CF6);
    return const Color(0xFF4F46E5);
  }

  IconData _typeIcon(String t) {
    switch (t.toLowerCase()) {
      case 'agency':     return Icons.business_rounded;
      case 'individual': return Icons.person_rounded;
      case 'business':   return Icons.corporate_fare_rounded;
      default:           return Icons.person_rounded;
    }
  }

  String _fmt(Timestamp? t, {String pattern = 'dd MMM yyyy'}) =>
      t == null ? '-' : DateFormat(pattern).format(t.toDate());

  /// Real-device adaptive scale factor, based on a 390-logical-pixel design
  /// width (iPhone 12/13 / most mid-range Android reference), clamped so
  /// very small or very large screens don't blow proportions out. Matches
  /// the scale convention used elsewhere in the app.
  double _scale(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return (w / 390).clamp(0.85, 1.25);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Same no-drop sync pattern used on the Orders page: always cache the
  /// freshest snapshot, sorted, via a single scheduled setState — instead of
  /// only updating when the document *count* changes. The previous
  /// count-based check meant a provider's status flipping from "pending" to
  /// "approved" (no change in total document count) could leave the list
  /// showing stale data until some other unrelated add/remove happened.
  void _syncDocs(List<QueryDocumentSnapshot> docs) {
    docs.sort((a, b) {
      final aT = (a.data() as Map)['createdAt'];
      final bT = (b.data() as Map)['createdAt'];
      if (aT is Timestamp && bT is Timestamp) {
        return bT.toDate().compareTo(aT.toDate());
      }
      return 0;
    });

    _pendingDocs = docs;
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      final latest = _pendingDocs;
      if (mounted && latest != null) {
        setState(() => _allDocs = latest);
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF2563EB),
      statusBarIconBrightness: Brightness.light,
    ));

    // Clamp the system/user font-scale for this screen. This is the actual
    // fix for the "bottom overflowed" error that only showed up on real
    // devices: emulators/previews typically run at 1.0x text scale, but
    // real devices with accessibility "Large text" settings (1.3x–2.0x)
    // pushed the fixed-height chip/pill rows past their bounds. Clamping
    // keeps layout predictable while still respecting some user preference.
    final mq = MediaQuery.of(context);
    final clampedTextScaler =
        mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15);

    return MediaQuery(
      data: mq.copyWith(textScaler: clampedTextScaler),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FC),
        body: StreamBuilder<QuerySnapshot>(
          stream: _providersStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _allDocs.isEmpty) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
            }
            if (snapshot.hasError) {
              return _errorState(snapshot.error.toString());
            }

            if (snapshot.hasData) {
              _syncDocs(List<QueryDocumentSnapshot>.from(snapshot.data!.docs));
            }

            if (_allDocs.isEmpty) return _emptyState();

            final filtered  = _filtered;
            final typeCounts = _typeCounts;

            return Column(
              children: [
                _buildHeader(filtered.length, typeCounts),
                Expanded(
                  child: filtered.isEmpty
                      ? _noMatch()
                      : ListView.builder(
                          // Extra bottom padding clears Android's gesture
                          // nav bar / iOS home indicator on real devices so
                          // the last card's action button is never hidden.
                          padding: EdgeInsets.fromLTRB(
                            14,
                            14,
                            14,
                            32 + MediaQuery.of(context).padding.bottom,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _providerCard(
                            filtered[i].data() as Map<String, dynamic>,
                            filtered[i].id,
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

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(int shown, Map<String, int> typeCounts) {
    final topPad = MediaQuery.of(context).padding.top;
    final scale = _scale(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 46 * scale,
                    height: 46 * scale,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.storefront_rounded,
                        color: Colors.white, size: 24 * scale),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Providers',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            letterSpacing: .2,
                          ),
                        ),
                        Text(
                          '$shown ${shown == 1 ? 'provider' : 'providers'} shown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Search bar — KEY: lives outside StreamBuilder rebuild cycle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                elevation: 0,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: (v) => setState(() => _search = v),
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                  decoration: InputDecoration(
                    hintText: 'Search name, phone, service, ID…',
                    hintStyle:
                        const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF6B7280), size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: Color(0xFF6B7280)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                              _searchFocus.requestFocus();
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Provider type chips
            // Height is generous (84 vs the old 72) and every internal
            // block is wrapped in FittedBox(scaleDown) so if a device's
            // font/DPI settings ever push the intrinsic content taller
            // than the box, it shrinks to fit instead of overflowing.
            SizedBox(
              height: 84 * scale,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: _kTypes.length,
                itemBuilder: (_, i) {
                  final t = _kTypes[i];
                  final k = t['key'] as String;
                  final selected = _typeFilter == k;
                  final cnt = typeCounts[k] ?? 0;
                  return GestureDetector(
                    onTap: () => setState(() => _typeFilter = k),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 66 * scale,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : Colors.white.withOpacity(.14),
                        borderRadius: BorderRadius.circular(16),
                        border: selected
                            ? Border.all(color: Colors.white, width: 1.5)
                            : null,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(t['icon'] as IconData,
                                size: 20,
                                color: selected
                                    ? const Color(0xFF4F46E5)
                                    : Colors.white70),
                            const SizedBox(height: 3),
                            Text(
                              t['label'] as String,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? const Color(0xFF4F46E5)
                                    : Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                                child: Text(
                                  '$cnt',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: selected ? Colors.white : Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Status pills
            SizedBox(
              height: 42 * scale,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: _kStatuses.length,
                itemBuilder: (_, i) {
                  final s = _kStatuses[i];
                  final k = s['key'] as String;
                  final selected = _statusFilter == k;
                  final color = s['color'] as Color;
                  return GestureDetector(
                    onTap: () => setState(() => _statusFilter = k),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : Colors.white.withOpacity(.14),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          (s['label'] as String).toUpperCase(),
                          maxLines: 1,
                          style: TextStyle(
                            color: selected ? color : Colors.white70,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Provider Card ──────────────────────────────────────────────────────────
  Widget _providerCard(Map<String, dynamic> data, String docId) {
    final biz    = (data['business']  as Map?)?.cast<String, dynamic>() ?? {};
    final bank   = (data['bank']      as Map?)?.cast<String, dynamic>() ?? {};
    final svc    = (data['service']   as Map?)?.cast<String, dynamic>() ?? {};
    final docsMap = (data['documents'] as Map?)?.cast<String, dynamic>() ?? {};

    final providerId        = (data['providerId']   ?? docId).toString();
    final businessName      = (biz['businessName']  ?? 'No Name').toString();
    final ownerName         = (biz['ownerName']     ?? data['ownerName'] ?? '').toString();
    final phone             = (biz['phone']         ?? data['phone'] ?? '').toString();
    final email             = (biz['email']         ?? '').toString();
    final city              = (biz['city']          ?? '').toString();
    final state              = (biz['state']         ?? '').toString();
    final address           = (biz['address']       ?? '').toString();
    final pincode           = (biz['pincode']       ?? '').toString();
    final image             = (biz['image']         ?? '').toString();
    final providerType      = (data['providerType'] ?? 'Provider').toString();
    final status            = (data['status']       ?? 'pending').toString();
    final serviceType       = _providerServiceType(data);
    final userId            = (data['userId']       ?? '').toString();
    final ownTools          = svc['ownTools'] ?? false;
    final isActive          = data['isActive'] ?? false;
    final agreementAccepted = data['agreementAccepted'] ?? false;
    final List categories   = List.from(data['categories'] ?? []);

    final Timestamp? createdAt           = data['createdAt'];
    final Timestamp? updatedAt           = data['updatedAt'];
    final Timestamp? agreementAcceptedAt = data['agreementAcceptedAt'];

    final svcColor = _serviceColor(serviceType);
    final location = [city, state].where((s) => s.isNotEmpty).join(', ');

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
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Coloured strip ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [svcColor, svcColor.withOpacity(.72)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo / avatar
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.2),
                      borderRadius: BorderRadius.circular(18),
                      image: image.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(image), fit: BoxFit.cover)
                          : null,
                    ),
                    child: image.isEmpty
                        ? Icon(_serviceIcon(serviceType),
                            color: Colors.white, size: 28)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          businessName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: .2,
                          ),
                        ),
                        if (ownerName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            ownerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          children: [
                            _pill(_statusIcon(status), status.toUpperCase()),
                            _pill(_typeIcon(providerType), providerType),
                            _pill(
                              isActive ? Icons.circle : Icons.circle_outlined,
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

            // ── Card body ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Status banner ──
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: _statusBg(status),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(_statusIcon(status),
                            color: _statusColor(status), size: 18),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            status.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _statusColor(status),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: .4,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (serviceType.isNotEmpty)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: svcColor.withOpacity(.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                serviceType,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: svcColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Contact & Service ──
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
                        child: _infoTile(Icons.location_city_rounded,
                            'Location', location.isEmpty ? '-' : location)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _infoTile(Icons.build_circle_rounded, 'Tools',
                            ownTools ? 'Available' : 'Not available')),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _infoTile(Icons.calendar_today_rounded, 'Joined',
                            _fmt(createdAt))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _infoTile(Icons.badge_rounded, 'Provider ID',
                            providerId)),
                  ]),

                  const SizedBox(height: 16),

                  // ── Timeline ──
                  _sectionLabel('Timeline'),
                  const SizedBox(height: 8),
                  _timelineRow([
                    ('Registered', _fmt(createdAt, pattern: 'dd MMM yy')),
                    ('Agreement',
                        _fmt(agreementAcceptedAt, pattern: 'dd MMM yy')),
                    ('Updated', _fmt(updatedAt, pattern: 'dd MMM yy')),
                  ], svcColor),

                  // ── Address ──
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

                  // ── Categories ──
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
                            color: svcColor.withOpacity(.07),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: svcColor.withOpacity(.22)),
                          ),
                          child: Text(
                            c.toString(),
                            style: TextStyle(
                              color: svcColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // ── Documents ──
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
                                      color: Color(0xFF16A34A), size: 13),
                                  const SizedBox(width: 5),
                                  Text(
                                    k,
                                    style: const TextStyle(
                                      color: Color(0xFF16A34A),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
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
                                  color: Color(0xFFF59E0B), size: 15),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No documents uploaded yet',
                                  style: TextStyle(
                                    color: Color(0xFFB45309),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                  // ── Bank Details ──
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _bankRow('Holder',  (bank['accountHolder'] ?? '-').toString()),
                        _bankRow('Account', (bank['accountNumber'] ?? '-').toString()),
                        _bankRow('IFSC',    (bank['ifsc']          ?? '-').toString()),
                        _bankRow('UPI',     (bank['upi']           ?? '-').toString()),
                      ],
                    ),
                  ),

                  // ── Agreement ──
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
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                agreementAccepted
                                    ? 'Agreement Accepted'
                                    : 'Agreement Not Accepted',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: agreementAccepted
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                              if (agreementAccepted &&
                                  agreementAcceptedAt != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _fmt(agreementAcceptedAt,
                                      pattern: 'dd MMM yyyy • hh:mm a'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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

                  // ── User ID (copyable) ──
                  if (userId.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: userId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User ID copied'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDDD9FF)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.link_rounded,
                                color: Color(0xFF4F46E5), size: 15),
                            const SizedBox(width: 8),
                            const Text(
                              'User ID: ',
                              style: TextStyle(
                                color: Color(0xFF4F46E5),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                userId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF3730A3),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Icon(Icons.copy_rounded,
                                color: Color(0xFF4F46E5), size: 13),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // ── Open Profile button ──
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ProviderProfilePage(providerId: providerId)),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 17),
                      label: const Text(
                        'Open Provider Profile',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
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

  // ── Shared widgets ─────────────────────────────────────────────────────────
  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      constraints: const BoxConstraints(maxWidth: 140),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.2),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937)),
          ),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 13, color: const Color(0xFF4F46E5)),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          const SizedBox(height: 5),
          Text(
            value.isEmpty ? '-' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _bankRow(String title, String value) {
    final isEmpty = value.isEmpty || value == '-';
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              isEmpty ? '—' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isEmpty
                    ? const Color(0xFFD1D5DB)
                    : const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineRow(List<(String, String)> items, Color color) {
    return Row(
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final hasVal = item.$2 != '-';
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: hasVal
                                ? color
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: hasVal
                            ? const Color(0xFF1F2937)
                            : const Color(0xFFD1D5DB),
                      ),
                      textAlign: TextAlign.center,
                    ),
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
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.storefront_outlined,
                size: 36, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(height: 14),
          const Text('No Providers Found',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Registered providers will appear here',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _noMatch() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No matching providers',
            style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 15),
          ),
          const SizedBox(height: 5),
          Text(
            'Adjust filters or search term',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFDC2626)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}