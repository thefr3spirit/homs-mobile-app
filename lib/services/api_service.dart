import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/booking.dart';
import '../models/customer.dart';
import '../models/daily_summary.dart';
import '../models/payment.dart';
import '../models/room.dart';
import 'auth_service.dart';
import 'cache_service.dart';

class ApiService {
  // Backend API URL
  static const String baseUrl = 'https://homs-backend-txs8.onrender.com';

  // Timeout duration
  static const Duration timeout = Duration(seconds: 15);

  final AuthService _authService = AuthService();
  final CacheService _cacheService = CacheService();

  /// Get authorization headers with JWT token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get today's summary
  Future<DailySummary?> getTodaySummary({bool forceRefresh = false}) async {
    try {
      // Check cache first
      if (!forceRefresh) {
        final cached = await _cacheService.get(CacheService.todaySummaryKey);
        if (cached != null) {
          return DailySummary.fromJson(cached);
        }
      }

      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/summary/today'), headers: headers)
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Cache the result
        await _cacheService.set(
          CacheService.todaySummaryKey,
          data,
          ttl: const Duration(minutes: 3),
        );
        return DailySummary.fromJson(data);
      } else if (response.statusCode == 404) {
        // No data for today yet
        return null;
      } else {
        throw Exception(
          'Failed to load today\'s summary: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching today\'s summary: $e');
    }
  }

  /// Get latest summary (most recent day with data)
  Future<DailySummary?> getLatestSummary() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/summary/latest'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return DailySummary.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
          'Failed to load latest summary: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching latest summary: $e');
    }
  }

  /// Get summary for a specific date
  Future<DailySummary?> getSummaryByDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await http
          .get(
            Uri.parse('$baseUrl/summary/date/$dateStr'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return DailySummary.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
          'Failed to load summary for $dateStr: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching summary for date: $e');
    }
  }

  /// Get summary history (past 30 days by default)
  Future<List<DailySummary>> getSummaryHistory({
    int limit = 30,
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache first
      if (!forceRefresh) {
        final cached = await _cacheService.get(
          CacheService.historySummariesKey,
        );
        if (cached != null) {
          final List<dynamic> data = cached;
          return data.map((item) => DailySummary.fromJson(item)).toList();
        }
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/summary/history?limit=$limit'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Cache the result
        await _cacheService.set(
          CacheService.historySummariesKey,
          data,
          ttl: const Duration(minutes: 10),
        );
        return data.map((item) => DailySummary.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching history: $e');
    }
  }

  /// Get summaries for a date range
  Future<List<DailySummary>> getSummaryRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startStr = startDate.toIso8601String().split('T')[0];
      final endStr = endDate.toIso8601String().split('T')[0];

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/summary/range?start_date=$startStr&end_date=$endStr',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => DailySummary.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load date range: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching date range: $e');
    }
  }

  /// Check API health
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ========== CUSTOMER ENDPOINTS ==========

  /// Get customers with optional filters
  Future<List<Customer>> getCustomers({
    String? search,
    String? customerType,
    bool? hasPendingBalance,
    int page = 1,
    int pageSize = 20,
    bool forceRefresh = false,
  }) async {
    try {
      // Only cache the default request (no filters, page 1)
      final shouldCache =
          search == null &&
          customerType == null &&
          hasPendingBalance == null &&
          page == 1;

      // Check cache first
      if (!forceRefresh && shouldCache) {
        final cached = await _cacheService.get(CacheService.customersKey);
        if (cached != null) {
          final List<dynamic> data = cached is Map
              ? (cached['customers'] ?? [])
              : cached;
          return data.map((item) => Customer.fromJson(item)).toList();
        }
      }

      final headers = await _getHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (search != null) 'search': search,
        if (customerType != null) 'customer_type': customerType,
        if (hasPendingBalance != null)
          'has_pending_balance': hasPendingBalance.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/customers',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers).timeout(timeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Handle paginated response structure
        final List<dynamic> data = responseData is Map
            ? (responseData['customers'] ?? [])
            : responseData;

        // Cache only the default request
        if (shouldCache) {
          await _cacheService.set(
            CacheService.customersKey,
            data,
            ttl: const Duration(minutes: 10),
          );
        }

        return data.map((item) => Customer.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please login again.');
      } else if (response.statusCode == 404) {
        return []; // No customers found
      }
      throw Exception('Failed to load customers: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching customers: $e');
    }
  }

  /// Get customers with pending balances
  Future<List<Customer>> getCustomersWithPendingBalances() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/customers/pending-balances'),
            headers: headers,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> data = responseData is List
            ? responseData
            : (responseData['customers'] ?? []);
        return data.map((item) => Customer.fromJson(item)).toList();
      } else if (response.statusCode == 404) {
        return []; // No customers with pending balance
      }
      throw Exception('Failed to load customers: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching customers: $e');
    }
  }

  /// Get customers with pending balances (from customers table where pending_balance > 0)
  Future<List<Customer>> getCustomerBalances() async {
    try {
      final headers = await _getHeaders();

      // Debug: Check if we have a token
      final hasAuth = headers.containsKey('Authorization');
      if (!hasAuth) {
        throw Exception('No authentication token found. Please log in again.');
      }

      final response = await http
          .get(Uri.parse('$baseUrl/customer-balances'), headers: headers)
          .timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Customer.fromJson(item)).toList();
      } else if (response.statusCode == 404) {
        return []; // No customers with pending balance
      } else if (response.statusCode == 401) {
        throw Exception(
          'Authentication failed. Please log out and log in again.',
        );
      } else {
        throw Exception(
          'Failed to load balances: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e.toString().contains('Authentication failed') ||
          e.toString().contains('No authentication token')) {
        rethrow;
      }
      throw Exception('Error fetching balances: $e');
    }
  }

  /// Get customer balances summary (count and total)
  Future<Map<String, dynamic>> getCustomerBalancesSummary() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/customer-balances/total'), headers: headers)
          .timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return {'customer_count': 0, 'total_pending': 0.0};
      }
      throw Exception('Failed to load summary: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching summary: $e');
    }
  }

  /// Create customer
  Future<Customer> createCustomer({
    required String fullName,
    required String phone,
    String? email,
    String? address,
    required String customerType,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/customers'),
            headers: headers,
            body: json.encode({
              'full_name': fullName,
              'phone': phone,
              'email': email,
              'address': address,
              'customer_type': customerType,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 201) {
        return Customer.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to create customer: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error creating customer: $e');
    }
  }

  // ========== ROOM ENDPOINTS ==========

  /// Get rooms with optional filters
  Future<List<Room>> getRooms({
    String? status,
    String? roomType,
    int? floor,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        if (status != null) 'status': status,
        if (roomType != null) 'room_type': roomType,
        if (floor != null) 'floor': floor.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/rooms',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers).timeout(timeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Handle paginated response structure
        final List<dynamic> data = responseData is Map
            ? (responseData['rooms'] ?? [])
            : responseData;
        return data.map((item) => Room.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please login again.');
      } else if (response.statusCode == 404) {
        return []; // No rooms found
      }
      throw Exception('Failed to load rooms: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching rooms: $e');
    }
  }

  /// Get available rooms
  Future<List<Room>> getAvailableRooms({
    DateTime? checkIn,
    DateTime? checkOut,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        if (checkIn != null)
          'check_in': checkIn.toIso8601String().split('T')[0],
        if (checkOut != null)
          'check_out': checkOut.toIso8601String().split('T')[0],
      };

      final uri = Uri.parse(
        '$baseUrl/rooms/available',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers).timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Room.fromJson(item)).toList();
      }
      throw Exception('Failed to load rooms: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching available rooms: $e');
    }
  }

  /// Update room status
  Future<Room> updateRoomStatus(int roomId, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .patch(
            Uri.parse('$baseUrl/rooms/$roomId/status'),
            headers: headers,
            body: json.encode({'status': status}),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return Room.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to update room: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error updating room status: $e');
    }
  }

  // ========== BOOKING ENDPOINTS ==========

  /// Get bookings with optional filters
  Future<List<Booking>> getBookings({
    int? customerId,
    int? roomId,
    String? status,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        if (customerId != null) 'customer_id': customerId.toString(),
        if (roomId != null) 'room_id': roomId.toString(),
        if (status != null) 'status': status,
      };

      final uri = Uri.parse(
        '$baseUrl/bookings',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers).timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Booking.fromJson(item)).toList();
      }
      throw Exception('Failed to load bookings: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching bookings: $e');
    }
  }

  /// Get today's check-ins and check-outs
  Future<Map<String, List<Booking>>> getTodaysBookings() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/bookings/today'), headers: headers)
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'check_ins': (data['check_ins'] as List)
              .map((item) => Booking.fromJson(item))
              .toList(),
          'check_outs': (data['check_outs'] as List)
              .map((item) => Booking.fromJson(item))
              .toList(),
        };
      }
      throw Exception(
        'Failed to load today\'s bookings: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Error fetching today\'s bookings: $e');
    }
  }

  /// Create booking
  Future<Booking> createBooking({
    required int customerId,
    required int roomId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int numGuests,
    required double totalAmount,
    String? specialRequests,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/bookings'),
            headers: headers,
            body: json.encode({
              'customer_id': customerId,
              'room_id': roomId,
              'check_in_date': checkInDate.toIso8601String().split('T')[0],
              'check_out_date': checkOutDate.toIso8601String().split('T')[0],
              'num_guests': numGuests,
              'total_amount': totalAmount,
              'special_requests': specialRequests,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 201) {
        return Booking.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to create booking: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error creating booking: $e');
    }
  }

  /// Check in guest
  Future<Booking> checkInGuest(int bookingId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/bookings/$bookingId/checkin'),
            headers: headers,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return Booking.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to check in: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error checking in guest: $e');
    }
  }

  /// Check out guest
  Future<Booking> checkOutGuest(int bookingId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/bookings/$bookingId/checkout'),
            headers: headers,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return Booking.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to check out: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error checking out guest: $e');
    }
  }

  // ========== PAYMENT ENDPOINTS ==========

  /// Get payments with optional filters
  Future<List<Payment>> getPayments({
    int? bookingId,
    int? customerId,
    String? paymentMethod,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        if (bookingId != null) 'booking_id': bookingId.toString(),
        if (customerId != null) 'customer_id': customerId.toString(),
        if (paymentMethod != null) 'payment_method': paymentMethod,
      };

      final uri = Uri.parse(
        '$baseUrl/payments',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers).timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Payment.fromJson(item)).toList();
      }
      throw Exception('Failed to load payments: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching payments: $e');
    }
  }

  /// Get today's payments
  Future<Map<String, dynamic>> getTodaysPayments() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/payments/today'), headers: headers)
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'total': (data['total_amount'] ?? 0.0).toDouble(),
          'count': data['count'] ?? 0,
          'by_method': data['by_method'] ?? {},
          'payments': (data['payments'] as List)
              .map((item) => Payment.fromJson(item))
              .toList(),
        };
      }
      throw Exception(
        'Failed to load today\'s payments: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Error fetching today\'s payments: $e');
    }
  }

  /// Record payment
  Future<Payment> recordPayment({
    required int bookingId,
    required int customerId,
    required double amount,
    required String paymentMethod,
    required String paymentType,
    String? reference,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/payments'),
            headers: headers,
            body: json.encode({
              'booking_id': bookingId,
              'customer_id': customerId,
              'amount': amount,
              'payment_method': paymentMethod,
              'payment_type': paymentType,
              'reference': reference,
              'notes': notes,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 201) {
        return Payment.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to record payment: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error recording payment: $e');
    }
  }
}
