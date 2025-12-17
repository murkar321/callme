import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  GoogleMapController? mapController;
  LatLng? selectedLatLng;
  String selectedAddress = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      selectedLatLng = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _getAddress(LatLng latLng) async {
    final placemarks =
        await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
    final place = placemarks.first;

    setState(() {
      selectedAddress =
          '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (selectedLatLng == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Select Address')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: selectedLatLng!,
              zoom: 16,
            ),
            onMapCreated: (controller) => mapController = controller,
            myLocationEnabled: true,
            onTap: (latLng) async {
              selectedLatLng = latLng;
              await _getAddress(latLng);
            },
            markers: selectedLatLng == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: selectedLatLng!,
                    ),
                  },
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: selectedAddress.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context, selectedAddress);
                    },
              child: const Text('Confirm Address'),
            ),
          ),
        ],
      ),
    );
  }
}
