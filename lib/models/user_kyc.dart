class UserKyc {
  final String id;
  final String status;

  UserKyc({required this.id, required this.status});

  factory UserKyc.fromJson(Map<String, dynamic> json) {
    return UserKyc(
      id: json['_id'] ?? json['id'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}
