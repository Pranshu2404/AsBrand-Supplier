/// Order model matching backend Order schema
class Order {
  final String id;
  final String? userId;
  final DateTime orderDate;
  final String orderStatus;
  final List<OrderItem> items;
  final double totalPrice;
  final ShippingAddress? shippingAddress;
  final String? paymentMethod;
  final String? couponCode;
  final OrderTotal? orderTotal;
  final String? trackingUrl;

  // Delivery fields
  final String? paymentStatus;
  final double? shippingCharge;
  final String? deliveryStatus;
  final String? deliveryPartner;
  final String? shipmentId;
  final String? awbCode;
  final String? courierName;
  final String? estimatedDeliveryDate;
  final int? estimatedDeliveryMinutes;
  final String? assignedDriver;

  // Zomato-style lifecycle timestamps
  final DateTime? supplierAcceptedAt;
  final DateTime? prepStartedAt;
  final DateTime? readyAt;
  final DateTime? pickedUpAt;
  final int estimatedPrepMinutes;

  // Customer info (populated from userID)
  final String? customerName;
  final String? customerPhone;

  Order({
    required this.id,
    this.userId,
    required this.orderDate,
    required this.orderStatus,
    required this.items,
    required this.totalPrice,
    this.shippingAddress,
    this.paymentMethod,
    this.couponCode,
    this.orderTotal,
    this.trackingUrl,
    this.paymentStatus,
    this.shippingCharge,
    this.deliveryStatus,
    this.deliveryPartner,
    this.shipmentId,
    this.awbCode,
    this.courierName,
    this.estimatedDeliveryDate,
    this.estimatedDeliveryMinutes,
    this.assignedDriver,
    this.supplierAcceptedAt,
    this.prepStartedAt,
    this.readyAt,
    this.pickedUpAt,
    this.estimatedPrepMinutes = 15,
    this.customerName,
    this.customerPhone,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userID'] is Map ? json['userID']['_id'] : json['userID'],
      orderDate: json['orderDate'] != null ? DateTime.parse(json['orderDate']) : DateTime.now(),
      orderStatus: json['orderStatus'] ?? 'pending',
      items: (json['items'] as List?)?.map((e) => OrderItem.fromJson(e)).toList() ?? [],
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      shippingAddress: json['shippingAddress'] != null ? ShippingAddress.fromJson(json['shippingAddress']) : null,
      paymentMethod: json['paymentMethod'],
      couponCode: json['couponCode']?.toString(),
      orderTotal: json['orderTotal'] != null ? OrderTotal.fromJson(json['orderTotal']) : null,
      trackingUrl: json['trackingUrl'],
      // Delivery fields
      paymentStatus: json['paymentStatus'],
      shippingCharge: (json['shippingCharge'] ?? 0).toDouble(),
      deliveryStatus: json['deliveryStatus'],
      deliveryPartner: json['deliveryPartner'],
      shipmentId: json['shipmentId'],
      awbCode: json['awbCode'],
      courierName: json['courierName'],
      estimatedDeliveryDate: json['estimatedDeliveryDate'],
      estimatedDeliveryMinutes: json['estimatedDeliveryMinutes'] != null ? (json['estimatedDeliveryMinutes'] as num).toInt() : null,
      assignedDriver: json['assignedDriver'] is Map ? json['assignedDriver']['_id'] : json['assignedDriver'],
      supplierAcceptedAt: json['supplierAcceptedAt'] != null ? DateTime.tryParse(json['supplierAcceptedAt']) : null,
      prepStartedAt: json['prepStartedAt'] != null ? DateTime.tryParse(json['prepStartedAt']) : null,
      readyAt: json['readyAt'] != null ? DateTime.tryParse(json['readyAt']) : null,
      pickedUpAt: json['pickedUpAt'] != null ? DateTime.tryParse(json['pickedUpAt']) : null,
      estimatedPrepMinutes: (json['estimatedPrepMinutes'] ?? 15) as int,
      customerName: json['userID'] is Map ? json['userID']['name'] : null,
      customerPhone: json['userID'] is Map ? json['userID']['phone'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
      'totalPrice': totalPrice,
      'shippingAddress': shippingAddress?.toJson(),
      'paymentMethod': paymentMethod,
      'couponCode': couponCode,
      'orderTotal': orderTotal?.toJson(),
    };
  }
}

class OrderItem {
  final String? productId;
  final String productName;
  final String productImage;
  final int quantity;
  final double price;
  final String? variant;

  OrderItem({
    this.productId,
    required this.productName,
    this.productImage = '',
    required this.quantity,
    required this.price,
    this.variant,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    String image = '';
    if (json['productID'] is Map) {
      final prod = json['productID'] as Map<String, dynamic>;
      image = prod['primaryImage'] ?? '';
      if (image.isEmpty && prod['images'] is List && (prod['images'] as List).isNotEmpty) {
        final firstImg = (prod['images'] as List).first;
        if (firstImg is Map) {
          image = firstImg['url'] ?? '';
        } else if (firstImg is String) {
          image = firstImg;
        }
      }
    }

    return OrderItem(
      productId: json['productID'] is Map ? json['productID']['_id'] : json['productID'],
      productName: json['productName'] ?? '',
      productImage: image,
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      variant: json['variant'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productID': productId,
      'productName': productName,
      'productImage': productImage,
      'quantity': quantity,
      'price': price,
      'variant': variant,
    };
  }
}

class ShippingAddress {
  final String phone;
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final double? latitude;
  final double? longitude;

  ShippingAddress({
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    this.country = 'India',
    this.latitude,
    this.longitude,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      phone: json['phone'] ?? '',
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postalCode'] ?? '',
      country: json['country'] ?? 'India',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'street': street,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
    };
  }
}

class OrderTotal {
  final double subtotal;
  final double discount;
  final double total;

  OrderTotal({
    required this.subtotal,
    this.discount = 0,
    required this.total,
  });

  factory OrderTotal.fromJson(Map<String, dynamic> json) {
    return OrderTotal(
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
    };
  }
}
