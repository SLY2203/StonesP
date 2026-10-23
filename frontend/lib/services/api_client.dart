import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

  String? _accessToken;
  String? _refreshToken;
  String? get refreshToken => _refreshToken;

  static String get _detectInitialBaseUrl {
    try {
      if (kIsWeb) {
        final host = Uri.base.host;
        if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
          return AppConstants.productionApiUrl;
        }
        return AppConstants.localApiUrl;
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        if (kReleaseMode) {
          return AppConstants.productionApiUrl;
        }
        return AppConstants.defaultApiUrl;
      }
      return AppConstants.localApiUrl;
    } catch (_) {
      return AppConstants.localApiUrl;
    }
  }

  // Auto-detect base URL (10.0.2.2 for Android Emulator, 127.0.0.1 for Windows/iOS/Web)
  String _baseUrl = _detectInitialBaseUrl;
  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  Future<void> initTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(AppConstants.keyAccessToken);
      _refreshToken = prefs.getString(AppConstants.keyRefreshToken);
    } catch (_) {}
  }

  Future<void> saveTokens({required String access, String? refresh}) async {
    _accessToken = access;
    if (refresh != null) _refreshToken = refresh;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyAccessToken, access);
      if (refresh != null) {
        await prefs.setString(AppConstants.keyRefreshToken, refresh);
      }
    } catch (_) {}
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyAccessToken);
      await prefs.remove(AppConstants.keyRefreshToken);
      await prefs.remove(AppConstants.keyUserData);
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
    } on http.ClientException {
      throw ApiException(message: "Cannot connect to DCS Alumni server at $_baseUrl. Please check connection.");
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: "Network request failed: ${e.toString()}");
    }
  }

  Future<List<int>> getBytes(String endpoint, {Map<String, dynamic>? queryParams, bool includeAuth = true}) async {
    Uri uri = _buildUri(endpoint, queryParams);
    try {
      final response = await http
          .get(uri, headers: _getHeaders(includeAuth: includeAuth))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      } else {
        throw ApiException(
          message: "Failed to download file: Server returned HTTP ${response.statusCode}",
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException {
      throw ApiException(message: "Cannot connect to DCS Alumni server at $_baseUrl to download file.");
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: "Download request failed: ${e.toString()}");
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
    } on http.ClientException {
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
