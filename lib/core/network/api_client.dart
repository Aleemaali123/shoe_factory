import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.baseUrl});

  final String baseUrl;
  String? token;
  final http.Client _http = http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path) {
    return _decode(_http.get(Uri.parse('$baseUrl$path'), headers: _headers));
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) {
    return _decode(_http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body == null ? null : jsonEncode(body),
    ));
  }

  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) {
    return _decode(_http.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body == null ? null : jsonEncode(body),
    ));
  }

  Future<dynamic> delete(String path) {
    return _decode(_http.delete(Uri.parse('$baseUrl$path'), headers: _headers));
  }

  Future<dynamic> _decode(Future<http.Response> request) async {
    final response = await request;
    final raw = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final message = raw is Map && raw['error'] is String
          ? raw['error'] as String
          : 'Something went wrong. Try again.';
      throw ApiException(message);
    }
    if (raw is Map && raw.containsKey('data')) return raw['data'];
    return raw;
  }
}
