class Payment {
  final int id;
  final int bookingId;
  final int customerId;
  final double amount;
  final String paymentMethod;
  final String paymentType;
  final String paymentStatus;
  final int receivedBy;
  final String? reference;
  final String? notes;
  final DateTime paymentDate;
  final DateTime createdAt;

  // Related data (optional, populated by API)
  final String? customerName;
  final String? receivedByName;

  Payment({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentType,
    required this.paymentStatus,
    required this.receivedBy,
    this.reference,
    this.notes,
    required this.paymentDate,
    required this.createdAt,
    this.customerName,
    this.receivedByName,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      bookingId: json['booking_id'],
      customerId: json['customer_id'],
      amount: (json['amount']).toDouble(),
      paymentMethod: json['payment_method'],
      paymentType: json['payment_type'],
      paymentStatus: json['payment_status'],
      receivedBy: json['received_by'],
      reference: json['reference'],
      notes: json['notes'],
      paymentDate: DateTime.parse(json['payment_date']),
      createdAt: DateTime.parse(json['created_at']),
      customerName: json['customer_name'],
      receivedByName: json['received_by_name'],
    );
  }

  String get methodDisplay {
    switch (paymentMethod) {
      case 'CASH':
        return 'Cash';
      case 'MOMO':
        return 'Mobile Money';
      case 'CHEQUE':
        return 'Cheque';
      case 'CARD':
        return 'Card';
      case 'BANK_TRANSFER':
        return 'Bank Transfer';
      default:
        return paymentMethod;
    }
  }

  String get typeDisplay {
    switch (paymentType) {
      case 'DEPOSIT':
        return 'Deposit';
      case 'PARTIAL':
        return 'Partial Payment';
      case 'FULL':
        return 'Full Payment';
      case 'REFUND':
        return 'Refund';
      default:
        return paymentType;
    }
  }
}
