class EmiPlan {
  final String id;
  final String name;
  final int months;
  final double interestRate;

  EmiPlan({required this.id, required this.name, required this.months, required this.interestRate});

  factory EmiPlan.fromJson(Map<String, dynamic> json) {
    return EmiPlan(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      months: json['months'] ?? 0,
      interestRate: (json['interestRate'] ?? 0).toDouble(),
    );
  }
}
