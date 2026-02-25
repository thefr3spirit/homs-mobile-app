class Room {
  final int id;
  final String roomNumber;
  final String roomType;
  final int floor;
  final int capacity;
  final double dailyRate;
  final String status;
  final String? description;
  final DateTime createdAt;

  Room({
    required this.id,
    required this.roomNumber,
    required this.roomType,
    required this.floor,
    required this.capacity,
    required this.dailyRate,
    required this.status,
    this.description,
    required this.createdAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      roomNumber: json['room_number'],
      roomType: json['room_type'],
      floor: json['floor'],
      capacity: json['capacity'],
      dailyRate: (json['daily_rate']).toDouble(),
      status: json['status'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_number': roomNumber,
      'room_type': roomType,
      'floor': floor,
      'capacity': capacity,
      'daily_rate': dailyRate,
      'status': status,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isAvailable => status == 'AVAILABLE';
  bool get isOccupied => status == 'OCCUPIED';
  bool get isCleaning => status == 'CLEANING';
  bool get isMaintenance => status == 'MAINTENANCE';

  String get statusDisplay {
    switch (status) {
      case 'AVAILABLE':
        return 'Available';
      case 'OCCUPIED':
        return 'Occupied';
      case 'CLEANING':
        return 'Cleaning';
      case 'MAINTENANCE':
        return 'Maintenance';
      case 'RESERVED':
        return 'Reserved';
      default:
        return status;
    }
  }
}
