import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:habit_constellation/models/habit.dart';
import 'package:habit_constellation/models/log.dart';
import 'package:habit_constellation/models/user.dart';
import 'package:habit_constellation/repositories/habit_repository.dart';
import 'package:habit_constellation/services/token_store.dart';

class HttpRepository implements HabitRepository {
  final String baseUrl;
  final TokenStore _tokenStore;
  final http.Client _client;

  HttpRepository({
    required this.baseUrl,
    TokenStore? tokenStore,
    http.Client? client,
  })  : _tokenStore = tokenStore ?? TokenStore(),
        _client = client ?? http.Client();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _tokenStore.getAccessToken();
    if (token == null) throw AuthException('No access token');
    return {'Authorization': 'Bearer $token'};
  }

  Future<http.Response> _get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final headers = await _authHeaders();
    var response = await _client.get(uri, headers: headers);
    if (response.statusCode == 401) {
      response = await _refreshAndRetry(() => _client.get(uri, headers: headers));
    }
    return response;
  }

  Future<http.Response> _post(String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _authHeaders();
    headers['Content-Type'] = 'application/json';
    var response = await _client.post(uri, headers: headers, body: jsonEncode(body));
    if (response.statusCode == 401) {
      response = await _refreshAndRetry(() =>
          _client.post(uri, headers: {...headers, 'Content-Type': 'application/json'}, body: jsonEncode(body)));
    }
    return response;
  }

  Future<http.Response> _put(String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _authHeaders();
    headers['Content-Type'] = 'application/json';
    var response = await _client.put(uri, headers: headers, body: jsonEncode(body));
    if (response.statusCode == 401) {
      response = await _refreshAndRetry(() =>
          _client.put(uri, headers: {...headers, 'Content-Type': 'application/json'}, body: jsonEncode(body)));
    }
    return response;
  }

  Future<http.Response> _delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _authHeaders();
    var response = await _client.delete(uri, headers: headers);
    if (response.statusCode == 401) {
      response = await _refreshAndRetry(() => _client.delete(uri, headers: headers));
    }
    return response;
  }

  Future<http.Response> _patch(String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _authHeaders();
    headers['Content-Type'] = 'application/json';
    var response = await _client.patch(uri, headers: headers, body: jsonEncode(body));
    if (response.statusCode == 401) {
      response = await _refreshAndRetry(() =>
          _client.patch(uri, headers: {...headers, 'Content-Type': 'application/json'}, body: jsonEncode(body)));
    }
    return response;
  }

  Future<http.Response> _refreshAndRetry(Future<http.Response> Function() retry) async {
    final refreshToken = await _tokenStore.getRefreshToken();
    if (refreshToken == null) throw AuthException('No refresh token');

    final uri = Uri.parse('$baseUrl/auth/refresh');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (response.statusCode != 200) {
      await _tokenStore.clear();
      throw AuthException('Refresh failed');
    }

    final data = jsonDecode(response.body);
    await _tokenStore.saveTokens(
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
    );

    return retry();
  }

  void _checkError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final body = jsonDecode(response.body);
    final detail = body['detail'];
    if (detail is Map) {
      throw ApiException(detail['code'] ?? 'unknown', detail['message'] ?? 'Error');
    }
    throw ApiException('unknown', 'Error ${response.statusCode}');
  }

  @override
  Future<User> signInWithGoogle(String idToken) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    );
    _checkError(response);
    final data = jsonDecode(response.body);
    await _tokenStore.saveTokens(
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
    );
    return User.fromJson(data['user']);
  }

  @override
  Future<void> signOut() async {
    await _tokenStore.clear();
  }

  @override
  Future<bool> isSignedIn() async {
    final token = await _tokenStore.getAccessToken();
    return token != null;
  }

  @override
  Future<User> getCurrentUser() async {
    final response = await _get('/me');
    _checkError(response);
    return User.fromJson(jsonDecode(response.body));
  }

  @override
  Future<List<HabitWithTodayLog>> getHabits(String date) async {
    final response = await _get('/habits', queryParams: {'date': date});
    _checkError(response);
    final data = jsonDecode(response.body);
    return (data['habits'] as List)
        .map((h) => HabitWithTodayLog.fromJson(h))
        .toList();
  }

  @override
  Future<Habit> createHabit(String name) async {
    final response = await _post('/habits', body: {'name': name});
    _checkError(response);
    return Habit.fromJson(jsonDecode(response.body));
  }

  @override
  Future<Habit> renameHabit(String id, String name) async {
    final response = await _put('/habits/$id', body: {'name': name});
    _checkError(response);
    return Habit.fromJson(jsonDecode(response.body));
  }

  @override
  Future<void> deleteHabit(String id) async {
    final response = await _delete('/habits/$id');
    _checkError(response);
  }

  @override
  Future<LogEntry> logHabit(String habitId, String logDate) async {
    final response = await _post('/habits/$habitId/logs', body: {'log_date': logDate});
    _checkError(response);
    return LogEntry.fromJson(jsonDecode(response.body));
  }

  @override
  Future<void> deleteLog(String habitId, String logDate) async {
    final response = await _delete('/habits/$habitId/logs/$logDate');
    _checkError(response);
  }

  @override
  Future<LogEntry> patchLog(String logId, {String? comment}) async {
    final response = await _patch('/habit_logs/$logId', body: {'comment': comment});
    _checkError(response);
    return LogEntry.fromJson(jsonDecode(response.body));
  }

  @override
  Future<LogsResponse> getLogs(String from, String to) async {
    final response = await _get('/logs', queryParams: {'from': from, 'to': to});
    _checkError(response);
    return LogsResponse.fromJson(jsonDecode(response.body));
  }

  @override
  Future<User> patchMe({bool? tooltipLogSeen, bool? tooltipCommentSeen}) async {
    final body = <String, dynamic>{};
    if (tooltipLogSeen != null) body['tooltip_log_seen'] = tooltipLogSeen;
    if (tooltipCommentSeen != null) body['tooltip_comment_seen'] = tooltipCommentSeen;
    final response = await _patch('/me', body: body);
    _checkError(response);
    return User.fromJson(jsonDecode(response.body));
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class ApiException implements Exception {
  final String code;
  final String message;
  ApiException(this.code, this.message);
}
