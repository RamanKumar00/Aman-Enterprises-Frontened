import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Open Source Map
import 'package:latlong2/latlong.dart'; // Metrics for map
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/services/location_service.dart';
import 'package:aman_enterprises/services/user_service.dart';
import 'package:aman_enterprises/screens/main_navigation_screen.dart';
import 'package:aman_enterprises/screens/location/location_search_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  
  // Default position (Patna, Bihar)
  static final LatLng _defaultPosition = LatLng(25.5941, 85.1376);

  LatLng _currentCenter = _defaultPosition;
  bool _isLoading = true;
  bool _isMoving = false;
  Placemark? _currentAddress;
  String _formattedAddress = "Fetching location...";
  Timer? _debounceTimer;
  
  // Nearby places suggestions
  List<NearbyPlace> _nearbyPlaces = [];
  bool _isLoadingNearbyPlaces = false;
  
  // Bihar validation
  bool _isInBihar = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }
  
  // --- New state variables for detailed address ---
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  bool _isDeliveringToSomeoneElse = false;

  /// Show alert that delivery is not available outside Bihar
  void _showNotDeliverableAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.location_off_rounded,
            size: 48,
            color: Colors.red.shade400,
          ),
        ),
        title: const Text(
          'Delivery Not Available',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sorry! We currently deliver only in Bihar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please select an address within Bihar to continue.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Move map back to Patna (Bihar capital)
              final biharCenter = LatLng(25.5941, 85.1376);
              _updateCameraPosition(biharCenter);
              _getAddress(biharCenter);
            },
            child: const Text('Go to Bihar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child: const Text('Try Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  /// Fetch nearby places for suggestions
  Future<void> _fetchNearbyPlaces(double lat, double lng) async {
    if (_isLoadingNearbyPlaces) return;
    
    setState(() => _isLoadingNearbyPlaces = true);
    
    try {
      final places = await _locationService.getNearbyPlaces(lat, lng);
      if (mounted) {
        setState(() {
          _nearbyPlaces = places;
          _isLoadingNearbyPlaces = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingNearbyPlaces = false);
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _houseNoController.dispose();
    _landmarkController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoading = true);
    
    Position? position = await _locationService.getCurrentPosition();
    
    if (position != null) {
      final latLng = LatLng(position.latitude, position.longitude);
      _updateCameraPosition(latLng);
      _getAddress(latLng);
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _formattedAddress = "Location permission denied or unavailable.";
        });
      }
    }
  }

  void _updateCameraPosition(LatLng latLng) {
    _mapController.move(latLng, 17.0);
    setState(() {
      _currentCenter = latLng;
    });
  }

  Future<void> _getAddress(LatLng latLng) async {
    // Only show loading if we really want to block UI, simpler to just background it 
    // but here we are in a 'moving' state usually
    
    try {
      Placemark? place = await _locationService.getAddressFromCoordinates(
        latLng.latitude, 
        latLng.longitude
      );
      
      if (place != null && mounted) {
        // Check if location is in Bihar
        final stateName = place.administrativeArea;
        final inBihar = LocationService.isInBihar(stateName);
        
        setState(() {
          _currentAddress = place;
          _isInBihar = inBihar;
          // Construct a friendly address string
          _formattedAddress = [
            place.name,
            place.subLocality,
            place.locality,
            place.postalCode
          ].where((e) => e != null && e.isNotEmpty).join(', ');
        });
        
        // Show alert if outside Bihar
        if (!inBihar) {
          _showNotDeliverableAlert();
        } else {
          // Fetch nearby places for suggestions (only for Bihar locations)
          _fetchNearbyPlaces(latLng.latitude, latLng.longitude);
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isMoving = false;
        });
      }
    }
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    // flutter_map 6+ uses MapCamera
    _currentCenter = camera.center;
    if (!_isMoving) {
      setState(() => _isMoving = true);
    }
    
    // Debounce address fetch
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _getAddress(_currentCenter);
    });
    }

  Future<void> _openSearch() async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const LocationSearchScreen())
    );

    if (result != null && result is Prediction) { 
       final latLng = LatLng(result.lat, result.lng);
       _updateCameraPosition(latLng);
       _getAddress(latLng);
    }
  }

  void _showAddressDetailsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: StatefulBuilder(
            builder: (context, setSheetState) => ListView(
              controller: scrollController,
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 40, 
                    height: 4, 
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))
                  ),
                ),
                const SizedBox(height: 20),
                
                // Header
                Text("Enter Complete Address", style: AppTextStyles.headingSmall),
                const SizedBox(height: 16),
                
                // Detected Location (Read Only)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryGreen.withAlpha(50)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primaryGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_formattedAddress, style: AppTextStyles.bodySmall),
                            if (_currentAddress?.administrativeArea != null)
                              Text(
                                '${_currentAddress!.administrativeArea}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Nearby Places Suggestions
                if (_nearbyPlaces.isNotEmpty || _isLoadingNearbyPlaces) ...[
                  Row(
                    children: [
                      const Icon(Icons.near_me, size: 18, color: AppColors.primaryGreen),
                      const SizedBox(width: 8),
                      Text(
                        "Nearby Places (tap to add as landmark)",
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingNearbyPlaces)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _nearbyPlaces.length,
                        separatorBuilder: (context, i) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final place = _nearbyPlaces[index];
                          return GestureDetector(
                            onTap: () {
                              _landmarkController.text = place.name;
                              setSheetState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added "${place.name}" as landmark'),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: AppColors.primaryGreen,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withAlpha(15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primaryGreen.withAlpha(40),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    place.type.split(' ').first, // Emoji
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    place.name,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                ],

                // House No / Flat
                TextField(
                  controller: _houseNoController,
                  decoration: InputDecoration(
                    labelText: 'House No. / Flat / Building *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.home_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Landmark
                TextField(
                  controller: _landmarkController,
                  decoration: InputDecoration(
                    labelText: 'Landmark (Optional)',
                    hintText: 'e.g., Near Hospital, Opposite School',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.flag_outlined),
                    suffixIcon: _landmarkController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _landmarkController.clear();
                              setSheetState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: 24),

                // Deliver for someone else toggle
                SwitchListTile(
                  value: _isDeliveringToSomeoneElse,
                  onChanged: (val) {
                    setSheetState(() => _isDeliveringToSomeoneElse = val);
                    setState(() => _isDeliveringToSomeoneElse = val);
                  },
                  activeThumbColor: AppColors.primaryGreen,
                  title: Text("Deliver for someone else?", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: const Text("Add receiver's details"),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_isDeliveringToSomeoneElse) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Receiver's Name",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Receiver's Phone Number",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Save Button
                ElevatedButton(
                  onPressed: _saveAndConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Save Address", style: AppTextStyles.buttonText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveAndConfirm() async {
    if (_houseNoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter House No / Flat')));
      return;
    }
    if (_isDeliveringToSomeoneElse && (_nameController.text.isEmpty || _phoneController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter receiver details')));
      return;
    }

    Navigator.pop(context); // Close sheet
    setState(() => _isLoading = true);

    // Save address to User Service
    final userService = UserService();
    final currentData = userService.currentUser ?? {};
    final newAddressData = Map<String, dynamic>.from(currentData);
    
    // Construct address string
    final street = _currentAddress!.street ?? '';
    final subLocality = _currentAddress!.subLocality ?? '';
    final houseNo = _houseNoController.text.trim();
    final landmark = _landmarkController.text.trim();
    
    // Combine for a displayable address string
    String addressLine = "$houseNo, $street, $subLocality";
    if (landmark.isNotEmpty) addressLine += " (Near $landmark)";

    newAddressData['address'] = addressLine;
    newAddressData['city'] = _currentAddress!.locality ?? '';
    newAddressData['state'] = _currentAddress!.administrativeArea ?? '';
    newAddressData['pincode'] = _currentAddress!.postalCode ?? '';
    newAddressData['latitude'] = _currentCenter.latitude;
    newAddressData['longitude'] = _currentCenter.longitude;
    
    // Save extra details
    newAddressData['houseNo'] = houseNo;
    newAddressData['landmark'] = landmark;
    
    if (_isDeliveringToSomeoneElse) {
      newAddressData['receiverName'] = _nameController.text.trim();
      newAddressData['receiverPhone'] = _phoneController.text.trim();
    } else {
      // Clear if not
      newAddressData.remove('receiverName');
      newAddressData.remove('receiverPhone');
    }

    await userService.updateUser(newAddressData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Address Saved: $addressLine'))
      );
      
      // Navigate to Home
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        (route) => false,
      );
    }
  }

  // --- Main Build ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultPosition,
              initialZoom: 15.0,
              onPositionChanged: _onMapPositionChanged,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
               TileLayer(
                 urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                 userAgentPackageName: 'com.aman_enterprises.app',
               ),
            ],
          ),
          
          // Center Pin
          Center(
             child: Padding(
               padding: const EdgeInsets.only(bottom: 35),
               child: Icon(
                 Icons.location_on,
                 size: 50,
                 color: AppColors.primaryGreenDark,
                 shadows: [
                   BoxShadow(
                     color: Colors.black.withValues(alpha: 0.3),
                     blurRadius: 10,
                     offset: const Offset(0, 5)
                   )
                 ],
               ),
             ),
          ),
          
          // Search Bar
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: _openSearch,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                  ]
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.primaryGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Search area, street...",
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // My Location Button
          Positioned(
            bottom: 230,
            right: 16,
            child: FloatingActionButton(
              onPressed: _determinePosition,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: AppColors.primaryGreen),
            ),
          ),

          // Bottom Sheet Preview
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                       Icon(
                         Icons.location_on_outlined, 
                         color: _isInBihar ? AppColors.textMedium : Colors.red.shade400, 
                         size: 28
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text("Select Delivery Location", style: AppTextStyles.labelText),
                             if (!_isInBihar && !_isLoading && !_isMoving)
                               Container(
                                 margin: const EdgeInsets.only(top: 4),
                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                 decoration: BoxDecoration(
                                   color: Colors.red.shade50,
                                   borderRadius: BorderRadius.circular(4),
                                 ),
                                 child: Text(
                                   '⚠️ Outside Bihar - Delivery not available',
                                   style: TextStyle(
                                     fontSize: 11,
                                     color: Colors.red.shade700,
                                     fontWeight: FontWeight.w500,
                                   ),
                                 ),
                               ),
                           ],
                         ),
                       ),
                       if (_isLoading)
                         const SizedBox(
                           width: 20, 
                           height: 20, 
                           child: CircularProgressIndicator(strokeWidth: 2)
                         )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formattedAddress,
                    style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_currentAddress?.administrativeArea != null)
                    Text(
                      _currentAddress!.administrativeArea!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _isInBihar ? AppColors.primaryGreen : Colors.red.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: (_isLoading || _isMoving || _currentAddress == null) 
                        ? null 
                        : (_isInBihar ? _showAddressDetailsSheet : _showNotDeliverableAlert),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isInBihar ? AppColors.primaryGreen : Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _isInBihar ? "Confirm & Enter Details" : "Location Not Serviceable",
                      style: AppTextStyles.buttonText,
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
