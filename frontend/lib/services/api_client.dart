import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException({required this.message, this.statusCode, this.details});

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final _storage = const FlutterSecureStorage();
  String? _accessToken;
  String? _refreshToken;

  // Custom base URL support (defaults to AppConstants.defaultApiUrl)
  String _baseUrl = AppConstants.defaultApiUrl;
  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  Future<void> initTokens() async {
    try {
      _accessToken = await _storage.read(key: AppConstants.keyAccessToken);
      _refreshToken = await _storage.read(key: AppConstants.keyRefreshToken);
    } catch (_) {
      // Secure storage fallback if unavailable in environment
    }
  }

  Future<void> saveTokens({required String access, String? refresh}) async {
    _accessToken = access;
    if (refresh != null) _refreshToken = refresh;
    try {
      await _storage.write(key: AppConstants.keyAccessToken, value: access);
      if (refresh != null) {
        await _storage.write(key: AppConstants.keyRefreshToken, value: refresh);
      }
    } catch (_) {}
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    try {
      await _storage.delete(key: AppConstants.keyAccessToken);
      await _storage.delete(key: AppConstants.keyRefreshToken);
      await _storage.delete(key: AppConstants.keyUserData);
    } catch (_) {}
  }

  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (includeAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams, bool includeAuth = true}) async {
    Uri uri = _buildUri(endpoint, queryParams);
    try {
      final response = await http
          .get(uri, headers: _getHeaders(includeAuth: includeAuth))
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on SocketException {
      throw ApiException(message: "Cannot connect to DCS Alumni server at $_baseUrl. Please check connection.");
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: "Network request failed: ${e.toString()}");
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body, bool includeAuth = true}) async {
    Uri uri = _buildUri(endpoint);
    try {
      final response = await http
          .post(
            uri,
            headers: _getHeaders(includeAuth: includeAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on SocketException {
      throw ApiException(message: "Cannot reach backend server. Check that Django API is running.");
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: "Request error: ${e.toString()}");
    }
  }

  Future<dynamic> put(String endpoint, {dynamic body, bool includeAuth = true}) async {
    Uri uri = _buildUri(endpoint);
    try {
      final response = await http
          .put(
            uri,
            headers: _getHeaders(includeAuth: includeAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  Future<dynamic> patch(String endpoint, {dynamic body, bool includeAuth = true}) async {
    Uri uri = _buildUri(endpoint);
    try {
      final response = await http
          .patch(
            uri,
            headers: _getHeaders(includeAuth: includeAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  Future<dynamic> delete(String endpoint, {bool includeAuth = true}) async {
    Uri uri = _buildUri(endpoint);
    try {
      final response = await http
          .delete(uri, headers: _getHeaders(includeAuth: includeAuth))
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    String cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    String fullUrl = '$_baseUrl/$cleanEndpoint';
    Uri uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      Map<String, String> stringParams = {};
      queryParams.forEach((key, value) {
        if (value != null) {
          stringParams[key] = value.toString();
        }
      });
      uri = uri.replace(queryParameters: stringParams);
    }
    return uri;
  }

  dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      body = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      String errorMessage = "Server error occurred (${response.statusCode})";
      if (body is Map) {
        if (body.containsKey('detail')) {
          errorMessage = body['detail'].toString();
        } else if (body.containsKey('error')) {
          errorMessage = body['error'].toString();
        } else if (body.containsKey('message')) {
          errorMessage = body['message'].toString();
        } else {
          // Flatten field error lists
          final firstKey = body.keys.first;
          final firstVal = body[firstKey];
          if (firstVal is List && firstVal.isNotEmpty) {
            errorMessage = "$firstKey: ${firstVal.first}";
          } else {
            errorMessage = "$firstKey: $firstVal";
          }
        }
      }
      throw ApiException(message: errorMessage, statusCode: response.statusCode, details: body);
    }
  }
}
