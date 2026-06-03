import 'dart:async';
import 'dart:convert';

import 'package:fitgroup/config/app_config.dart';
import 'package:fitgroup/services/session_service.dart';
import 'package:http/http.dart' as http;

class GroupInfo {
  const GroupInfo({
    required this.id,
    required this.name,
    required this.code,
  });

  final int id;
  final String name;
  final String code;
}

class GroupFlowEntry {
  const GroupFlowEntry({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.date,
    required this.weight,
    required this.waist,
    required this.chest,
  });

  final int userId;
  final String userName;
  final String userEmail;
  final DateTime date;
  final double? weight;
  final double? waist;
  final double? chest;
}

class GroupService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  static const Duration _requestTimeout = Duration(seconds: 12);

  Map<String, String>? _authHeaders() {
    final token = SessionService.token;
    if (token == null || token.isEmpty) {
      return null;
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<GroupInfo?> createGroup({required String name}) async {
    final headers = _authHeaders();
    if (headers == null) {
      return null;
    }

    final url = Uri.parse('$baseUrl/groups/create');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'name': name,
        }),
      ).timeout(_requestTimeout);

      if (response.statusCode != 201) {
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return _toGroupInfo(body['group'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<GroupInfo?> joinGroup({required String code}) async {
    final headers = _authHeaders();
    if (headers == null) {
      return null;
    }

    final url = Uri.parse('$baseUrl/groups/join');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'code': code,
        }),
      ).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return _toGroupInfo(body['group'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<List<GroupInfo>> fetchMyGroups() async {
    final headers = _authHeaders();
    if (headers == null) {
      return [];
    }

    final url = Uri.parse('$baseUrl/groups/mine');

    try {
      final response = await http.get(url, headers: headers).timeout(_requestTimeout);
      if (response.statusCode != 200) {
        return [];
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final groups = (body['groups'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      return groups.map(_toGroupInfo).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<GroupFlowEntry>> fetchGroupFlow({required int groupId, int limit = 50}) async {
    final headers = _authHeaders();
    if (headers == null) {
      return [];
    }

    final url = Uri.parse('$baseUrl/groups/$groupId/flow?limit=$limit');

    try {
      final response = await http.get(url, headers: headers).timeout(_requestTimeout);
      if (response.statusCode != 200) {
        return [];
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final flow = (body['flow'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      return flow.map(_toFlowEntry).toList();
    } catch (_) {
      return [];
    }
  }

  GroupInfo _toGroupInfo(Map<String, dynamic> json) {
    return GroupInfo(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
    );
  }

  GroupFlowEntry _toFlowEntry(Map<String, dynamic> json) {
    final dateParts = (json['measurement_date'] as String).split('-');

    return GroupFlowEntry(
      userId: (json['user_id'] as num).toInt(),
      userName: (json['full_name'] ?? '').toString(),
      userEmail: (json['email'] ?? '').toString(),
      date: DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      ),
      weight: _toDouble(json['weight']),
      waist: _toDouble(json['waist']),
      chest: _toDouble(json['chest']),
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}
