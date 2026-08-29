import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:turfpro_owner/common/constants/colors.dart';

class MapPickerScreen extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;

  const MapPickerScreen({
    super.key,
    this.initialLatitude = 20.5937,
    this.initialLongitude = 78.9629,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late LatLng _pickedLocation;
  String _address = 'Move the pin to select your venue location';
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = false;
  
  // Search state
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _pickedLocation = LatLng(
      widget.initialLatitude != 0.0 ? widget.initialLatitude : 20.5937,
      widget.initialLongitude != 0.0 ? widget.initialLongitude : 78.9629,
    );
    
    _searchFocusNode.addListener(() {
      setState(() {}); // Re-build to show/hide dropdown
      if (_searchFocusNode.hasFocus) {
        // Optionally select all text when focused
        _searchController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _searchController.text.length,
        );
      } else {
        // Reset text to current address when losing focus
        _searchController.text = _address;
        _searchResults.clear();
      }
    });

    if (widget.initialLatitude != 0.0) {
      _reverseGeocode(_pickedLocation);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() => _isSearching = true);
      try {
        final locations = await locationFromAddress(query);
        List<Map<String, dynamic>> results = [];
        
        // Process top 5 locations to get their addresses
        for (var loc in locations.take(5)) {
           try {
             final placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
             if (placemarks.isNotEmpty) {
               final p = placemarks.first;
               final parts = [
                 p.name,
                 p.street,
                 p.subLocality,
                 p.locality,
                 p.administrativeArea,
               ].where((e) => e != null && e.isNotEmpty).toSet().join(', ');
               
               results.add({
                 'address': parts.isNotEmpty ? parts : 'Unknown Location',
                 'location': LatLng(loc.latitude, loc.longitude)
               });
             }
           } catch (e) {
             // Ignore individual reverse geocode failures
           }
        }
        
        if (mounted) {
          setState(() => _searchResults = results);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _searchResults = []);
        }
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  Future<void> _zoomIn() async {
    final ctrl = await _controller.future;
    ctrl.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    final ctrl = await _controller.future;
    ctrl.animateCamera(CameraUpdate.zoomOut());
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _isLoadingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
        
        setState(() {
          _address = parts.isNotEmpty ? parts : 'Location selected';
          if (!_searchFocusNode.hasFocus) {
            _searchController.text = _address;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _address = 'Location selected';
          if (!_searchFocusNode.hasFocus) {
            _searchController.text = _address;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied.'),
            ),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final newPos = LatLng(pos.latitude, pos.longitude);

      final ctrl = await _controller.future;
      ctrl.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: newPos, zoom: 16),
      ));

      setState(() => _pickedLocation = newPos);
      _reverseGeocode(newPos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Map ─────────────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLocation,
              zoom: widget.initialLatitude != 0.0 ? 16 : 5,
            ),
            onMapCreated: (ctrl) => _controller.complete(ctrl),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onTap: (pos) async {
              _searchFocusNode.unfocus();
              final ctrl = await _controller.future;
              final zoom = await ctrl.getZoomLevel();
              ctrl.animateCamera(CameraUpdate.newCameraPosition(
                CameraPosition(target: pos, zoom: zoom),
              ));
              setState(() => _pickedLocation = pos);
              _reverseGeocode(pos);
            },
            onCameraMove: (pos) {
              _pickedLocation = pos.target;
            },
            onCameraIdle: () {
              _reverseGeocode(_pickedLocation);
            },
          ),

          // ── Centre Pin ──────────────────────────────────────────────────
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 44), // offset for pin stem
              child: _CentrePin(),
            ),
          ),

          // ── Top App Bar & Search ────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Back Button
                        Material(
                          color: Colors.white,
                          elevation: 4,
                          shadowColor: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.pop(context),
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Unified Search Bar
                        Expanded(
                          child: Material(
                            color: Colors.white,
                            elevation: 4,
                            shadowColor: Colors.black26,
                            borderRadius: BorderRadius.circular(12),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onChanged: _onSearchChanged,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search for a location...',
                                hintStyle: const TextStyle(fontWeight: FontWeight.normal),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                prefixIcon: const Icon(Icons.search, color: Colors.red, size: 22),
                                suffixIcon: _isLoadingAddress
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty)
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, size: 20),
                                            onPressed: () {
                                              _searchController.clear();
                                              _onSearchChanged('');
                                            },
                                          )
                                        : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Search Results Dropdown
                    if (_searchFocusNode.hasFocus && (_searchResults.isNotEmpty || _isSearching))
                      Container(
                        margin: const EdgeInsets.only(top: 8, left: 44),
                        constraints: const BoxConstraints(maxHeight: 250),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _searchResults.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final result = _searchResults[index];
                                  return ListTile(
                                    leading: const Icon(Icons.location_on, color: Colors.grey, size: 20),
                                    title: Text(
                                      result['address'],
                                      style: const TextStyle(fontSize: 13),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () async {
                                      _searchFocusNode.unfocus();
                                      final pos = result['location'] as LatLng;
                                      
                                      final ctrl = await _controller.future;
                                      ctrl.animateCamera(CameraUpdate.newCameraPosition(
                                        CameraPosition(target: pos, zoom: 16),
                                      ));
                                      
                                      setState(() {
                                        _pickedLocation = pos;
                                        _searchController.text = result['address'];
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Zoom Buttons ───────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 180,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _zoomIn,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.add, color: AppColors.primaryDarkGreen, size: 22),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _zoomOut,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.remove, color: AppColors.primaryDarkGreen, size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── My Location Button ─────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 120,
            child: Material(
              color: Colors.white,
              elevation: 4,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isLoadingLocation ? null : _goToCurrentLocation,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _isLoadingLocation
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded,
                          color: AppColors.primaryDarkGreen, size: 22),
                ),
              ),
            ),
          ),

          // ── Confirm Button ─────────────────────────────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'location': _pickedLocation,
                'address': _address,
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppColors.primaryDarkGreen.withValues(alpha: 0.4),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Confirm Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated pin that bounces to indicate draggability
class _CentrePin extends StatefulWidget {
  const _CentrePin();

  @override
  State<_CentrePin> createState() => _CentrePinState();
}

class _CentrePinState extends State<_CentrePin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _bounce.value),
        child: child,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryDarkGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDarkGreen.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.location_on_rounded,
                color: Colors.white, size: 26),
          ),
          // Pin stem
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primaryDarkGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Shadow dot
          Container(
            width: 10,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
