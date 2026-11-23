import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
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
  bool _skipNextIdleReverseGeocode = false;
  
  // Search state
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Default to Ahmedabad, Gujarat if no coordinates are passed
    _pickedLocation = LatLng(
      widget.initialLatitude != 0.0 ? widget.initialLatitude : 23.0225,
      widget.initialLongitude != 0.0 ? widget.initialLongitude : 72.5714,
    );
    
    _searchFocusNode.addListener(() {
      setState(() {}); // Re-build to show/hide dropdown
      if (_searchFocusNode.hasFocus) {
        // Select all text when focused so user can easily search
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
    } else {
      // Auto-locate to device location on new venue creation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _goToCurrentLocation();
      });
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

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearching = true);
      final results = await _searchPlaces(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  /// Robust multi-source place search (handles landmarks, cross roads, spelling variations)
  Future<List<Map<String, dynamic>>> _searchPlaces(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    double lat = _pickedLocation.latitude;
    double lon = _pickedLocation.longitude;
    // If coordinates are outside India (e.g. iOS Simulator default Cupertino), default bias to Ahmedabad
    if (lat < 6.0 || lat > 38.0 || lon < 68.0 || lon > 98.0) {
      lat = 23.0225;
      lon = 72.5714;
    }

    // 1. Try Photon (OpenStreetMap Elasticsearch with fuzzy search & proximity bias)
    try {
      final photonUri = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(cleanQuery)}&lat=$lat&lon=$lon&limit=6&lang=en',
      );
      final res = await http.get(
        photonUri,
        headers: {'User-Agent': 'SlottixPartner/1.0 (contact@slottix.com)'},
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          final List<Map<String, dynamic>> results = [];
          for (final f in features) {
            final p = f['properties'] as Map<String, dynamic>? ?? {};
            final coords = f['geometry']?['coordinates'] as List?;
            if (coords == null || coords.length < 2) continue;
            final lng = (coords[0] as num).toDouble();
            final lat = (coords[1] as num).toDouble();

            final name = p['name'] as String?;
            final street = p['street'] as String?;
            final district = p['district'] as String? ?? p['suburb'] as String? ?? p['locality'] as String?;
            final city = p['city'] as String? ?? p['county'] as String?;
            final state = p['state'] as String?;

            final parts = <String>[];
            for (final item in [name, street, district, city, state]) {
              if (item != null && item.isNotEmpty && !parts.contains(item)) {
                parts.add(item);
              }
            }

            final addr = parts.isNotEmpty ? parts.join(', ') : 'Selected Location';
            results.add({
              'address': addr,
              'location': LatLng(lat, lng),
            });
          }
          if (results.isNotEmpty) return results;
        }
      }
    } catch (e) {
      debugPrint('Photon search error: $e');
    }

    // 2. Try OpenStreetMap Nominatim
    try {
      final nominatimUri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(cleanQuery)}&format=json&addressdetails=1&limit=5&countrycodes=in',
      );
      final res = await http.get(
        nominatimUri,
        headers: {'User-Agent': 'SlottixPartner/1.0 (contact@slottix.com)'},
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List?;
        if (data != null && data.isNotEmpty) {
          final List<Map<String, dynamic>> results = [];
          for (final item in data) {
            final dName = item['display_name'] as String? ?? '';
            final latStr = item['lat'] as String?;
            final lonStr = item['lon'] as String?;
            if (latStr == null || lonStr == null) continue;
            final lat = double.tryParse(latStr);
            final lon = double.tryParse(lonStr);
            if (lat != null && lon != null) {
              results.add({
                'address': dName,
                'location': LatLng(lat, lon),
              });
            }
          }
          if (results.isNotEmpty) return results;
        }
      }
    } catch (e) {
      debugPrint('Nominatim search error: $e');
    }

    // 3. Fallback to native geocoder
    try {
      final locations = await locationFromAddress(cleanQuery);
      if (locations.isNotEmpty) {
        final List<Map<String, dynamic>> results = [];
        for (final loc in locations.take(5)) {
          results.add({
            'address': cleanQuery,
            'location': LatLng(loc.latitude, loc.longitude),
          });
        }
        return results;
      }
    } catch (e) {
      debugPrint('Native geocode fallback error: $e');
    }

    return [];
  }

  void _selectSearchResult(Map<String, dynamic> result) async {
    final itemAddress = result['address'] as String;
    final pos = result['location'] as LatLng;

    _skipNextIdleReverseGeocode = true;
    _searchFocusNode.unfocus();

    setState(() {
      _address = itemAddress;
      _searchController.text = itemAddress;
      _pickedLocation = pos;
      _searchResults.clear();
    });

    final ctrl = await _controller.future;
    ctrl.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: pos, zoom: 17),
    ));
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
          p.name,
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).toSet().join(', ');
        
        setState(() {
          _address = parts.isNotEmpty ? parts : 'Location selected';
          if (!_searchFocusNode.hasFocus) {
            _searchController.text = _address;
          }
        });
        return;
      }

      // Fallback: Nominatim reverse geocode
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json&addressdetails=1',
      );
      final res = await http.get(
        url,
        headers: {'User-Agent': 'SlottixPartner/1.0 (contact@slottix.com)'},
      ).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final dName = data['display_name'] as String?;
        if (dName != null && dName.isNotEmpty && mounted) {
          setState(() {
            _address = dName;
            if (!_searchFocusNode.hasFocus) {
              _searchController.text = _address;
            }
          });
          return;
        }
      }

      if (mounted) {
        setState(() {
          _address = 'Location selected';
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
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
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
              zoom: widget.initialLatitude != 0.0 ? 16 : 14,
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
              if (_skipNextIdleReverseGeocode) {
                _skipNextIdleReverseGeocode = false;
                return;
              }
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
                              textInputAction: TextInputAction.search,
                              onSubmitted: (query) async {
                                if (query.trim().isEmpty) return;
                                setState(() => _isSearching = true);
                                final results = await _searchPlaces(query);
                                if (!mounted) return;
                                setState(() {
                                  _searchResults = results;
                                  _isSearching = false;
                                });
                                if (results.isNotEmpty) {
                                  _selectSearchResult(results.first);
                                }
                              },
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
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 44),
                        child: Material(
                          color: Colors.white,
                          elevation: 4,
                          shadowColor: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 250),
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
                                        onTap: () => _selectSearchResult(result),
                                      );
                                    },
                                  ),
                          ),
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
