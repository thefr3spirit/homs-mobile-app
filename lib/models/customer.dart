class Customer {
  final String id; // Changed from int to String (UUID)
  final String fullName;
  final String phone;
  final String? email;
  final String? address;
  final String customerType;
  final double pendingBalance;
  final double totalSpent;
  final int totalVisits;
  final DateTime createdAt;
  final String? createdByName;
  final String? updatedByName;

  Customer({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.address,
    required this.customerType,
    required this.pendingBalance,
    required this.totalSpent,
    required this.totalVisits,
    required this.createdAt,
    this.createdByName,
    this.updatedByName,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      fullName: json['full_name'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      customerType: json['customer_type'],
      pendingBalance: (json['pending_balance'] ?? 0.0).toDouble(),
      totalSpent: (json['total_spent'] ?? 0.0).toDouble(),
      totalVisits: json['total_visits'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      createdByName: json['created_by_name'],
      updatedByName: json['updated_by_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'address': address,
      'customer_type': customerType,
      'pending_balance': pendingBalance,
      'total_spent': totalSpent,
      'total_visits': totalVisits,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get hasBalance => pendingBalance > 0;
  bool get isVip => customerType == 'VIP';
  bool get isCorporate => customerType == 'CORPORATE';
}
