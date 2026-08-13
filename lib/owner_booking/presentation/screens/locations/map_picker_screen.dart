import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:toastification/toastification.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const MapPickerScreen({super.key, this.initialLocation});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _pickedLocation;
  String? _address;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
    if (_pickedLocation != null) {
      _fetchAddress(_pickedLocation!);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    // Optionally use the controller if needed
  }

  void _onTap(LatLng position) {
    setState(() {
      _pickedLocation = position;
      _address = null;
    });
    _fetchAddress(position);
  }

  Future<void> _fetchAddress(LatLng position) async {
    setState(() {
      _isLoadingAddress = true;
    });
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final addressParts = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.postalCode,
          p.country
        ].where((part) => part != null && part.isNotEmpty).toList();
        
        setState(() {
          _address = addressParts.join(', ');
        });
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text('Could not fetch address'),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialCameraPosition = CameraPosition(
      target: widget.initialLocation ?? const LatLng(20.5937, 78.9629),
      zoom: widget.initialLocation != null ? 15 : 4.5,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primaryDarkGreen,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialCameraPosition,
            onMapCreated: _onMapCreated,
            onTap: _onTap,
            markers: _pickedLocation == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('picked_location'),
                      position: _pickedLocation!,
                    ),
                  },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
          ),
          if (_pickedLocation != null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoadingAddress)
                        const CircularProgressIndicator(color: AppColors.primaryDarkGreen)
                      else if (_address != null)
                        Text(
                          _address!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      const SizedBox(height: 16),
                      AppButton(
                        title: 'Confirm Location',
                        backgroundColor: AppColors.primaryDarkGreen,
                        onTap: () {
                          Navigator.of(context).pop({
                            'location': _pickedLocation,
                            'address': _address,
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
