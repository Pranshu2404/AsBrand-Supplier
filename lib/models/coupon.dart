class Coupon {
  final String id;
  final String code;
  final double discountAmount;
  final String discountType;

  Coupon({required this.id, required this.code, required this.discountAmount, required this.discountType});

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['_id'] ?? json['id'] ?? '',
      code: json['couponCode'] ?? json['code'] ?? '',
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      discountType: json['discountType'] ?? 'flat',
    );
  }
}
