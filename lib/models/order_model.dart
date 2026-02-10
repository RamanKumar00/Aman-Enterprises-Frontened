class OrderModel {
  final String id;
  final String trackingId;
  final String status;
  final double totalPrice;
  final DateTime createdAt;
  final List<OrderItem> items;
  final DeliverySlot? deliverySlot;
  final ShippingAddress? shippingAddress;
  final List<OrderTimeline>? timeline;

  OrderModel({
    required this.id,
    required this.trackingId,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    required this.items,
    this.deliverySlot,
    this.shippingAddress,
    this.timeline,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id'] ?? '',
      trackingId: json['trackingId'] ?? '',
      status: json['orderStatus'] ?? 'Placed',
      totalPrice: (json['pricing']?['totalPrice'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      items: (json['orderItems'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      deliverySlot: json['deliverySlot'] != null
          ? DeliverySlot.fromJson(json['deliverySlot'])
          : null,
      shippingAddress: json['shippingAddress'] != null
          ? ShippingAddress.fromJson(json['shippingAddress'])
          : null,
      timeline: (json['timeline'] as List<dynamic>?)
          ?.map((e) => OrderTimeline.fromJson(e))
          .toList(),
    );
  }
}

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String image;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.image,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      image: json['image'] ?? '',
    );
  }
}

class DeliverySlot {
  final DateTime date;
  final String timeSlot;

  DeliverySlot({required this.date, required this.timeSlot});

  factory DeliverySlot.fromJson(Map<String, dynamic> json) {
    return DeliverySlot(
      date: DateTime.parse(json['date']),
      timeSlot: json['timeSlot'] ?? '',
    );
  }
}

class ShippingAddress {
  final String details;
  final String city;
  final String state;
  final String pincode;

  ShippingAddress({
    required this.details,
    required this.city,
    required this.state,
    required this.pincode,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      details: json['details'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
    );
  }
}

class OrderTimeline {
  final String status;
  final DateTime timestamp;

  OrderTimeline({required this.status, required this.timestamp});

  factory OrderTimeline.fromJson(Map<String, dynamic> json) {
    return OrderTimeline(
      status: json['status'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
