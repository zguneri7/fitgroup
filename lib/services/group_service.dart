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

class GroupLatestMeasurement {
  const GroupLatestMeasurement({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.date,
    required this.chest,
    required this.waist,
    required this.belly,
    required this.lowerBelly,
    required this.hip,
    required this.leg,
    required this.weight,
  });

  final int userId;
  final String userName;
  final String userEmail;
  final DateTime date;
  final double? chest;
  final double? waist;
  final double? belly;
  final double? lowerBelly;
  final double? hip;
  final double? leg;
  final double? weight;
}

class GroupMember {
  const GroupMember({
    required this.id,
    required this.displayName,
    required this.fullName,
    required this.email,
    required this.joinedAt,
  });

  final int id;
  final String displayName;
  final String fullName;
  final String email;
  final DateTime joinedAt;
}

class GroupDetail {
  const GroupDetail({
    required this.group,
    required this.members,
    required this.inviteLink,
    required this.inviteMessage,
  });

  final GroupInfo group;
  final List<GroupMember> members;
  final String inviteLink;
  final String inviteMessage;
}

class GroupActionResult {
  const GroupActionResult({
    this.group,
    this.message,
  });

  final GroupInfo? group;
  final String? message;

  bool get isSuccess => group != null;
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

  Future<GroupActionResult> createGroup({required String name}) async {
    final headers = _authHeaders();
    if (headers == null) {
      return const GroupActionResult(
        message: 'Oturum bulunamadi. Lutfen tekrar giris yap.',
      );
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
        return GroupActionResult(message: _extractMessage(response.body, fallback: 'Grup olusturulamadi.'));
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return GroupActionResult(group: _toGroupInfo(body['group'] as Map<String, dynamic>));
    } on TimeoutException {
      return const GroupActionResult(
        message: 'Sunucuya erisilemedi (zaman asimi).',
      );
    } catch (_) {
      return const GroupActionResult(
        message: 'Sunucuya baglanirken bir hata olustu.',
      );
    }
  }

  Future<GroupActionResult> joinGroup({required String code}) async {
    final headers = _authHeaders();
    if (headers == null) {
      return const GroupActionResult(
        message: 'Oturum bulunamadi. Lutfen tekrar giris yap.',
      );
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
        return GroupActionResult(message: _extractMessage(response.body, fallback: 'Grup bulunamadi.'));
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return GroupActionResult(group: _toGroupInfo(body['group'] as Map<String, dynamic>));
    } on TimeoutException {
      return const GroupActionResult(
        message: 'Sunucuya erisilemedi (zaman asimi).',
      );
    } catch (_) {
      return const GroupActionResult(
        message: 'Sunucuya baglanirken bir hata olustu.',
      );
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

  Future<List<GroupLatestMeasurement>> fetchGroupLatestMeasurements({required int groupId}) async {
    final headers = _authHeaders();
    if (headers == null) {
      return [];
    }

    final url = Uri.parse('$baseUrl/groups/$groupId/latest-measurements');

    try {
      final response = await http.get(url, headers: headers).timeout(_requestTimeout);
      if (response.statusCode != 200) {
        return [];
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final measurements = (body['measurements'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      return measurements.map(_toLatestMeasurement).toList();
    } catch (_) {
      return [];
    }
  }

  Future<GroupDetail?> fetchGroupDetail({required int groupId}) async {
    final headers = _authHeaders();
    if (headers == null) {
      return null;
    }

    final url = Uri.parse('$baseUrl/groups/$groupId');

    try {
      final response = await http.get(url, headers: headers).timeout(_requestTimeout);
      if (response.statusCode != 200) {
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final members = (body['members'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(_toGroupMember)
          .toList();

      return GroupDetail(
        group: _toGroupInfo(body['group'] as Map<String, dynamic>),
        members: members,
        inviteLink: (body['inviteLink'] ?? '').toString(),
        inviteMessage: (body['inviteMessage'] ?? '').toString(),
      );
    } catch (_) {
      return null;
    }
  }

  GroupInfo _toGroupInfo(Map<String, dynamic> json) {
    return GroupInfo(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
    );
  }

  GroupFlowEntry _toFlowEntry(Map<String, dynamic> json) {
    final dateParts = (json['measurement_date'] as String).split('-');

    return GroupFlowEntry(
      userId: _toInt(json['user_id']),
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

  GroupMember _toGroupMember(Map<String, dynamic> json) {
    return GroupMember(
      id: _toInt(json['id']),
      displayName: (json['display_name'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      joinedAt: DateTime.tryParse((json['joined_at'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Future<List<Map<String, dynamic>>> fetchGroupMessages({required int groupId, int limit = 50}) async {
    final headers = _authHeaders();
    if (headers == null) {
      return [];
    }

    final url = Uri.parse('$baseUrl/groups/$groupId/messages?limit=$limit');

    try {
      final response = await http.get(url, headers: headers).timeout(_requestTimeout);
      if (response.statusCode != 200) {
        return [];
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final messages = (body['messages'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      return messages;
    } catch (_) {
      return [];
    }
  }

  Future<void> sendGroupMessage({required int groupId, required String text}) async {
    final headers = _authHeaders();
    if (headers == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse('$baseUrl/groups/$groupId/messages');
    final body = jsonEncode({'text': text});

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(_requestTimeout);

      if (response.statusCode != 201) {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  GroupLatestMeasurement _toLatestMeasurement(Map<String, dynamic> json) {
    final dateParts = (json['measurement_date'] as String).split('-');

    return GroupLatestMeasurement(
      userId: _toInt(json['user_id']),
      userName: (json['full_name'] ?? '').toString(),
      userEmail: (json['email'] ?? '').toString(),
      date: DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      ),
      chest: _toDouble(json['chest']),
      waist: _toDouble(json['waist']),
      belly: _toDouble(json['belly']),
      lowerBelly: _toDouble(json['lower_belly']),
      hip: _toDouble(json['hip']),
      leg: _toDouble(json['leg']),
      weight: _toDouble(json['weight']),
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

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _extractMessage(String body, {required String fallback}) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final message = json['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    } catch (_) {
      // Ignore invalid response bodies and fall back to a generic message.
    }

    return fallback;
  }
}
