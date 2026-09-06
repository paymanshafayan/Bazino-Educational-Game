import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

/// ApiClient — قرارداد دقیق با بک‌اند FastAPI (فاز ۲).
/// baseUrl پیش‌فرض: `API_BASE_URL` (dart-define)؛ وگرنه اندرویدیِ محلی (10.0.2.2).
class ApiClient {
  String baseUrl = const String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000');
  String? token;
  int? parentId;
  String displayName = '';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _u(String path, [Map<String, String>? q]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: q);

  Future<Map<String, dynamic>> _get(String path,
      [Map<String, String>? q]) async {
    final r = await http.get(_u(path, q), headers: _headers).timeout(
        const Duration(seconds: 10));
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    }
    throw ApiException(r.statusCode, utf8.decode(r.bodyBytes));
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> b) async {
    final r = await http
        .post(_u(path), headers: _headers, body: jsonEncode(b))
        .timeout(const Duration(seconds: 10));
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    }
    throw ApiException(r.statusCode, utf8.decode(r.bodyBytes));
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      final j = await _post('/auth/register', {
        'email': email,
        'password': password,
        'display_name': name,
        'role': 'parent',
      });
      token = j['access_token'] as String;
      final me = await _get('/auth/me');
      parentId = me['id'] as int;
      displayName = me['display_name'] as String;
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final j = await _post(
          '/auth/login', {'email': email, 'password': password});
      token = j['access_token'] as String;
      final me = await _get('/auth/me');
      parentId = me['id'] as int;
      displayName = me['display_name'] as String;
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<String> createFamilyCode() async {
    final j = await _post('/links/create', {});
    return j['code'] as String;
  }

  Future<List<FamilyLink>> myLinks() async {
    final raw = await http
        .get(_u('/links/mine'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    final l = jsonDecode(utf8.decode(raw.bodyBytes)) as List;
    return l.map((e) => FamilyLink.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MasteryReport> mastery(int childId) async =>
      MasteryReport.fromJson(await _get('/mastery/$childId'));

  Future<Wallet> wallet() async => Wallet.fromJson(await _get('/wallet'));

  Future<Map<String, dynamic>> submitGrade(
      int childId, String subject, double score) async {
    return _post('/reality/grades',
        {'child_id': childId, 'subject': subject, 'score': score});
  }
}

class ApiException implements Exception {
  final int status;
  final String body;
  ApiException(this.status, this.body);
  @override
  String toString() => 'ApiException($status): $body';
}
