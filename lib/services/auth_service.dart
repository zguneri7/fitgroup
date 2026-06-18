import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:fitgroup/config/app_config.dart';
import 'package:fitgroup/services/session_service.dart';

enum LoginStatus {
  success,
  invalidCredentials,
  emailNotVerified,
  serverError,
  networkError,
}

class RegisterResult {
  const RegisterResult({
    required this.success,
    this.message,
    this.verificationCode,
    this.requiresEmailVerification = false,
  });

  final bool success;
  final String? message;
  final String? verificationCode;
  final bool requiresEmailVerification;
}

class LoginResult {
  const LoginResult({
    required this.status,
    this.message,
  });

  final LoginStatus status;
  final String? message;

  bool get isSuccess => status == LoginStatus.success;
}

class AuthService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  static const Duration _requestTimeout = Duration(seconds: 12);

  Future<RegisterResult> register(
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

      if (response.statusCode == 201) {
        Map<String, dynamic> body = <String, dynamic>{};
        try {
          body = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          body = <String, dynamic>{};
        }

        return RegisterResult(
          success: true,
          message: body['message']?.toString(),
          verificationCode: body['verificationCode']?.toString(),
          requiresEmailVerification: body['requiresEmailVerification'] == true,
        );
      }

      String? message;
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = body['message']?.toString();
      } catch (_) {
        message = null;
      }

      return RegisterResult(
        success: false,
        message: message,
      );
    } catch (_) {
      return const RegisterResult(
        success: false,
        message: 'Sunucuya baglanirken bir hata olustu.',
      );
    }
  }

  Future<LoginResult> login(String email, String password) async {
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
          return const LoginResult(
            status: LoginStatus.serverError,
            message: 'Sunucu gecersiz bir cevap dondurdu.',
          );
        }

        final userId = int.tryParse(user['id'].toString());

        if (userId == null) {
          return const LoginResult(
            status: LoginStatus.serverError,
            message: 'Kullanici bilgisi okunamadi.',
          );
        }

        SessionService.userId = userId;
        SessionService.email = (user['email'] ?? '').toString();
        SessionService.fullName = (user['fullName'] ?? '').toString();
        SessionService.token = token;
        return const LoginResult(status: LoginStatus.success);
      }

      String? message;
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = body['message']?.toString();
      } catch (_) {
        message = null;
      }

      if (response.statusCode == 401) {
        return LoginResult(
          status: LoginStatus.invalidCredentials,
          message: message,
        );
      }

      if (response.statusCode == 403) {
        final requiresEmailVerification = (() {
          try {
            final body = jsonDecode(response.body) as Map<String, dynamic>;
            return body['requiresEmailVerification'] == true;
          } catch (_) {
            return false;
          }
        })();

        if (requiresEmailVerification) {
          return LoginResult(
            status: LoginStatus.emailNotVerified,
            message: message,
          );
        }
      }

      return LoginResult(
        status: LoginStatus.serverError,
        message: message,
      );
    } on TimeoutException {
      return const LoginResult(
        status: LoginStatus.networkError,
        message: 'Sunucuya erisilemedi (zaman asimi).',
      );
    } catch (_) {
      return const LoginResult(
        status: LoginStatus.networkError,
        message: 'Sunucuya baglanirken bir hata olustu.',
      );
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
