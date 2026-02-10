import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/services/location_service.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Prediction> _predictions = [];
  Timer? _debounceTimer;
  bool _isLoading = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) async {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (value.isEmpty) {
        setState(() => _predictions = []);
        return;
      }

      setState(() => _isLoading = true);
      
      // Add Bihar to search query to prioritize Bihar results
      String searchQuery = value;
      final lowerValue = value.toLowerCase();
      if (!lowerValue.contains('bihar') && 
          !lowerValue.contains('patna') &&
          !lowerValue.contains('gaya') &&
          !lowerValue.contains('muzaffarpur') &&
          !lowerValue.contains('bhagalpur')) {
        searchQuery = '$value, Bihar';
      }
      
      final predictions = await _locationService.getPlacePredictions(searchQuery);
      if (mounted) {
        setState(() {
          _predictions = predictions;
          _isLoading = false;
        });
      }
    });
  }

  void _selectPlace(Prediction prediction) {
    // OSM Nominatim provides lat/lng directly in the search result
    Navigator.pop(context, prediction);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search area, street name in Bihar...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            hintStyle: AppTextStyles.hintText,
            fillColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: _onSearchChanged,
        ),
        elevation: 1,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Bihar only notice
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primaryGreen.withAlpha(15),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline, size: 16, color: AppColors.primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'We currently deliver only in Bihar',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Search results
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                : _predictions.isEmpty && _searchController.text.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No locations found in Bihar',
                              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try searching for a different area',
                              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _predictions.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final prediction = _predictions[index];
                          // Check if this location is in Bihar
                          final displayName = prediction.displayName.toLowerCase();
                          final isInBihar = displayName.contains('bihar');
                          
                          return ListTile(
                            leading: Icon(
                              Icons.location_on_outlined, 
                              color: isInBihar ? AppColors.primaryGreen : Colors.orange.shade400,
                            ),
                            title: Text(
                              prediction.displayName,
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isInBihar 
                                ? const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20)
                                : Icon(Icons.warning_amber, color: Colors.orange.shade400, size: 20),
                            onTap: () => _selectPlace(prediction),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
