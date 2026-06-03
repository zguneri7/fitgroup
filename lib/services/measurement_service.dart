import 'dart:async';
import 'dart:convert';

import 'package:fitgroup/config/app_config.dart';
import 'package:fitgroup/services/measurement_store.dart';
import 'package:http/http.dart' as http;

class MeasurementService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  static const Duration _requestTimeout = Duration(seconds: 12);

  Future<bool> saveMeasurement(MeasurementEntry entry) async {
    final url = Uri.parse('$baseUrl/measurements');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'measurementDate': _formatDate(entry.date),
          'chest': entry.chest,
          'waist': entry.waist,
          'belly': entry.belly,
          'lowerBelly': entry.lowerBelly,
          'hip': entry.hip,
          'leg': entry.leg,
          'weight': entry.weight,
        }),
      ).timeout(_requestTimeout);

      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<List<MeasurementEntry>> fetchLatestMeasurements({int limit = 2}) async {
    final url = Uri.parse('$baseUrl/measurements/latest?limit=$limit');

    try {
      final response = await http.get(url).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        return [];
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (decoded['measurements'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      return list.map(_fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  MeasurementEntry _fromJson(Map<String, dynamic> json) {
    final dateParts = (json['measurement_date'] as String).split('-');

    return MeasurementEntry(
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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$year-$month-$day';
  }
}