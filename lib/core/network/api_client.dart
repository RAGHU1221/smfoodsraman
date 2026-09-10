import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException(this.message, [this.statusCode = -1]);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static final _client = http.Client();

  static Map<String, String> _headers(String? token) => {
    'Content-Type':    'application/json; charset=utf-8',
    'Accept':          'application/json',
    'X-Requested-With':'SMFoods-Flutter/3.0',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  static Future<Map<String, dynamic>> post({
    required String endpoint,
    required Map<String, dynamic> body,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.API_URL}/$endpoint');
      if (kDebugMode) {
        debugPrint('[API POST] URL: $uri');
        debugPrint('[API POST] Body: ${jsonEncode(body)}');
      }
      final res = await _client.post(
        uri,
        headers: _headers(token),
        body: jsonEncode(body),
      ).timeout(AppConstants.CONNECT_TIMEOUT);

      if (kDebugMode) {
        debugPrint('[API POST] Status: ${res.statusCode}');
        debugPrint('[API POST] Raw body: ${res.body}');
      }

      return _parseResponse(res);
    } on SocketException {
      throw const ApiException('No internet connection');
    } on HttpException catch (e) {
      throw ApiException('HTTP error: ${e.message}');
    } on FormatException {
      throw const ApiException('Invalid server response');
    } on TimeoutException {
      throw const ApiException('Connection timed out');
    }
  }

  static Future<Map<String, dynamic>> get({
    required String endpoint,
    String? token,
    Map<String, String>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('${AppConstants.API_URL}/$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final res = await _client.get(
        uri,
        headers: _headers(token),
      ).timeout(AppConstants.CONNECT_TIMEOUT);

      return _parseResponse(res);
    } on SocketException {
      throw const ApiException('No internet connection');
    } on TimeoutException {
      throw const ApiException('Connection timed out');
    }
  }

  static Map<String, dynamic> _parseResponse(http.Response res) {
    // Strip BOM and whitespace defensively before any checks
    var body = res.body;
    if (body.isNotEmpty && body.codeUnitAt(0) == 0xFEFF) {
      body = body.substring(1); // strip UTF-8 BOM if present
    }
    body = body.trim();

    if (body.isEmpty) {
      throw ApiException(
        'Empty response from server (HTTP ${res.statusCode})',
        res.statusCode,
      );
    }

    // Detect HTML error response
    if (body.startsWith('<')) {
      final preview = body.length > 120 ? body.substring(0, 120) : body;
      throw ApiException(
        'Server returned HTML instead of JSON (HTTP ${res.statusCode}): $preview',
        res.statusCode,
      );
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      final preview = body.length > 120 ? body.substring(0, 120) : body;
      throw ApiException('Invalid JSON response: $preview', res.statusCode);
    }

    // Check success
    final isOk = json['success'] == true || json['ok'] == true;

    if (res.statusCode == 200 && isOk) return json;

    if (res.statusCode == 401) throw const ApiException('Session expired. Please login again.', 401);
    if (res.statusCode == 403) throw const ApiException('Access denied', 403);
    if (res.statusCode == 404) throw const ApiException('API endpoint not found', 404);
    if (res.statusCode >= 500) throw ApiException('Server error (${res.statusCode})', res.statusCode);

    final msg = json['message'] as String?
        ?? json['error'] as String?
        ?? 'Request failed';
    throw ApiException(msg, res.statusCode);
  }
}
