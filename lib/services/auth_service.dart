import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/user.dart';

class AuthService {
  static const String baseUrl = 'https://homs-backend-txs8.onrender.com';
  static const Duration timeout = Duration(seconds: 30);

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Storage keys
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';

  /// Login with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['access_token'];

        // Save token
        await _storage.write(key: _tokenKey, value: token);

        // Get and save user info
        final user = await getCurrentUser();

        return {'success': true, 'token': token, 'user': user};
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'Invalid email or password'};
      } else {
        return {
          'success': false,
          'message': 'Login failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Get current user info
  Future<User?> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http
          .get(
            Uri.parse('$baseUrl/auth/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        final user = User.fromJson(userData);

        // Save user data
        await _storage.write(key: _userKey, value: json.encode(userData));

        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get saved user from storage
  Future<User?> getSavedUser() async {
    try {
      final userData = await _storage.read(key: _userKey);
      if (userData != null) {
        return User.fromJson(json.decode(userData));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get saved token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  /// Logout - clear all stored data
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  /// Change password
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not logged in'};
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/change-password'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'old_password': oldPassword,
              'new_password': newPassword,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Password changed successfully'};
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'Old password is incorrect'};
      } else {
        return {'success': false, 'message': 'Failed to change password'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
