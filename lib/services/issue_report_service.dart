import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

enum ExpectedResult { halal, haram, nonFood, unknown }

extension ExpectedResultValue on ExpectedResult {
  String get value {
    switch (this) {
      case ExpectedResult.halal:
        return 'halal';
      case ExpectedResult.haram:
        return 'haram';
      case ExpectedResult.nonFood:
        return 'non_food';
      case ExpectedResult.unknown:
        return 'unknown';
    }
  }
}

class IssueReportResult {
  final bool success;
  final String? issueUrl;
  final int? issueNumber;

  const IssueReportResult({
    required this.success,
    this.issueUrl,
    this.issueNumber,
  });
}

class IssueReportService {
  static http.Client _httpClient = http.Client();
  static bool _supabaseAvailable = AppConfig.hasSupabase;

  @visibleForTesting
  static void setHttpClientForTesting(http.Client client) {
    _httpClient = client;
    _supabaseAvailable = true;
  }

  @visibleForTesting
  static void resetForTesting() {
    _httpClient = http.Client();
    _supabaseAvailable = AppConfig.hasSupabase;
  }

  static Future<IssueReportResult> reportWrongResult({
    required String barcode,
    required String productName,
    required String currentResult,
    required ExpectedResult expectedResult,
    String? note,
  }) async {
    if (!_supabaseAvailable) {
      return const IssueReportResult(success: false);
    }
    try {
      final response = await _httpClient
          .post(
            Uri.parse('${AppConfig.supabaseUrl}/functions/v1/report-issue'),
            headers: {
              'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'barcode': barcode,
              'productName': productName,
              'currentResult': currentResult,
              'expectedResult': expectedResult.value,
              if (note != null && note.isNotEmpty) 'note': note,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return const IssueReportResult(success: false);
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return IssueReportResult(
        success: true,
        issueUrl: data['issueUrl'] as String?,
        issueNumber: data['issueNumber'] as int?,
      );
    } catch (_) {
      return const IssueReportResult(success: false);
    }
  }
}
