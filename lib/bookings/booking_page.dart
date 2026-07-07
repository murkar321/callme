import 'package:callme/data/service_product.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/payment/payment_page.dart';
import 'package:callme/provider/order_service.dart';
import 'package:callme/screens/bottom_nav_page.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:callme/screens/map_picker_page.dart';

import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const _kAccent     = Color(0xFF5B4FCF);
const _kAccentSoft = Color(0xFF7B6FE8);
const _kBg         = Color(0xFFF4F3FB);
const _kCard       = Colors.white;
const _kSuccess    = Color(0xFF34C759);

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING PAGE
//

// ─────────────────────────────────────────────────────────────────────────────

class BookingPage extends StatefulWidget {
  final String          serviceName;
  final ServiceProduct? product;
  final List<CartItem>? cart;
  final String?         initialProviderId;

  const BookingPage({
    super.key,
    required this.serviceName,
    this.product,
    this.cart,
    this.initialProviderId,
    required List<dynamic> products,
    required String providerId,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage>
    with TickerProviderStateMixin {

  // ── Controllers ──────────────────────────────────────────────────────────
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _noteCtrl    = TextEditingController();
  final _phoneFocus  = FocusNode();
  final _scrollCtrl  = ScrollController();

  // ── State ─────────────────────────────────────────────────────────────────
  DateTime?  _date;
  TimeOfDay? _time;

  bool _isLoading         = false;
  bool _isSuccess         = false;
  bool _isLoadingProvider = true;
  bool _phoneComplete     = false;
  bool _summaryExpanded   = true;

  LatLng? _pickedLatLng;
  String  _bookingId = '';

  // Preview match only — see class-level comment above. This is NOT
  // automatically who the order gets assigned to.
  String? _providerId;
  String? _providerName;
  String? _noProviderMessage;

  // ── Animations ────────────────────────────────────────────────────────────
  late final AnimationController _pageAnim;
  late final AnimationController _revealAnim;
  late final Animation<double>   _pageFade;
  late final Animation<Offset>   _revealSlide;
  late final Animation<double>   _revealFade;

  // ─────────────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _pageAnim   = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 520));
    _revealAnim = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 480));

    _pageFade    = CurvedAnimation(parent: _pageAnim,   curve: Curves.easeOut);
    _revealSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _revealAnim, curve: Curves.easeOutCubic));
    _revealFade  = CurvedAnimation(parent: _revealAnim, curve: Curves.easeOut);

    _pageAnim.forward();
    _phoneCtrl.addListener(_onPhoneChanged);

    if (_isPinnedProvider) {
      _providerId        = widget.initialProviderId;
      _isLoadingProvider = false;
      _fetchProviderName(widget.initialProviderId!);
    } else {
      _loadProvider();
    }
  }

  void _onPhoneChanged() {
    final done = _phoneCtrl.text.trim().length >= 10;
    if (done != _phoneComplete) {
      setState(() => _phoneComplete = done);
      done ? _revealAnim.forward() : _revealAnim.reverse();
    }
  }

  @override
  void dispose() {
    _pageAnim.dispose();
    _revealAnim.dispose();
    _phoneCtrl.removeListener(_onPhoneChanged);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    _phoneFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PIN vs PREVIEW
  // ─────────────────────────────────────────────────────────────────────────

  /// True only when the CALLER explicitly resolved a specific provider
  /// (e.g. navigated here from that provider's own profile page). This
  /// is the ONLY case where we should force direct assignment.
  bool get _isPinnedProvider => widget.initialProviderId?.isNotEmpty == true;

  // ─────────────────────────────────────────────────────────────────────────
  // CATEGORY / SUBCATEGORY RESOLUTION
  //
  // FIX: for services like Laundry, the fabric-picker popup bakes the
  // fabric choice straight into the cart item's display name, e.g.
  // "Shirt (Cotton)". That's exactly what we WANT to show the customer
  // and the provider — but it's the WRONG string to feed into category
  // resolution: resolveCanonicalCategory() / categoryMatchFuzzy() try to
  // match this text against the provider's registered categories, and
  // "shirt (cotton)" normalizes to something like "shirtcotton", which
  // will essentially never equal or overlap with a clean registered
  // category like "Shirts". That mismatch was silently causing these
  // orders to match NO provider at all — the order existed in Firestore,
  // but no provider's dashboard ever showed it.
  //
  // `_cleanItemName()` strips a trailing " (Something)" annotation so
  // category resolution runs against the plain base product name, while
  // the fabric-annotated original text is still shown to the customer
  // (in the summary card) and to the provider (via `_itemBreakdown` /
  // `_autoItemsNote` below) — nothing about what the customer picked is
  // lost, it's just no longer allowed to break provider matching.
  // ─────────────────────────────────────────────────────────────────────────

  String _cleanItemName(String rawName) {
    final match = RegExp(r'^(.*?)\s*\([^()]*\)\s*$').firstMatch(rawName.trim());
    final cleaned = match?.group(1)?.trim() ?? '';
    return cleaned.isNotEmpty ? cleaned : rawName.trim();
  }

  // FIX: NEW — like `_cleanItemName()` but returns BOTH pieces instead of
  // discarding the fabric/variant annotation. Used to build a structured,
  // human-readable breakdown (see `_itemBreakdown` below) instead of the
  // collapsed, matching-only name that used to be all providers/admins
  // could see (which made "Washing (Wool)" and "Washing (Denim)" both
  // render as indistinguishable "Washing" chips on their dashboards).
  ({String base, String? variant}) _splitItemName(String rawName) {
    final match =
        RegExp(r'^(.*?)\s*\(([^()]*)\)\s*$').firstMatch(rawName.trim());
    if (match == null) {
      return (base: rawName.trim(), variant: null);
    }
    final base = match.group(1)?.trim();
    final variant = match.group(2)?.trim();
    return (
      base: (base != null && base.isNotEmpty) ? base : rawName.trim(),
      variant: (variant != null && variant.isNotEmpty) ? variant : null,
    );
  }

  String get _normalizedServiceType => widget.serviceName.trim().toLowerCase();

  String get _category {
    if (_isCart && _cartItems.isNotEmpty) {
      // FIX: previously always used `_cartItems.first.category` — if
      // that particular item somehow had an empty category (e.g. a
      // legacy/edge-case cart entry), the WHOLE order fell back to an
      // empty category and matched nobody. Now we scan for the first
      // item that actually HAS a non-empty category, so one blank
      // entry can't silently blank the whole order.
      final firstWithCategory = _cartItems.firstWhere(
        (i) => i.category.trim().isNotEmpty,
        orElse: () => _cartItems.first,
      );
      return resolveCanonicalCategory(
          firstWithCategory.category, _normalizedServiceType);
    }
    if (_isSingle && widget.product != null) {
      return resolveCanonicalCategory(
          widget.product!.service, _normalizedServiceType);
    }
    return '';
  }

  /// One level more specific than `_category`.
  ///
  /// FIX: this used to only get populated when the cart held EXACTLY one
  /// item, on the theory that `services[]` already carries per-item
  /// detail for multi-item carts. In practice `services[]` was being fed
  /// the fabric-annotated raw name (see `_cleanItemName()` above), which
  /// broke canonical resolution — so multi-item laundry carts (almost
  /// always 2+ items once a fabric+quantity picker is involved) ended up
  /// with BOTH `subCategory` blank AND unmatchable `services[]` entries.
  /// Now `subCategory` always carries the cleaned, matchable name of the
  /// first cart item — one more independent chance for a provider match,
  /// on top of the (now also cleaned) `services[]` list below.
  String get _subCategory {
    if (_isCart && _cartItems.isNotEmpty) {
      return resolveCanonicalCategory(
          _cleanItemName(_cartItems.first.name), _normalizedServiceType);
    }
    if (_isSingle && widget.product != null) {
      return resolveCanonicalCategory(
          widget.product!.name, _normalizedServiceType);
    }
    return '';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PROVIDER PREVIEW LOOKUP
  //

  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _fetchProviderName(String id) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('providers').doc(id).get();
      if (!mounted || !doc.exists) return;
      final d = doc.data()!;
      final b = (d['business'] as Map<String, dynamic>?) ?? {};
      setState(() => _providerName =
          (b['businessName'] ?? d['providerName'] ?? '').toString());
    } catch (_) {}
  }

  Future<void> _loadProvider() async {
    setState(() { _isLoadingProvider = true; _noProviderMessage = null; });
    try {
      final normSvc = _normalizedServiceType;

      // Synthetic "order" used only to run it through the exact same
      // matcher that real orders are matched against — guarantees the
      // preview agrees with what will actually happen on submit.
      final syntheticOrderData = <String, dynamic>{
        'category':    _category,
        'subCategory': _subCategory,
        'services':    _servicesForOrder,
        'serviceType': normSvc,
      };

      final approved = await FirebaseFirestore.instance
          .collection('providers')
          .where('status', isEqualTo: 'approved')
          .get();

      QueryDocumentSnapshot<Map<String, dynamic>>? svcOnlyMatch;
      QueryDocumentSnapshot<Map<String, dynamic>>? categoryMatchDoc;
      QueryDocumentSnapshot<Map<String, dynamic>>? unrestrictedLegacy;

      for (final doc in approved.docs) {
        final data = doc.data();

        // Tolerant of both top-level and nested serviceType shapes.
        final docSvc = providerServiceType(data);
        if (docSvc.isEmpty ||
            normalizeServiceType(docSvc) != normalizeServiceType(normSvc)) {
          continue;
        }

        svcOnlyMatch ??= doc;

        final cats    = providerCategories(data);
        final subCats = providerSubCategories(data);

        if (cats.isEmpty && subCats.isEmpty) {
          // Legacy/unrestricted — no categories saved at all.
          unrestrictedLegacy ??= doc;
          continue;
        }

        if (categoryMatchDoc == null &&
            categoryMatchFuzzy(syntheticOrderData, cats,
                providerSubCats: subCats)) {
          categoryMatchDoc = doc;
        }
      }

    
      final best = categoryMatchDoc ?? unrestrictedLegacy ?? svcOnlyMatch;

      if (best != null) {
        _setPreviewProvider(best.id, best.data());
      } else if (mounted) {
        setState(() {
          _noProviderMessage =
              'No approved provider for "${widget.serviceName}" yet.\nTry again later.';
          _isLoadingProvider = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _noProviderMessage = 'Could not load provider. Check your connection.';
        _isLoadingProvider = false;
      });
    }
  }

  void _setPreviewProvider(String id, Map<String, dynamic> d) {
    if (!mounted) return;
    final b = (d['business'] as Map<String, dynamic>?) ?? {};
    setState(() {
      _providerId        = id;
      _providerName      =
          (b['businessName'] ?? d['providerName'] ?? '').toString();
      _isLoadingProvider = false;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CART / TOTAL
  // ─────────────────────────────────────────────────────────────────────────

  List<CartItem> get _cartItems {
    if (widget.cart?.isNotEmpty == true) return widget.cart!;
    return Cart.getItems(widget.serviceName);
  }

  bool get _isCart   => _cartItems.isNotEmpty;
  bool get _isSingle => widget.product != null;

  double get _total => _isCart
      ? _cartItems.fold(
          0.0, (s, i) => s + (i.price * i.quantity).toDouble())
      : _isSingle
          ? widget.product!.calculatedFinalPrice.toDouble()
          : 0.0;

  /// Clean, matchable names used ONLY for provider category resolution
  /// (sent as the order's `services` field). See `_cleanItemName()` for
  /// why the fabric annotation is stripped here — the full fabric detail
  /// is never lost, it's preserved for humans in `_itemBreakdown` /
  /// `_autoItemsNote` below and in the on-screen summary card, which both
  /// use the raw cart item name directly.
  List<String> get _servicesForOrder => _isCart
      ? _cartItems.map((e) => _cleanItemName(e.name)).toList()
      : [widget.product?.name ?? widget.serviceName];

  /// FIX: NEW — a structured, per-item breakdown (base service name +
  /// variant/fabric + quantity) sent to `OrderService.placeOrder()` as
  /// `itemBreakdown`. This is saved to Firestore purely for DISPLAY on
  /// the provider/admin dashboards, completely separate from the
  /// cleaned/canonical `services` field used for matching. This is what
  /// actually fixes "Washing, Washing" showing up with no way to tell
  /// which fabric is which — the provider dashboard can now render
  /// "Washing: 1 Wool, 1 Denim" using this exact structure.
  List<Map<String, dynamic>> get _itemBreakdown {
    if (!_isCart || _cartItems.isEmpty) return [];
    return _cartItems.map((item) {
      final split = _splitItemName(item.name);
      return <String, dynamic>{
        'service':     split.base,
        'variant':     split.variant ?? '',
        'quantity':    item.quantity,
        'displayName': item.name,
      };
    }).toList();
  }

  /// FIX: NEW — a human-readable line grouping every cart item by its
  /// base service name with each variant/fabric + quantity listed under
  /// it, e.g. "Washing: 1 Wool, 1 Denim". This is prepended to the
  /// booking note so the fabric/quantity choice from the popup is
  /// GUARANTEED visible on the provider's dashboard card (which renders
  /// the note prominently) — regardless of how category matching turns
  /// out, and regardless of whether the admin/provider UI has been
  /// updated yet to read the new `itemBreakdown` field directly.
  String get _autoItemsNote {
    if (!_isCart || _cartItems.isEmpty) return '';

    final grouped = <String, List<String>>{};
    for (final item in _cartItems) {
      final split = _splitItemName(item.name);
      final label = split.variant != null
          ? '${item.quantity} ${split.variant}'
          : '${item.quantity} pc${item.quantity == 1 ? '' : 's'}';
      grouped.putIfAbsent(split.base, () => []).add(label);
    }

    final lines =
        grouped.entries.map((e) => '${e.key}: ${e.value.join(', ')}').join(' | ');
    return 'Items: $lines';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        extendBody: true,
        resizeToAvoidBottomInset: true,
        body: _isSuccess ? _buildSuccessView() : _buildMainView(),
        bottomNavigationBar: _isSuccess ? null : _buildBottomBar(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MAIN VIEW
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMainView() {
    return FadeTransition(
      opacity: _pageFade,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoadingProvider
                ? _buildLoadingState()
                : _noProviderMessage != null
                    ? _buildNoProviderState()
                    : _buildBody(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER  (safe-area aware)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 14, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kAccent, _kAccentSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          _circleBtn(
            icon:  Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Book Service',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text(widget.serviceName,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Only show a specific provider's name when this is a genuine
          // pinned assignment — otherwise showing one name would wrongly
          // imply that specific provider is guaranteed to get this order.
          if (_isPinnedProvider && _providerName?.isNotEmpty == true)
            _providerChip(_providerName!),
        ],
      ),
    );
  }

  Widget _circleBtn(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _providerChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.storefront_rounded,
              color: Colors.white, size: 13),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 90),
            child: Text(name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BODY
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ListView(
      controller: _scrollCtrl,
      padding: EdgeInsets.fromLTRB(16, 18, 16, 16 + bottomInset),
      children: [

        // ── SERVICES SUMMARY (always visible, collapsible) ──────────────
        _ServicesSummaryCard(
          cartItems:   _isCart ? _cartItems : null,
          productName: _isSingle
              ? (widget.product?.name ?? widget.serviceName)
              : null,
          total:       _total,
          expanded:    _summaryExpanded,
          onToggle:    () =>
              setState(() => _summaryExpanded = !_summaryExpanded),
        ),

        const SizedBox(height: 20),

        // ── STEP 1 ──────────────────────────────────────────────────────
        _StepHeader(number: 1, label: 'Your Details'),
        const SizedBox(height: 10),
        _buildDetailsCard(),

        // ── STEPS 2 & 3 revealed after phone is complete ────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          child: _phoneComplete
              ? SlideTransition(
                  position: _revealSlide,
                  child: FadeTransition(
                    opacity: _revealFade,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _StepHeader(number: 2, label: 'Schedule'),
                        const SizedBox(height: 10),
                        _buildDateTimeRow(),
                        const SizedBox(height: 24),
                        _StepHeader(number: 3, label: 'Additional Note'),
                        const SizedBox(height: 10),
                        _buildNoteCard(),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 120),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1 — Details card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDetailsCard() {
    return _Card(
      child: Column(
        children: [
          _Field(
            controller: _nameCtrl,
            hint: 'Full name',
            icon: Icons.person_outline_rounded,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _phoneCtrl,
            hint: 'Mobile number',
            icon: Icons.phone_outlined,
            keyboard: TextInputType.phone,
            focusNode: _phoneFocus,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            suffix: _phoneComplete
                ? const Icon(Icons.check_circle_rounded,
                    color: _kSuccess, size: 20)
                : null,
          ),
          if (!_phoneComplete) ...[
            const SizedBox(height: 6),
            _hintRow('Enter 10-digit number to unlock schedule'),
          ],
          const SizedBox(height: 12),
          _Field(
            controller: _addressCtrl,
            hint: 'Full address',
            icon: Icons.location_on_outlined,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _OutlineBtn(
              icon:  Icons.map_outlined,
              label: 'Pick on Map',
              onTap: _openMapPicker,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2 — Date + Time
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDateTimeRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 320;
        final dateTile = _PickerTile(
          icon:     Icons.calendar_month_rounded,
          label:    'Date',
          value:    _date == null
              ? 'Tap to pick'
              : DateFormat('dd MMM yyyy').format(_date!),
          selected: _date != null,
          onTap:    _pickDate,
        );
        final timeTile = _PickerTile(
          icon:     Icons.access_time_rounded,
          label:    'Time',
          value:    _time == null ? 'Tap to pick' : _time!.format(context),
          selected: _time != null,
          onTap:    _pickTime,
        );

        if (narrow) {
          return Column(
            children: [
              dateTile,
              const SizedBox(height: 12),
              timeTile,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: dateTile),
            const SizedBox(width: 12),
            Expanded(child: timeTile),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 3 — Note
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildNoteCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(
            controller: _noteCtrl,
            hint: 'Any special request? (optional)',
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
          // FIX: NEW — lets the customer see, before they even submit,
          // exactly what will be sent to the provider as the item/fabric
          // breakdown (see `_autoItemsNote`). Purely informational; it's
          // appended to the note automatically in `_save()` regardless.
          if (_isCart && _cartItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F2FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.checklist_rounded,
                      size: 15, color: _kAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _autoItemsNote,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOTTOM BAR
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final bottom     = MediaQuery.of(context).viewPadding.bottom;
    final canProceed =
        !_isLoading && !_isLoadingProvider && _providerId != null;

    final step1Done = _nameCtrl.text.trim().isNotEmpty &&
        _phoneComplete &&
        _addressCtrl.text.trim().isNotEmpty;
    final step2Done = _date != null && _time != null;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + bottom),
        decoration: const BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProgressRow(step1: _phoneComplete, step2: step1Done && step2Done),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    (canProceed && _phoneComplete) ? _validateAndPay : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:         _kAccent,
                  disabledBackgroundColor: const Color(0xFFD0CBEE),
                  foregroundColor:         Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Proceed to Payment',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('₹${_total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUCCESS VIEW
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSuccessView() {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    final top    = MediaQuery.of(context).padding.top;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(32, top + 32, 32, bottom + 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - top - bottom - 64,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                color: _kSuccess.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: _kSuccess, size: 60),
            ),
            const SizedBox(height: 28),
            const Text('All Done!',
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text(
              'Your booking has been confirmed.\n'
              'We\'ll notify you once a provider accepts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EEF9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.confirmation_number_outlined,
                      size: 15, color: _kAccent),
                  const SizedBox(width: 6),
                  Text('ID: $_bookingId',
                      style: const TextStyle(
                          color: _kAccent,
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _goHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text('Back to Home',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOADING / NO-PROVIDER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildLoadingState() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _kAccent),
            SizedBox(height: 16),
            Text('Finding a provider…',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );

  Widget _buildNoProviderState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.store_mall_directory_outlined,
                    size: 52, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 20),
              Text(_noProviderMessage ?? 'No provider available',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                      height: 1.6)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadProvider,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // PICKERS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kAccent),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kAccent),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MAP PICKER
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MapPickerPage(initialLatLng: _pickedLatLng),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _pickedLatLng = result.latLng);
    final details = result.addressDetails.isNotEmpty
        ? '${result.addressDetails}, ${result.fullAddress}'
        : result.fullAddress;
    _addressCtrl.text = details;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VALIDATE + PAY + SAVE
  // ─────────────────────────────────────────────────────────────────────────

  void _validateAndPay() {
    if (_providerId == null || _providerId!.isEmpty) {
      _showSnack('No provider available for this service.'); return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack('Please enter your name.'); return;
    }
    if (_phoneCtrl.text.trim().length < 10) {
      _showSnack('Enter a valid 10-digit number.'); return;
    }
    if (_addressCtrl.text.trim().isEmpty) {
      _showSnack('Please enter your address.'); return;
    }
    if (_date == null || _time == null) {
      _showSnack('Please pick a date and time.'); return;
    }
    if (_total <= 0) {
      _showSnack('No services selected. Go back and add a service.'); return;
    }
    _pay();
  }

  Future<void> _pay() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          serviceName: widget.serviceName,
          amount: _total.toInt(),
        ),
      ),
    );
    if (!mounted) return;
    if (result != null && result != false) {
      await _save();
    } else {
      _showSnack('Payment was not completed. Please try again.');
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      // FIX: the fabric/quantity breakdown (`_autoItemsNote`) is always
      // prepended to whatever the customer typed, so it reaches the
      // provider guaranteed — via the `note` field, which the provider
      // dashboard already renders prominently — instead of relying
      // solely on category-matching machinery to carry that detail.
      final userNote  = _noteCtrl.text.trim();
      final itemsNote = _autoItemsNote;
      final combinedNote = [itemsNote, userNote]
          .where((s) => s.isNotEmpty)
          .join('\n');

      final ref = await OrderService.placeOrder(
        serviceType:   _normalizedServiceType,
        services:      _servicesForOrder,
        userId:        user.uid,
        userName:      _nameCtrl.text.trim(),
        phone:         _phoneCtrl.text.trim(),
        email:         user.email ?? '',
        address:       _addressCtrl.text.trim(),
        note:          combinedNote,
        date:          _date!,
        time:          _time!.format(context),
        totalAmount:   _total,
        createdBy:     user.uid,
        createdByRole: 'user',

        // NOW passed explicitly, properly canonicalized — this is the
        // #1 fix for reliable routing (see resolveCanonicalCategory()
        // in order_service.dart).
        category:      _category,
        subCategory:   _subCategory,

        // FIX: NEW — structured, un-collapsed item breakdown so the
        // provider/admin dashboards can render "Washing: 1 Wool, 1
        // Denim" instead of two indistinguishable "Washing" chips.
        itemBreakdown: _itemBreakdown,

        // THE KEY FIX: only pin a provider when the caller explicitly
        // chose one. Otherwise omit providerId so placeOrder() fans out
        // to every approved provider whose categories/subCategories
        // actually match — instead of silently notifying only whoever
        // _loadProvider()'s preview search happened to land on.
        providerId:    _isPinnedProvider ? _providerId : null,
        providerName:  _isPinnedProvider ? (_providerName ?? '') : '',
      );

      // Booking succeeded — clear this service's cart.
      Cart.clear(widget.serviceName);

      if (!mounted) return;
      setState(() {
        _bookingId = ref.id;
        _isSuccess = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Could not save booking: $e');
    }
  }

  void _goHome() {
    final user = FirebaseAuth.instance.currentUser;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => BottomNavPage(
          userPhone: user?.phoneNumber ?? _phoneCtrl.text,
          userEmail: user?.email ?? '',
        ),
      ),
      (_) => false,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    ));
  }

  Widget _hintRow(String text) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 13, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICES SUMMARY CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ServicesSummaryCard extends StatelessWidget {
  final List<CartItem>? cartItems;
  final String?         productName;
  final double          total;
  final bool            expanded;
  final VoidCallback    onToggle;

  const _ServicesSummaryCard({
    required this.total,
    required this.expanded,
    required this.onToggle,
    this.cartItems,
    this.productName,
  });

  @override
  Widget build(BuildContext context) {
    final hasItems = cartItems != null && cartItems!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B4FCF), Color(0xFF7B6FE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B4FCF).withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      color: Colors.white70, size: 20),
                  const SizedBox(width: 10),
                  const Text('Your Services',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('₹${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: expanded
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20)),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 12),
                        if (hasItems)
                          ...cartItems!.map((item) => _SummaryRow(
                                name:  item.name,
                                qty:   item.quantity,
                                price: (item.price * item.quantity).toDouble(),
                              ))
                        else if (productName != null)
                          _SummaryRow(
                            name:  productName!,
                            qty:   1,
                            price: total,
                          ),
                        const SizedBox(height: 6),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            Text('₹${total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY ROW
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String name;
  final int    qty;
  final num    price;

  const _SummaryRow({
    required this.name,
    required this.qty,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
                color: Colors.white54, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
          Text('x$qty',
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(width: 12),
          Text('₹${price.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final int    number;
  final String label;

  const _StepHeader({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_kAccent, _kAccentSoft]),
            shape: BoxShape.circle,
          ),
          child: Text('$number',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS ROW
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  final bool step1;
  final bool step2;

  const _ProgressRow({required this.step1, required this.step2});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dot(done: step1, label: 'Details'),
        _line(done: step1),
        _dot(done: step2, label: 'Schedule'),
        _line(done: step2),
        _dot(done: false, label: 'Payment'),
      ],
    );
  }

  Widget _dot({required bool done, required String label}) {
    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: done ? _kAccent : const Color(0xFFDDDAF5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: done ? _kAccent : Colors.grey.shade400,
                  fontWeight: done ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _line({required bool done}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 2, width: 36,
      color: done ? _kAccent : const Color(0xFFE8E6F7),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PICKER TILE
// ─────────────────────────────────────────────────────────────────────────────

class _PickerTile extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final String       value;
  final bool         selected;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? _kAccent.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? _kAccent.withOpacity(0.5)
                : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(blurRadius: 10,
                color: Colors.black.withOpacity(0.04)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? _kAccent.withOpacity(0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: selected ? _kAccent : Colors.grey.shade400,
                  size: 18),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: selected ? _kAccent : Colors.grey.shade400,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD WRAPPER
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIELD
// ─────────────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController        controller;
  final String                       hint;
  final IconData                     icon;
  final TextInputType                keyboard;
  final int                          maxLines;
  final FocusNode?                   focusNode;
  final List<TextInputFormatter>?    formatters;
  final Widget?                      suffix;
  final ValueChanged<String>?        onChanged;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboard  = TextInputType.text,
    this.maxLines  = 1,
    this.focusNode,
    this.formatters,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller:      controller,
        keyboardType:    keyboard,
        maxLines:        maxLines,
        focusNode:       focusNode,
        inputFormatters: formatters,
        onChanged:       onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: _kAccent, size: 20),
          suffixIcon: suffix != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: suffix)
              : null,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OUTLINE BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _OutlineBtn extends StatelessWidget {
  final IconData?     icon;
  final String        label;
  final bool          loading;
  final VoidCallback? onTap;

  const _OutlineBtn({
    required this.label,
    this.icon,
    bool loading = false,
    this.onTap,
  }) : loading = loading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _kAccent,
        side: const BorderSide(color: _kAccent, width: 1.4),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
      icon: loading
          ? const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                  color: _kAccent, strokeWidth: 2))
          : Icon(icon, size: 17),
      label: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}