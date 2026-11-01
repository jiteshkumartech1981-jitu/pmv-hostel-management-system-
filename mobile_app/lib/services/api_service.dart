import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/session.dart';
import 'auth_store.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  Map<String, String> _headers({bool auth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = AuthStore.instance.session?.token;
    if (auth && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  dynamic _decode(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      return response.body;
    }
  }

  String _errorMessage(dynamic body, int status) {
    if (body is Map && body['message'] != null) {
      return body['message'].toString();
    }
    if (body is String && body.trim().isNotEmpty) {
      return body;
    }
    if (status == 401) return 'Login expired or invalid credentials.';
    if (status == 403) return 'You do not have permission for this action.';
    return 'Server error ($status). Please check server status.';
  }

  Future<dynamic> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(const Duration(seconds: 12));
      final body = _decode(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      }
      throw ApiException(
        _errorMessage(body, response.statusCode),
        statusCode: response.statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'Unable to connect to backend server. Please verify network and server status.',
      );
    }
  }

  Future<UserSession> login(String username, String password) async {
    final body = await _send(
      () => http.post(
        _uri('/auth/login'),
        headers: _headers(auth: false),
        body: jsonEncode({'username': username.trim(), 'password': password}),
      ),
    );
    final session = UserSession.fromJson(body as Map<String, dynamic>);
    await AuthStore.instance.save(session);
    return session;
  }

  Future<Map<String, dynamic>> studentMe() async {
    final body = await _send(
      () => http.get(_uri('/students/me'), headers: _headers()),
    );
    return body as Map<String, dynamic>;
  }

  Future<List<dynamic>> messMenu({String? date}) async {
    final body = await _send(
      () => http.get(
        _uri('/mess-menu', date == null ? null : {'date': date}),
        headers: _headers(),
      ),
    );
    return body as List<dynamic>;
  }

  Future<List<dynamic>> messTimings() async {
    final body = await _send(
      () => http.get(_uri('/mess-timing'), headers: _headers()),
    );
    return body as List<dynamic>;
  }

  Future<List<dynamic>> myGatePasses() async {
    final body = await _send(
      () => http.get(_uri('/gatepass/my'), headers: _headers()),
    );
    return body as List<dynamic>;
  }

  Future<Map<String, dynamic>> applyGatePass(Map<String, dynamic> payload) async {
    final body = await _send(
      () => http.post(
        _uri('/gatepass'),
        headers: _headers(),
        body: jsonEncode(payload),
      ),
    );
    return body as Map<String, dynamic>;
  }

  Future<List<dynamic>> myComplaints() async {
    final body = await _send(
      () => http.get(_uri('/complaints/my'), headers: _headers()),
    );
    return body as List<dynamic>;
  }

  Future<Map<String, dynamic>> submitComplaint(Map<String, dynamic> payload) async {
    final body = await _send(
      () => http.post(
        _uri('/complaints'),
        headers: _headers(),
        body: jsonEncode(payload),
      ),
    );
    return body as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addMealRating({
    required int menuId,
    required String rollNumber,
    required int rating,
  }) async {
    final body = await _send(
      () => http.post(
        _uri('/meal-rating'),
        headers: _headers(),
        body: jsonEncode({
          'menuId': menuId,
          'studentRollNumber': rollNumber,
          'rating': rating,
        }),
      ),
    );
    return body as Map<String, dynamic>;
  }
}
