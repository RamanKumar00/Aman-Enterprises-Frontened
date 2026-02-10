
class CourierPartner {
  final String id;
  final String name;
  final String displayName;
  final bool isActive;
  final List<String> supportedServices;
  final CourierPerformance? performance;

  CourierPartner({
    required this.id,
    required this.name,
    required this.displayName,
    required this.isActive,
    required this.supportedServices,
    this.performance,
  });

  factory CourierPartner.fromJson(Map<String, dynamic> json) {
    return CourierPartner(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? '',
      isActive: json['isActive'] ?? false,
      supportedServices: (json['supportedServices'] as List?)?.cast<String>() ?? [],
      performance: json['performance'] != null ? CourierPerformance.fromJson(json['performance']) : null,
    );
  }
}

class CourierPerformance {
  final int totalShipments;
  final int successfulDeliveries;
  final int failedDeliveries;
  final int rtoCount;
  final double averageDeliveryDays;
  final double onTimeDeliveryRate;

  CourierPerformance({
    required this.totalShipments,
    required this.successfulDeliveries,
    required this.failedDeliveries,
    required this.rtoCount,
    required this.averageDeliveryDays,
    required this.onTimeDeliveryRate,
  });

  factory CourierPerformance.fromJson(Map<String, dynamic> json) {
    return CourierPerformance(
      totalShipments: json['totalShipments'] ?? 0,
      successfulDeliveries: json['successfulDeliveries'] ?? 0,
      failedDeliveries: json['failedDeliveries'] ?? 0,
      rtoCount: json['rtoCount'] ?? 0,
      averageDeliveryDays: (json['averageDeliveryDays'] ?? 0).toDouble(),
      onTimeDeliveryRate: (json['onTimeDeliveryRate'] ?? 0).toDouble(),
    );
  }
}

class ServiceabilityCheck {
  final bool serviceable;
  final List<ServiceOption> couriers;

  ServiceabilityCheck({
    required this.serviceable,
    required this.couriers,
  });

  factory ServiceabilityCheck.fromJson(Map<String, dynamic> json) {
    return ServiceabilityCheck(
      serviceable: json['serviceable'] ?? false,
      couriers: (json['couriers'] as List?)
              ?.map((e) => ServiceOption.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ServiceOption {
  final String courierName;
  final bool serviceable;
  final String? estimatedDays;
  final List<ServiceType> serviceTypes;

  ServiceOption({
    required this.courierName,
    required this.serviceable,
    this.estimatedDays,
    required this.serviceTypes,
  });

  factory ServiceOption.fromJson(Map<String, dynamic> json) {
    return ServiceOption(
      courierName: json['courierName'] ?? '',
      serviceable: json['serviceable'] ?? false,
      estimatedDays: json['estimatedDays'],
      serviceTypes: (json['serviceTypes'] as List?)
              ?.map((e) => ServiceType.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ServiceType {
  final String name;
  final String type;
  final String? estimatedDays;
  final double? rate;
  final bool codAvailable;

  ServiceType({
    required this.name,
    required this.type,
    this.estimatedDays,
    this.rate,
    required this.codAvailable,
  });

  factory ServiceType.fromJson(Map<String, dynamic> json) {
    return ServiceType(
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      estimatedDays: json['estimatedDays'],
      rate: (json['rate'] ?? 0).toDouble(),
      codAvailable: json['codAvailable'] ?? false,
    );
  }
}

class ShippingRate {
  final String courierName;
  final String courierService; // Added
  final String courierType;
  final double rate;
  final String? estimatedDays;
  final double totalCharge;
  final bool codAvailable;
  final double? score;
  final Map<String, dynamic>? performance;

  ShippingRate({
    required this.courierName,
    required this.courierService,
    required this.courierType,
    required this.rate,
    this.estimatedDays,
    required this.totalCharge,
    required this.codAvailable,
    this.score,
    this.performance,
  });

  factory ShippingRate.fromJson(Map<String, dynamic> json) {
    return ShippingRate(
      courierName: json['courierName'] ?? '',
      courierService: json['courierService'] ?? (json['courierName'] ?? ''),
      courierType: json['courierType'] ?? '',
      rate: (json['rate'] ?? 0).toDouble(),
      estimatedDays: json['estimatedDays'],
      totalCharge: (json['totalCharge'] ?? 0).toDouble(),
      codAvailable: json['codAvailable'] ?? false,
      score: (json['score'] ?? 0).toDouble(),
      performance: json['performance'],
    );
  }
}

class Shipment {
  final String id;
  final String orderId;
  final String courierName;
  final String awbNumber;
  final String trackingNumber;
  final String shipmentStatus;
  final ShipmentDetails shipmentDetails;
  final ShipmentLocation? currentLocation;
  final DateTime? createdAt;

  Shipment({
    required this.id,
    required this.orderId,
    required this.courierName,
    required this.awbNumber,
    required this.trackingNumber,
    required this.shipmentStatus,
    required this.shipmentDetails,
    this.currentLocation,
    this.createdAt,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      id: json['_id'] ?? '',
      orderId: json['orderId'] is String ? json['orderId'] : (json['orderId']?['_id'] ?? ''),
      courierName: json['courierName'] ?? '',
      awbNumber: json['awbNumber'] ?? '',
      trackingNumber: json['trackingNumber'] ?? '',
      shipmentStatus: json['shipmentStatus'] ?? 'Unknown',
      shipmentDetails: ShipmentDetails.fromJson(json['shipmentDetails'] ?? {}),
      currentLocation: json['currentLocation'] != null ? ShipmentLocation.fromJson(json['currentLocation']) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

class ShipmentDetails {
  final double weight;
  final int numberOfPackages;
  final bool isCOD;
  final double codAmount;

  ShipmentDetails({
    required this.weight,
    required this.numberOfPackages,
    required this.isCOD,
    required this.codAmount,
  });

  factory ShipmentDetails.fromJson(Map<String, dynamic> json) {
    return ShipmentDetails(
      weight: (json['weight'] ?? 0).toDouble(),
      numberOfPackages: json['numberOfPackages'] ?? 1,
      isCOD: json['isCOD'] ?? false,
      codAmount: (json['codAmount'] ?? 0).toDouble(),
    );
  }
}

class ShipmentLocation {
  final String city;
  final String state;
  final String country;

  ShipmentLocation({
    required this.city,
    required this.state,
    required this.country,
  });

  factory ShipmentLocation.fromJson(Map<String, dynamic> json) {
    return ShipmentLocation(
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
    );
  }

  @override
  String toString() {
    return [city, state, country].where((element) => element.isNotEmpty).join(', ');
  }
}

class TrackingHistory {
  final String status;
  final String location;
  final String description;
  final DateTime timestamp;

  TrackingHistory({
    required this.status,
    required this.location,
    required this.description,
    required this.timestamp,
  });

  factory TrackingHistory.fromJson(Map<String, dynamic> json) {
    // Handle specific structure from Shiprocket if needed
    // Assuming backend standardizes it
    String loc = '';
    if (json['location'] is Map) {
         loc = (json['location']['city'] ?? '') +  (json['location']['city'] != null ? ', ' : '') + (json['location']['state'] ?? '');
    } else if (json['location'] is String) {
        loc = json['location'];
    }

    return TrackingHistory(
      status: json['status'] ?? '',
      location: loc,
      description: json['description'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    );
  }
}

class TrackingData {
  final String currentStatus;
  final ShipmentLocation? currentLocation;
  final String? estimatedDelivery;
  final List<TrackingHistory> history;

  TrackingData({
    required this.currentStatus,
    this.currentLocation,
    this.estimatedDelivery,
    required this.history,
  });

  factory TrackingData.fromJson(Map<String, dynamic> json) {
    return TrackingData(
      currentStatus: json['currentStatus'] ?? '',
      currentLocation: json['currentLocation'] != null ? ShipmentLocation.fromJson(json['currentLocation']) : null,
      estimatedDelivery: json['estimatedDelivery'],
      history: (json['history'] as List?)?.map((e) => TrackingHistory.fromJson(e)).toList() ?? [],
    );
  }
}
