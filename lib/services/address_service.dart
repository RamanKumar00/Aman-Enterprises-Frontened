import 'package:flutter/material.dart';

class AddressService extends ChangeNotifier {
  static final AddressService _instance = AddressService._internal();
  factory AddressService() => _instance;
  AddressService._internal();

  final List<Map<String, dynamic>> _addresses = [];

  List<Map<String, dynamic>> get addresses => _addresses;

  Map<String, dynamic> get currentAddress {
    return _addresses.firstWhere(
      (addr) => addr['isDefault'] == true,
      orElse: () => _addresses.isNotEmpty ? _addresses.first : {},
    );
  }

  void addAddress(Map<String, dynamic> address) {
    if (_addresses.isEmpty) {
      address['isDefault'] = true;
    }
    _addresses.add(address);
    notifyListeners();
  }

  void updateAddress(int index, Map<String, dynamic> address) {
    if (index >= 0 && index < _addresses.length) {
      _addresses[index] = address;
      notifyListeners();
    }
  }

  void deleteAddress(int index) {
    if (index >= 0 && index < _addresses.length) {
      final wasDefault = _addresses[index]['isDefault'];
      _addresses.removeAt(index);
      
      // If deleted default, ensure we have a new default if list not empty
      if (wasDefault && _addresses.isNotEmpty) {
        _addresses[0]['isDefault'] = true;
      }
      
      notifyListeners();
    }
  }

  void setAsDefault(int index) {
    if (index >= 0 && index < _addresses.length) {
      for (int i = 0; i < _addresses.length; i++) {
        _addresses[i]['isDefault'] = (i == index);
      }
      notifyListeners();
    }
  }
}
