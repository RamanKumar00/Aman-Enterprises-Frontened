import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/services/address_service.dart';
import 'package:aman_enterprises/services/location_service.dart';
import 'package:aman_enterprises/services/user_service.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  final AddressService _addressService = AddressService();

  @override
  void initState() {
    super.initState();
    _addressService.addListener(_update);
  }

  @override
  void dispose() {
    _addressService.removeListener(_update);
    super.dispose();
  }

  void _update() => setState(() {});

  void _setAsDefault(int index) {
    _addressService.setAsDefault(index);
  }

  void _deleteAddress(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        title: Text('Delete Address?', style: AppTextStyles.headingSmall),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMedium)),
          ),
          ElevatedButton(
            onPressed: () {
              _addressService.deleteAddress(index);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddEditAddress({Map<String, dynamic>? address, int? index}) {
    final isEditing = address != null;
    final nameController = TextEditingController(text: address?['name'] ?? UserService().name);
    final addressController = TextEditingController(text: address?['address'] ?? '');
    final cityController = TextEditingController(text: address?['city'] ?? UserService().city);
    final pincodeController = TextEditingController(text: address?['pincode'] ?? UserService().pincode);
    final phoneController = TextEditingController(text: address?['phone'] ?? UserService().phone);
    String selectedType = address?['type'] ?? 'Home';
    bool isLocating = false;

    Future<void> useCurrentLocation(StateSetter setModalState) async {
       setModalState(() => isLocating = true);
       try {
         final locationService = LocationService();
         final position = await locationService.getCurrentPosition();
         if (position != null) {
           final placemark = await locationService.getAddressFromCoordinates(position.latitude, position.longitude);
           if (placemark != null) {
              addressController.text = "${placemark.street}, ${placemark.subLocality}";
              cityController.text = placemark.locality ?? '';
              pincodeController.text = placemark.postalCode ?? '';
              // Update state to refresh UI
              setModalState(() {});
           }
         }
       } catch (e) {
         debugPrint("Error getting location: $e");
       } finally {
         setModalState(() => isLocating = false);
       }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Address' : 'Add New Address',
                        style: AppTextStyles.headingSmall,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Address Type
                        Text('Address Type', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Row(
                          children: ['Home', 'Office', 'Other'].map((type) {
                            final isSelected = selectedType == type;
                            return GestureDetector(
                              onTap: () => setModalState(() => selectedType = type),
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryGreen : Colors.white,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primaryGreen : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  type,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isSelected ? Colors.white : AppColors.textMedium,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Full Name
                        _buildTextField('Full Name', nameController, Icons.person_outline_rounded),
                        const SizedBox(height: 16),

                        // Address
                        _buildTextField(
                          'Street Address', 
                          addressController, 
                          Icons.location_on_outlined,
                          suffixIcon: isLocating ? Icons.hourglass_top : Icons.my_location,
                          onSuffixTap: () => useCurrentLocation(setModalState),
                        ),
                        if (isLocating)
                          const Padding(
                            padding: EdgeInsets.only(top: 4, left: 4),
                            child: Text("Fetching location...", style: TextStyle(fontSize: 12, color: AppColors.primaryGreen)),
                          ),
                        const SizedBox(height: 16),

                        // City & Pincode
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField('City', cityController, Icons.location_city_rounded),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField('Pincode', pincodeController, Icons.pin_drop_outlined, isNumber: true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        _buildTextField('Phone Number', phoneController, Icons.phone_outlined, isNumber: true),
                        const SizedBox(height: 32),

                        // Save Button
                        Container(
                          width: double.infinity,
                          height: AppDimensions.buttonHeight,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryGreenLight, AppColors.primaryGreen],
                            ),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              final newAddress = {
                                'id': isEditing ? address['id'] : DateTime.now().toString(),
                                'type': selectedType,
                                'name': nameController.text,
                                'address': addressController.text,
                                'city': cityController.text,
                                'pincode': pincodeController.text,
                                'phone': phoneController.text,
                                'isDefault': isEditing ? address['isDefault'] : _addressService.addresses.isEmpty,
                                'icon': selectedType == 'Home'
                                    ? Icons.home_rounded
                                    : selectedType == 'Office'
                                        ? Icons.business_rounded
                                        : Icons.location_on_rounded,
                              };

                              if (isEditing) {
                                _addressService.updateAddress(index!, newAddress);
                              } else {
                                _addressService.addAddress(newAddress);
                              }
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                              ),
                            ),
                            child: Text(
                              isEditing ? 'Update Address' : 'Save Address',
                              style: AppTextStyles.buttonText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, VoidCallback? onSuffixTap, IconData? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMedium)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundCream,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: AppTextStyles.inputText,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.textLight),
              suffixIcon: suffixIcon != null ? IconButton(
                  icon: Icon(suffixIcon, color: AppColors.primaryGreen),
                  onPressed: onSuffixTap,
              ) : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access addresses from service
    final addresses = _addressService.addresses;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text('My Addresses', style: AppTextStyles.headingSmall),
      ),
      body: addresses.isEmpty ? _buildEmptyState() : _buildAddressList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditAddress(),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Address'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off_rounded,
              size: 64,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 24),
          Text('No addresses saved', style: AppTextStyles.headingSmall),
          const SizedBox(height: 8),
          Text(
            'Add a delivery address to continue',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList() {
    final addresses = _addressService.addresses;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        final address = addresses[index];
        final isDefault = address['isDefault'] as bool;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
            border: Border.all(
              color: isDefault ? AppColors.primaryGreen : AppColors.border,
              width: isDefault ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDefault
                            ? AppColors.primaryGreen.withAlpha(26)
                            : AppColors.backgroundCream,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: Icon(
                        address['icon'] as IconData,
                        color: isDefault ? AppColors.primaryGreen : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                address['type'] as String,
                                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (isDefault)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Default',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            address['name'] as String,
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${address['address']}, ${address['city']} - ${address['pincode']}',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMedium),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            address['phone'] as String,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    if (!isDefault)
                      TextButton.icon(
                        onPressed: () => _setAsDefault(index),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: const Text('Set Default'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.primaryGreen),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: AppColors.textMedium,
                      onPressed: () => _showAddEditAddress(address: address, index: index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      color: Colors.red,
                      onPressed: () => _deleteAddress(index),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
