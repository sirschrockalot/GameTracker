import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Standard API error: { error, message }.
class ApiException implements Exception {
  ApiException(this.error, this.message);
  final String error;
  final String message;
  @override
  String toString() => message;
}

/// HTTP client that attaches Authorization: Bearer <jwt>; on 401 re-registers and retries once.
class AuthenticatedHttpClient {
  AuthenticatedHttpClient({
    required this.baseUrl,
    required this.getToken,
    Future<void> Function(String baseUrl)? forceReRegister,
    http.Client? client,
  })  : _forceReRegister = forceReRegister,
        _client = client ?? http.Client();

  final String baseUrl;
  final Future<String?> Function() getToken;
  final Future<void> Function(String baseUrl)? _forceReRegister;
  final http.Client _client;

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    return _request('GET', uri, headers: headers, isRetry: false);
  }

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _request('POST', uri, headers: headers, body: body, encoding: encoding, isRetry: false);
  }

  Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _request('PUT', uri, headers: headers, body: body, encoding: encoding, isRetry: false);
  }

  Future<http.Response> delete(Uri uri, {Map<String, String>? headers}) async {
    return _request('DELETE', uri, headers: headers, isRetry: false);
  }

  Future<http.Response> _request(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    required bool isRetry,
  }) async {
    final token = await getToken();
    final h = Map<String, String>.of(headers ?? {});
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    final url = uri.isAbsolute ? uri : Uri.parse('$baseUrl${uri.path}${uri.query.isNotEmpty ? '?${uri.query}' : ''}');
    http.Response res;
    switch (method) {
      case 'GET':
        res = await _client.get(url, headers: h);
        break;
      case 'POST':
        res = await _client.post(url, headers: h, body: body, encoding: encoding);
        break;
      case 'PUT':
        res = await _client.put(url, headers: h, body: body, encoding: encoding);
        break;
      case 'DELETE':
        res = await _client.delete(url, headers: h);
        break;
      default:
        throw UnsupportedError('Method $method');
    }

    if (res.statusCode == 401 &&
        _forceReRegister != null &&
        !isRetry) {
      if (kDebugMode) debugPrint('ApiClient: 401, re-registering and retrying once');
      await _forceReRegister!(baseUrl);
      return _request(method, uri, headers: headers, body: body, encoding: encoding, isRetry: true);
    }

    if (res.statusCode == 403) {
      throw ApiException('forbidden', _message(res) ?? "You don't have permission");
    }
    if (res.statusCode >= 500) {
      throw ApiException('server_error', _message(res) ?? 'Something went wrong. Please try again.');
    }
    return res;
  }

  static String? _message(http.Response res) {
    try {
      final m = jsonDecode(res.body) as Map<String, dynamic>?;
      return m?['message'] as String?;
    } catch (_) {
      return null;
    }
  }
}
