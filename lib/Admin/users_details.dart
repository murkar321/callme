import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String search = "";
  final TextEditingController searchController = TextEditingController();

  // ─── Stream ────────────────────────────────────────────────────────────────
  Stream<QuerySnapshot<Map<String, dynamic>>> usersStream() =>
      firestore.collection("users").snapshots();

  /// A valid user doc must have a uid field (FCM-token-only docs do not).
  bool _isValidUser(Map<String, dynamic> data) {
    final uid = (data['uid'] ?? '').toString().trim();
    return uid.isNotEmpty;
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
      backgroundColor: const Color(0xFFF4F7FC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: usersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          "Firestore Error\n\n${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _emptyState("No Users Found");
                  }

                  // ── Filter out non-user docs (e.g. FCM-token-only entries) ──
                  var docs = snapshot.data!.docs
                      .where((doc) => _isValidUser(doc.data()))
                      .toList();

                  // Sort newest first
                  docs.sort((a, b) {
                    final aT = a.data()['createdAt'];
                    final bT = b.data()['createdAt'];
                    if (aT is Timestamp && bT is Timestamp) {
                      return bT.toDate().compareTo(aT.toDate());
                    }
                    return 0;
                  });

                  // Search filter
                  final filtered = docs.where((doc) {
                    final d = doc.data();
                    final name      = (d['name']       ?? '').toString().toLowerCase();
                    final firstName = (d['firstName']  ?? '').toString().toLowerCase();
                    final lastName  = (d['lastName']   ?? '').toString().toLowerCase();
                    final email     = (d['email']      ?? '').toString().toLowerCase();
                    final phone     = (d['phone']      ?? '').toString().toLowerCase();
                    final uid       = (d['uid']        ?? doc.id).toString().toLowerCase();
                    return name.contains(search)      ||
                        firstName.contains(search)    ||
                        lastName.contains(search)     ||
                        email.contains(search)        ||
                        phone.contains(search)        ||
                        uid.contains(search);
                  }).toList();

                  if (filtered.isEmpty) return _emptyState("No Matching Users");

                  return RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) =>
                          _userCard(filtered[index].data(), filtered[index].id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── User Card ─────────────────────────────────────────────────────────────
  Widget _userCard(Map<String, dynamic> d, String docId) {
    final uid         = (d['uid']         ?? docId).toString();
    final name        = (d['name']        ?? 'Unknown User').toString();
    final firstName   = (d['firstName']   ?? '').toString();
    final lastName    = (d['lastName']    ?? '').toString();
    final googleName  = (d['googleName']  ?? '').toString();
    final email       = (d['email']       ?? 'No Email').toString();
    final phone       = (d['phone']       ?? '').toString();
    final address     = (d['address']     ?? '').toString();
    final photo       = (d['photo']       ?? d['googlePhoto'] ?? '').toString();
    final fcmToken    = (d['fcmToken']    ?? '').toString();
    final providers   = (d['providers']   as List?)?.cast<dynamic>() ?? [];
    final isActive    = d['isActive'] ?? true;

    final Timestamp? createdAt      = d['createdAt'];
    final Timestamp? lastLogin      = d['lastLogin'];
    final Timestamp? updatedAt      = d['updatedAt'];
    final Timestamp? tokenUpdatedAt = d['tokenUpdatedAt'];

    String fmt(Timestamp? t, {String pattern = 'dd MMM yyyy'}) =>
        t == null ? '-' : DateFormat(pattern).format(t.toDate());

    final displayName = name.isNotEmpty ? name : '$firstName $lastName'.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 18, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          // ── Coloured top strip ──
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5B5FEF), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF6D5DF6), Color(0xFF8E7CFF)]),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: photo.isNotEmpty
                        ? Image.network(
                            photo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person, color: Colors.white, size: 32),
                          )
                        : const Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (googleName.isNotEmpty && googleName != displayName) ...[
                        const SizedBox(height: 2),
                        Text(googleName,
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 2),
                      Text(email,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _whiteBadge(
                            isActive ? Icons.check_circle_rounded : Icons.block_rounded,
                            isActive ? 'ACTIVE' : 'BLOCKED',
                          ),
                          if (fcmToken.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _whiteBadge(Icons.notifications_active_rounded, 'PUSH ON'),
                          ],
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
                // ── Contact Info ──
                _sectionTitle('Contact'),
                const SizedBox(height: 10),
                _infoGrid([
                  if (phone.isNotEmpty)
                    (Icons.phone_rounded, 'Phone', phone)
                  else
                    (Icons.phone_rounded, 'Phone', 'Not provided'),
                  (Icons.email_rounded, 'Email', email),
                  if (address.isNotEmpty)
                    (Icons.location_on_rounded, 'Address', address)
                  else
                    (Icons.location_on_rounded, 'Address', 'Not provided'),
                ]),

                const SizedBox(height: 18),

                // ── Name Breakdown ──
                _sectionTitle('Profile'),
                const SizedBox(height: 10),
                _infoGrid([
                  (Icons.person_rounded, 'First Name', firstName.isNotEmpty ? firstName : '-'),
                  (Icons.person_outline_rounded, 'Last Name', lastName.isNotEmpty ? lastName : '-'),
                  if (googleName.isNotEmpty)
                    (Icons.g_mobiledata_rounded, 'Google Name', googleName),
                ]),

                const SizedBox(height: 18),

                // ── Activity Timeline ──
                _sectionTitle('Activity'),
                const SizedBox(height: 10),
                _timelineRow([
                  ('Joined',       fmt(createdAt, pattern: 'dd MMM yy')),
                  ('Last Login',   fmt(lastLogin,  pattern: 'dd MMM yy')),
                  ('Updated',      fmt(updatedAt,  pattern: 'dd MMM yy')),
                  ('Token Sync',   fmt(tokenUpdatedAt, pattern: 'dd MMM yy')),
                ]),

                // ── Providers ──
                if (providers.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _sectionTitle('Linked Providers'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: providers.map((p) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFEEF0FF), Color(0xFFE7E9FF)]),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.business_center_rounded,
                                size: 14, color: Color(0xFF5B5FEF)),
                            const SizedBox(width: 6),
                            Text(p.toString(),
                                style: const TextStyle(
                                    color: Color(0xFF5B5FEF),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 18),

                // ── UID ──
                _sectionTitle('UID'),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: uid));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('UID copied to clipboard')),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0FF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFDDD9FF)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded,
                            color: Color(0xFF5B5FEF), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            uid,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF3730A3)),
                          ),
                        ),
                        const Icon(Icons.copy_rounded,
                            color: Color(0xFF5B5FEF), size: 16),
                      ],
                    ),
                  ),
                ),

                // ── FCM Token (collapsed, tap to copy) ──
                if (fcmToken.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: fcmToken));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('FCM token copied to clipboard')),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FFF4),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_rounded,
                              color: Color(0xFF16A34A), size: 18),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'FCM Token — tap to copy',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF15803D)),
                            ),
                          ),
                          const Icon(Icons.copy_rounded,
                              color: Color(0xFF16A34A), size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── White Badge (for coloured header) ────────────────────────────────────
  Widget _whiteBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(.2),
          borderRadius: BorderRadius.circular(40)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }

  // ─── Section Title ─────────────────────────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
                color: const Color(0xFF5B5FEF),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
      ],
    );
  }

  // ─── Info Grid ─────────────────────────────────────────────────────────────
  Widget _infoGrid(List<(IconData, String, String)> items) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFFF7F8FD), borderRadius: BorderRadius.circular(20)),
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
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(item.$1, size: 16, color: const Color(0xFF5B5FEF)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.$2,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        item.$3.isEmpty ? '-' : item.$3,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, height: 1.4),
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

  // ─── Timeline Row ──────────────────────────────────────────────────────────
  Widget _timelineRow(List<(String, String)> items) {
    return Row(
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final hasValue = item.$2 != '-';
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: hasValue
                            ? const Color(0xFFEEF0FF)
                            : const Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasValue
                              ? const Color(0xFF5B5FEF).withOpacity(.4)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: hasValue
                                    ? const Color(0xFF5B5FEF)
                                    : const Color(0xFF9CA3AF))),
                      ),
                    ),
                    const SizedBox(height: 5),
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
                            color: hasValue
                                ? const Color(0xFF1F2937)
                                : const Color(0xFFD1D5DB)),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              if (i < items.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 38),
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B5FEF), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.people_alt_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Users Dashboard',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Manage all registered users',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 58,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: TextField(
              controller: searchController,
              onChanged: (v) =>
                  setState(() => search = v.trim().toLowerCase()),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search by name, email or phone…',
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF5B5FEF)),
                suffixIcon: search.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() => search = '');
                        },
                        icon: const Icon(Icons.close_rounded))
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty State ───────────────────────────────────────────────────────────
  Widget _emptyState(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 95,
            height: 95,
            decoration: BoxDecoration(
                color: const Color(0xFFEEF0FF),
                borderRadius: BorderRadius.circular(30)),
            child: const Icon(Icons.people_outline_rounded,
                size: 42, color: Color(0xFF5B5FEF)),
          ),
          const SizedBox(height: 18),
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}