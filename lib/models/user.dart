class SupplierProfile {
  final String? storeName;
  final String? gstin;
  final PickupAddress? pickupAddress;
  final BankDetails? bankDetails;
  final bool isApproved;
  final DateTime? supplierSince;

  SupplierProfile({
    this.storeName,
    this.gstin,
    this.pickupAddress,
    this.bankDetails,
    this.isApproved = false,
    this.supplierSince,
  });

  factory SupplierProfile.fromJson(Map<String, dynamic> json) {
    return SupplierProfile(
      storeName: json['storeName'],
      gstin: json['gstin'],
      pickupAddress: json['pickupAddress'] != null
          ? PickupAddress.fromJson(json['pickupAddress'])
          : null,
      bankDetails: json['bankDetails'] != null
          ? BankDetails.fromJson(json['bankDetails'])
          : null,
      isApproved: json['isApproved'] ?? false,
      supplierSince: json['supplierSince'] != null
          ? DateTime.tryParse(json['supplierSince'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeName': storeName,
      'gstin': gstin,
      if (pickupAddress != null) 'pickupAddress': pickupAddress!.toJson(),
      if (bankDetails != null) 'bankDetails': bankDetails!.toJson(),
    };
  }
}

class PickupAddress {
  final String address;
  final String city;
  final String state;
  final String pincode;

  PickupAddress({
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
  });

  factory PickupAddress.fromJson(Map<String, dynamic> json) {
    return PickupAddress(
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
      };
}

class BankDetails {
  final String accountName;
  final String accountNumber;
  final String ifscCode;
  final String bankName;

  BankDetails({
    required this.accountName,
    required this.accountNumber,
    required this.ifscCode,
    required this.bankName,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      accountName: json['accountName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      ifscCode: json['ifscCode'] ?? '',
      bankName: json['bankName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'accountName': accountName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'bankName': bankName,
      };
}

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? token;
  final String? profileImage; // Local path or URL
  final bool isVerified;
  final SupplierProfile? supplierProfile;
  final String? referralCode;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.token,
    this.profileImage,
    this.isVerified = false,
    this.supplierProfile,
    this.referralCode,
  });

  bool get isSupplier => role == 'supplier';
  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      token: json['token'],
      profileImage: json['profileImage'],
      isVerified: json['isVerified'] ?? false,
      supplierProfile: json['supplierProfile'] != null
          ? SupplierProfile.fromJson(json['supplierProfile'])
          : null,
      referralCode: json['referralCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'profileImage': profileImage,
      'isVerified': isVerified,
      'supplierProfile': supplierProfile?.toJson(),
      'referralCode': referralCode,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? token,
    String? profileImage,
    bool? isVerified,
    SupplierProfile? supplierProfile,
    String? referralCode,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      token: token ?? this.token,
      profileImage: profileImage ?? this.profileImage,
      isVerified: isVerified ?? this.isVerified,
      supplierProfile: supplierProfile ?? this.supplierProfile,
      referralCode: referralCode ?? this.referralCode,
    );
  }
}
