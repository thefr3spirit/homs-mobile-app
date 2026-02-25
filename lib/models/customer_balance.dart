class CustomerBalance {
  final int id;
  final int customerId;
  final String customerName;
  final String phone;
  final double balanceAmount;
  final DateTime createdAt;
  final String? createdByName;
  final DateTime updatedAt;
  final String? updatedByName;

  CustomerBalance({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.balanceAmount,
    required this.createdAt,
    this.createdByName,
    required this.updatedAt,
    this.updatedByName,
  });

  factory CustomerBalance.fromJson(Map<String, dynamic> json) {
    return CustomerBalance(
      id: json['id'],
      customerId: json['customer_id'],
      customerName: json['customer_name'],
      phone: json['phone'],
      balanceAmount: (json['balance_amount']).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      createdByName: json['created_by_name'],
      updatedAt: DateTime.parse(json['updated_at']),
      updatedByName: json['updated_by_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'phone': phone,
      'balance_amount': balanceAmount,
      'created_at': createdAt.toIso8601String(),
      'created_by_name': createdByName,
      'updated_at': updatedAt.toIso8601String(),
      'updated_by_name': updatedByName,
    };
  }
}
