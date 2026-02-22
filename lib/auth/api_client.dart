import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'auth_providers.dart';

/// Base URL for Heroku (or env). No trailing slash.
final apiBaseUrlProvider = Provider<String>((ref) {
  return const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://your-app.herokuapp.com/api',
  );
});

/// HTTP client that attaches Authorization: Bearer <idToken> to all requests to [baseUrl].
/// Use for Heroku API. Does not implement backend calls; shared utility only.
class AuthenticatedHttpClient {
  AuthenticatedHttpClient({
    required this.baseUrl,
    required this.getToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Future<String?> Function() getToken;
  final http.Client _client;

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    return _request('GET', uri, headers: headers);
  }

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _request('POST', uri, headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _request('PUT', uri, headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> delete(Uri uri, {Map<String, String>? headers}) async {
    return _request('DELETE', uri, headers: headers);
  }

  Future<http.Response> _request(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final token = await getToken();
    final h = Map<String, String>.of(headers ?? {});
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    final url = uri.isAbsolute ? uri : Uri.parse('$baseUrl${uri.path}${uri.query.isNotEmpty ? '?${uri.query}' : ''}');
    switch (method) {
      case 'GET':
        return _client.get(url, headers: h);
      case 'POST':
        return _client.post(url, headers: h, body: body, encoding: encoding);
      case 'PUT':
        return _client.put(url, headers: h, body: body, encoding: encoding);
      case 'DELETE':
        return _client.delete(url, headers: h);
      default:
        throw UnsupportedError('Method $method');
    }
  }
}

/// Provider for shared authenticated client. Depends on [apiBaseUrlProvider] and [idTokenProvider].
final authenticatedHttpClientProvider = Provider<AuthenticatedHttpClient>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return AuthenticatedHttpClient(
    baseUrl: baseUrl,
    getToken: () async => ref.read(idTokenProvider.future),
  );
});
