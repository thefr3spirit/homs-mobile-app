class DailySummary {
  final String id;
  final DateTime date;
  final int roomsTotal;
  final int roomsOccupied;
  final int roomsAvailable;
  final double cashCollected;
  final double momoCollected;
  final double chequeCollected;
  final double totalCollected;
  final double expectedBalance;
  final double expensesLogged;
  final DateTime lastUpdated;
  final String? createdByName;
  final String? updatedByName;

  DailySummary({
    required this.id,
    required this.date,
    required this.roomsTotal,
    required this.roomsOccupied,
    required this.roomsAvailable,
    required this.cashCollected,
    required this.momoCollected,
    required this.chequeCollected,
    required this.totalCollected,
    required this.expectedBalance,
    required this.expensesLogged,
    required this.lastUpdated,
    this.createdByName,
    this.updatedByName,
  });

  // Calculate occupancy percentage
  double get occupancyRate =>
      roomsTotal > 0 ? (roomsOccupied / roomsTotal) * 100 : 0;

  // Calculate net revenue (total collected - expenses)
  double get netRevenue => totalCollected - expensesLogged;

  // Create from JSON (API response)
  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      id: json['id'],
      date: DateTime.parse(json['date']),
      roomsTotal: json['rooms_total'],
      roomsOccupied: json['rooms_occupied'],
      roomsAvailable: json['rooms_available'],
      cashCollected: (json['cash_collected'] as num?)?.toDouble() ?? 0.0,
      momoCollected: (json['momo_collected'] as num?)?.toDouble() ?? 0.0,
      chequeCollected: (json['cheque_collected'] as num?)?.toDouble() ?? 0.0,
      totalCollected: (json['total_collected'] as num?)?.toDouble() ?? 0.0,
      expectedBalance: (json['expected_balance'] as num?)?.toDouble() ?? 0.0,
      expensesLogged: (json['expenses_logged'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: DateTime.parse(json['last_updated']),
      createdByName: json['created_by_name'],
      updatedByName: json['updated_by_name'],
    );
  }

  // Convert to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'rooms_total': roomsTotal,
      'rooms_occupied': roomsOccupied,
      'rooms_available': roomsAvailable,
      'cash_collected': cashCollected,
      'momo_collected': momoCollected,
      'cheque_collected': chequeCollected,
      'total_collected': totalCollected,
      'expected_balance': expectedBalance,
      'expenses_logged': expensesLogged,
    };
  }
}
