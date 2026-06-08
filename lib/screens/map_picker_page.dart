
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────
//  🔑  PUT YOUR GOOGLE API KEY HERE
// ─────────────────────────────────────────────
const String _kGoogleApiKey = 'AIzaSyBaPH1fJfFbf9nTW64HCkBr5FViH3AlXw8';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage>
    with SingleTickerProviderStateMixin {
  // ── Map ──
  GoogleMapController? _mapController;
  LatLng? _pickedLatLng;
  Set<Marker> _markers = {};

  // ── Address ──
  String _shortAddress = '';
  String _fullAddress = '';
  bool _addressLoading = false;

  // ── Page loading ──
  bool _loading = true;

  // ── Pin animation ──
  late AnimationController _pinAnimController;
  late Animation<double> _pinLiftAnim;

  // ── Search ──
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<Map<String, dynamic>> _predictions = [];
  bool _showSuggestions = false;
  Timer? _debounce;

  // ── Address details ──
  final TextEditingController _detailsController = TextEditingController();

  // ── Bottom sheet ──
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // ── Debounce for onCameraIdle ──
  Timer? _geocodeDebounce;

  @override
  void initState() {
    super.initState();

    _pinAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _pinLiftAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pinAnimController, curve: Curves.easeOut),
    );

    _getCurrentLocation();
  }

  @override
  void dispose() {
    _pinAnimController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _detailsController.dispose();
    _debounce?.cancel();
    _geocodeDebounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────
  //  LOCATION
  // ──────────────────────────────────────────

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Location permission denied. Please enable in settings.');
        setState(() => _loading = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _pickedLatLng = LatLng(pos.latitude, pos.longitude);
      await Future.wait([
        _reverseGeocode(_pickedLatLng!),
        _fetchNearbyPlaces(_pickedLatLng!),
      ]);
    } catch (e) {
      _showSnack('Could not get location: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latlng = LatLng(pos.latitude, pos.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(latlng, 16),
      );
    } catch (_) {}
  }

  // ──────────────────────────────────────────
  //  REVERSE GEOCODING  (Google Geocoding API)
  // ──────────────────────────────────────────

  Future<void> _reverseGeocode(LatLng latlng) async {
    if (mounted) setState(() => _addressLoading = true);
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${latlng.latitude},${latlng.longitude}'
        '&key=$_kGoogleApiKey',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final result = data['results'][0];
        final components =
            result['address_components'] as List<dynamic>;

        String sublocality = '';
        String locality = '';
        String city = '';
        String state = '';
        String country = '';
        String postalCode = '';

        for (final c in components) {
          final types = List<String>.from(c['types']);
          if (types.contains('sublocality_level_1') ||
              types.contains('sublocality')) {
            sublocality = c['long_name'];
          } else if (types.contains('locality')) {
            locality = c['long_name'];
          } else if (types.contains('administrative_area_level_2')) {
            city = c['long_name'];
          } else if (types.contains('administrative_area_level_1')) {
            state = c['long_name'];
          } else if (types.contains('country')) {
            country = c['long_name'];
          } else if (types.contains('postal_code')) {
            postalCode = c['long_name'];
          }
        }

        final short = [sublocality, locality.isNotEmpty ? locality : city]
            .where((s) => s.isNotEmpty)
            .join(', ');

        final full = [
          sublocality,
          locality,
          city != locality ? city : '',
          state,
          postalCode,
          country,
        ].where((s) => s.isNotEmpty).join(', ');

        if (mounted) {
          setState(() {
            _pickedLatLng = latlng;
            _shortAddress = short.isNotEmpty ? short : 'Selected location';
            _fullAddress =
                full.isNotEmpty ? full : result['formatted_address'] ?? '';
          });
        } 
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _shortAddress = 'Selected location';
          _fullAddress = '${latlng.latitude.toStringAsFixed(5)}, '
              '${latlng.longitude.toStringAsFixed(5)}';
        });
      }
    } finally {
      if (mounted) setState(() => _addressLoading = false);
    }
  }

  // ──────────────────────────────────────────
  //  NEARBY PLACES  (Google Places Nearby Search)
  // ──────────────────────────────────────────

  Future<void> _fetchNearbyPlaces(LatLng center) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${center.latitude},${center.longitude}'
        '&radius=400'
        '&key=$_kGoogleApiKey',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['status'] == 'OK') {
        final places = data['results'] as List<dynamic>;
        final newMarkers = <Marker>{};

        for (final place in places.take(15)) {
          final loc = place['geometry']['location'];
          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();
          final name = place['name'] as String;
          final placeId = place['place_id'] as String;

          newMarkers.add(
            Marker(
              markerId: MarkerId(placeId),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(title: name),
              icon: await _buildNearbyMarkerIcon(name),
              onTap: () {
                _mapController?.showMarkerInfoWindow(MarkerId(placeId));
              },
            ),
          );
        }

        if (mounted) setState(() => _markers = newMarkers);
      }
    } catch (_) {
      // Nearby places are non-critical; silently ignore
    }
  }

  /// Builds a white rounded label marker like in the reference image
  Future<BitmapDescriptor> _buildNearbyMarkerIcon(String label) async {
    // Truncate long names

    // Use default blue dot for simplicity — customise further with canvas if needed
    // For production: use flutter_map_marker_cluster or custom canvas painter
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
  }

  // ──────────────────────────────────────────
  //  PLACES AUTOCOMPLETE
  // ──────────────────────────────────────────

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _predictions = [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchPredictions(value.trim());
    });
  }

  Future<void> _fetchPredictions(String input) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '&key=$_kGoogleApiKey'
        '&language=en',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['status'] == 'OK') {
        if (mounted) {
          setState(() {
            _predictions =
                List<Map<String, dynamic>>.from(data['predictions']);
            _showSuggestions = true;
          });
        }
      } else {
        if (mounted) setState(() => _showSuggestions = false);
      }
    } catch (_) {}
  }

  Future<void> _onPredictionSelected(Map<String, dynamic> prediction) async {
    final placeId = prediction['place_id'];
    FocusScope.of(context).unfocus();
    setState(() {
      _showSuggestions = false;
      _searchController.text =
          prediction['structured_formatting']?['main_text'] ??
              prediction['description'];
      _predictions = [];
    });

    // Get place details → lat/lng
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=geometry,name,formatted_address'
        '&key=$_kGoogleApiKey',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['status'] == 'OK') {
        final loc = data['result']['geometry']['location'];
        final latlng =
            LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(latlng, 16),
        );

        await Future.wait([
          _reverseGeocode(latlng),
          _fetchNearbyPlaces(latlng),
        ]);
      }
    } catch (_) {}
  }

  // ──────────────────────────────────────────
  //  CAMERA IDLE → reverse geocode center
  // ──────────────────────────────────────────

  void _onCameraIdle() {
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (_mapController == null) return;
      final bounds = await _mapController!.getVisibleRegion();
      final center = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );
      await Future.wait([
        _reverseGeocode(center),
        _fetchNearbyPlaces(center),
      ]);
    });
  }

  // ──────────────────────────────────────────
  //  HELPERS
  // ──────────────────────────────────────────

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ──────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE8344E)),
        ),
      );
    }

    final screenH = MediaQuery.of(context).size.height;
    // Map occupies top 60% of the screen; bottom sheet the rest
    const sheetMinFraction = 0.38;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() => _showSuggestions = false);
        },
        child: Stack(
          children: [
            // ── 1. GOOGLE MAP ──────────────────────────────
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _pickedLatLng ?? const LatLng(19.076, 72.877),
                  zoom: 16,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (ctrl) {
                  _mapController = ctrl;
                },
                onCameraMoveStarted: () {
                  _pinAnimController.forward();
                },
                onCameraIdle: () {
                  _pinAnimController.reverse();
                  _onCameraIdle();
                },
              ),
            ),

            // ── 2. CENTER PIN ──────────────────────────────
            IgnorePointer(
              child: Align(
                alignment: Alignment.center,
                child: AnimatedBuilder(
                  animation: _pinLiftAnim,
                  builder: (_, __) {
                    final lift = _pinLiftAnim.value * 14.0;
                    final shadowScale = 1.0 + _pinLiftAnim.value * 0.4;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.translate(
                          offset: Offset(0, -lift),
                          child: const Icon(
                            Icons.location_pin,
                            size: 48,
                            color: Color(0xFFE8344E),
                          ),
                        ),
                        Transform.scale(
                          scale: shadowScale,
                          child: Container(
                            width: 12,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(
                                  0.25 - _pinLiftAnim.value * 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ── 3. TOP BAR (Back + Title + Search) ────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back + Title
                      Row(
                        children: [
                          _CircleButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Select delivery location',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onChanged: _onSearchChanged,
                          onTap: () {
                            if (_searchController.text.isNotEmpty) {
                              setState(() => _showSuggestions = true);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Search for area, street name...',
                            hintStyle: TextStyle(
                                color: Colors.grey.shade400, fontSize: 14),
                            prefixIcon: const Icon(Icons.search,
                                color: Color(0xFFE8344E), size: 22),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.close,
                                        color: Colors.grey.shade400,
                                        size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _predictions = [];
                                        _showSuggestions = false;
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── 4. AUTOCOMPLETE SUGGESTIONS ───────────────
            if (_showSuggestions && _predictions.isNotEmpty)
              Positioned(
                top: MediaQuery.of(context).padding.top + 110,
                left: 12,
                right: 12,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _predictions.length > 6
                          ? 6
                          : _predictions.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.grey.shade100,
                      ),
                      itemBuilder: (context, i) {
                        final p = _predictions[i];
                        final main =
                            p['structured_formatting']?['main_text'] ??
                                p['description'];
                        final secondary =
                            p['structured_formatting']?['secondary_text'] ??
                                '';
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined,
                              color: Color(0xFFE8344E), size: 20),
                          title: Text(
                            main,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87),
                          ),
                          subtitle: secondary.isNotEmpty
                              ? Text(
                                  secondary,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          onTap: () => _onPredictionSelected(p),
                        );
                      },
                    ),
                  ),
                ),
              ),

            // ── 5. "USE CURRENT LOCATION" BUTTON ──────────
            Positioned(
              bottom: screenH * sheetMinFraction + 12,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _goToCurrentLocation();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Target circle icon
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFFE8344E),
                                      width: 2),
                                ),
                              ),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFE8344E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Use current location',
                          style: TextStyle(
                            color: Color(0xFFE8344E),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── 6. BOTTOM SHEET ────────────────────────────
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: sheetMinFraction,
              minChildSize: sheetMinFraction,
              maxChildSize: 0.65,
              snap: true,
              snapSizes: const [sheetMinFraction, 0.65],
              builder: (context, scrollCtrl) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(22)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 18,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ListView(
                    controller: scrollCtrl,
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),

                      // Section label
                      Text(
                        'Delivery details',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Address tile ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.grey.shade200, width: 1.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Icon(Icons.location_on,
                                  color: const Color(0xFFE8344E),
                                  size: 22),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _addressLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFE8344E),
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _shortAddress.isNotEmpty
                                              ? _shortAddress
                                              : 'Move map to pick location',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (_fullAddress.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            _fullAddress,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color:
                                                  Colors.grey.shade600,
                                            ),
                                            maxLines: 2,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                            ),
                            Icon(Icons.chevron_right,
                                color: Colors.grey.shade400, size: 20),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Address details input ──
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.grey.shade300, width: 1.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _detailsController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Address details*',
                            labelStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                            hintText: 'Flat / Floor / Building name',
                            hintStyle:
                                TextStyle(color: Colors.grey.shade400),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            suffixIcon: _detailsController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.cancel,
                                        color: Colors.grey.shade400,
                                        size: 20),
                                    onPressed: () {
                                      _detailsController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Save button ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _fullAddress.isEmpty
                              ? null
                              : () {
                                  HapticFeedback.mediumImpact();
                                  Navigator.pop(context, {
                                    'shortAddress': _shortAddress,
                                    'fullAddress': _fullAddress,
                                    'addressDetails': _detailsController.text,
                                    'latLng': _pickedLatLng,
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8344E),
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Save address',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Helper: circular icon button (top bar)
// ─────────────────────────────────────────────
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }
}