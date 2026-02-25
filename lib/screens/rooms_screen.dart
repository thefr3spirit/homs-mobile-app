import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/room.dart';
import '../services/api_service.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final _apiService = ApiService();

  List<Room> _rooms = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rooms = await _apiService.getRooms(status: _statusFilter);

      if (mounted) {
        setState(() {
          _rooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateRoomStatus(Room room, String newStatus) async {
    try {
      await _apiService.updateRoomStatus(room.id, newStatus);
      _loadRooms();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Room ${room.roomNumber} status updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return Colors.green;
      case 'OCCUPIED':
        return Colors.red;
      case 'CLEANING':
        return Colors.orange;
      case 'MAINTENANCE':
        return Colors.purple;
      case 'RESERVED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'AVAILABLE':
        return Icons.check_circle;
      case 'OCCUPIED':
        return Icons.person;
      case 'CLEANING':
        return Icons.cleaning_services;
      case 'MAINTENANCE':
        return Icons.build;
      case 'RESERVED':
        return Icons.event;
      default:
        return Icons.hotel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'UGX ',
      decimalDigits: 0,
    );

    // Group rooms by status
    final availableRooms = _rooms.where((r) => r.isAvailable).length;
    final occupiedRooms = _rooms.where((r) => r.isOccupied).length;
    final cleaningRooms = _rooms.where((r) => r.isCleaning).length;

    return Scaffold(
      body: Column(
        children: [
          // Status Summary Cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _StatusCard(
                    label: 'Available',
                    count: availableRooms,
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatusCard(
                    label: 'Occupied',
                    count: occupiedRooms,
                    color: Colors.red,
                    icon: Icons.person,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatusCard(
                    label: 'Cleaning',
                    count: cleaningRooms,
                    color: Colors.orange,
                    icon: Icons.cleaning_services,
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _statusFilter == null,
                    onSelected: (_) {
                      setState(() => _statusFilter = null);
                      _loadRooms();
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Available'),
                    selected: _statusFilter == 'AVAILABLE',
                    onSelected: (_) {
                      setState(() => _statusFilter = 'AVAILABLE');
                      _loadRooms();
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Occupied'),
                    selected: _statusFilter == 'OCCUPIED',
                    onSelected: (_) {
                      setState(() => _statusFilter = 'OCCUPIED');
                      _loadRooms();
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Cleaning'),
                    selected: _statusFilter == 'CLEANING',
                    onSelected: (_) {
                      setState(() => _statusFilter = 'CLEANING');
                      _loadRooms();
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Room Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _rooms.isEmpty
                ? const Center(child: Text('No rooms found'))
                : RefreshIndicator(
                    onRefresh: _loadRooms,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _rooms.length,
                      itemBuilder: (context, index) {
                        final room = _rooms[index];
                        final statusColor = _getStatusColor(room.status);

                        return Card(
                          elevation: 2,
                          child: InkWell(
                            onTap: () => _showRoomDetails(room),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          _getStatusIcon(room.status),
                                          color: statusColor,
                                          size: 24,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          room.statusDisplay,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Room ${room.roomNumber}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    room.roomType.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${room.capacity}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        currencyFormat.format(room.dailyRate),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showRoomDetails(Room room) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Room ${room.roomNumber}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.category,
              label: 'Type',
              value: room.roomType.toUpperCase(),
            ),
            _DetailRow(
              icon: Icons.layers,
              label: 'Floor',
              value: 'Floor ${room.floor}',
            ),
            _DetailRow(
              icon: Icons.people,
              label: 'Capacity',
              value: '${room.capacity} guests',
            ),
            _DetailRow(
              icon: Icons.payments,
              label: 'Rate',
              value: NumberFormat.currency(
                symbol: 'UGX ',
                decimalDigits: 0,
              ).format(room.dailyRate),
            ),
            const SizedBox(height: 24),
            const Text(
              'Change Status:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (!room.isAvailable)
                  _StatusChip(
                    label: 'Available',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _updateRoomStatus(room, 'AVAILABLE');
                    },
                  ),
                if (!room.isCleaning)
                  _StatusChip(
                    label: 'Cleaning',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _updateRoomStatus(room, 'CLEANING');
                    },
                  ),
                if (!room.isMaintenance)
                  _StatusChip(
                    label: 'Maintenance',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _updateRoomStatus(room, 'MAINTENANCE');
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatusCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text('$label:', style: TextStyle(color: Colors.grey.shade600)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.2),
      side: BorderSide(color: color),
      onPressed: onTap,
    );
  }
}
