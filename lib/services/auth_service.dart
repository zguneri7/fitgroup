import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:fitgroup/config/app_config.dart';

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
          'email': email,
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

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}
