class Booking {
  final int id;
  final int customerId;
  final int roomId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int numGuests;
  final double totalAmount;
  final double amountPaid;
  final String status;
  final String? specialRequests;
  final int createdBy;
  final int? checkedInBy;
  final int? checkedOutBy;
  final DateTime? actualCheckIn;
  final DateTime? actualCheckOut;
  final DateTime createdAt;

  // Related data (optional, populated by API)
  final String? customerName;
  final String? roomNumber;
  final String? createdByName;
  final String? checkedInByName;
  final String? checkedOutByName;

  Booking({
    required this.id,
    required this.customerId,
    required this.roomId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numGuests,
    required this.totalAmount,
    required this.amountPaid,
    required this.status,
    this.specialRequests,
    required this.createdBy,
    this.checkedInBy,
    this.checkedOutBy,
    this.actualCheckIn,
    this.actualCheckOut,
    required this.createdAt,
    this.customerName,
    this.roomNumber,
    this.createdByName,
    this.checkedInByName,
    this.checkedOutByName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      customerId: json['customer_id'],
      roomId: json['room_id'],
      checkInDate: DateTime.parse(json['check_in_date']),
      checkOutDate: DateTime.parse(json['check_out_date']),
      numGuests: json['num_guests'],
      totalAmount: (json['total_amount']).toDouble(),
      amountPaid: (json['amount_paid'] ?? 0.0).toDouble(),
      status: json['status'],
      specialRequests: json['special_requests'],
      createdBy: json['created_by'],
      checkedInBy: json['checked_in_by'],
      checkedOutBy: json['checked_out_by'],
      actualCheckIn: json['actual_check_in'] != null
          ? DateTime.parse(json['actual_check_in'])
          : null,
      actualCheckOut: json['actual_check_out'] != null
          ? DateTime.parse(json['actual_check_out'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      customerName: json['customer_name'],
      roomNumber: json['room_number'],
      createdByName: json['created_by_name'],
      checkedInByName: json['checked_in_by_name'],
      checkedOutByName: json['checked_out_by_name'],
    );
  }

  double get balanceDue => totalAmount - amountPaid;
  bool get hasBalance => balanceDue > 0;
  bool get isFullyPaid => balanceDue <= 0;

  bool get isReserved => status == 'RESERVED';
  bool get isCheckedIn => status == 'CHECKED_IN';
  bool get isCheckedOut => status == 'CHECKED_OUT';
  bool get isCancelled => status == 'CANCELLED';

  String get statusDisplay {
    switch (status) {
      case 'RESERVED':
        return 'Reserved';
      case 'CHECKED_IN':
        return 'Checked In';
      case 'CHECKED_OUT':
        return 'Checked Out';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  int get durationDays {
    return checkOutDate.difference(checkInDate).inDays;
  }
}
