import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:fitgroup/config/app_config.dart';
import 'package:fitgroup/services/session_service.dart';

class AuthService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  static const Duration _requestTimeout = Duration(seconds: 12);

  Future<bool> register(
    String fullName,
    String email,
    String password,
    DateTime birthDate,
    String gender,
  ) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final normalizedEmail = email.trim().toLowerCase();

    final formattedBirthDate = [
      birthDate.year.toString().padLeft(4, '0'),
      birthDate.month.toString().padLeft(2, '0'),
      birthDate.day.toString().padLeft(2, '0'),
    ].join('-');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': normalizedEmail,
          'password': password,
          'birthDate': formattedBirthDate,
          'gender': gender,
        }),
      ).timeout(_requestTimeout);

      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final normalizedEmail = email.trim().toLowerCase();

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': normalizedEmail,
          'password': password,
        }),
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final user = body['user'] as Map<String, dynamic>?;
        final token = body['token']?.toString();

        if (user == null || user['id'] == null || token == null || token.isEmpty) {
          return false;
        }

        final userId = int.tryParse(user['id'].toString());

        if (userId == null) {
          return false;
        }

        SessionService.userId = userId;
        SessionService.email = (user['email'] ?? '').toString();
        SessionService.fullName = (user['fullName'] ?? '').toString();
        SessionService.token = token;
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> forgotPassword(String email, String newPassword) async {
    final url = Uri.parse('$baseUrl/auth/forgot-password');
    final normalizedEmail = email.trim().toLowerCase();

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': normalizedEmail,
          'newPassword': newPassword,
        }),
      ).timeout(_requestTimeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
