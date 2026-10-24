import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password, {String? role}) async {
    final body = <String, dynamic>{
      'email': email.trim().toLowerCase(),
      'password': password,
    };
    if (role != null && role.isNotEmpty) {
      body['role'] = role;
    }

    final response = await _client.post(
      'auth/login/',
      body: body,
      includeAuth: false,
    );

    final access = response['access'];
    final refresh = response['refresh'];
    final userJson = response['user'];

    await _client.saveTokens(access: access, refresh: refresh);
    final user = UserModel.fromJson(userJson);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserData, jsonEncode(userJson));
    } catch (_) {}

    return {'user': user, 'access': access, 'refresh': refresh};
  }

  Future<UserModel> registerAlumni({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String registrationNumber,
    required int graduationYear,
    required String programme,
    String? phoneNumber,
  }) async {
    final body = {
      'email': email.trim().toLowerCase(),
      'password': password,
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'registration_number': registrationNumber.trim().toUpperCase(),
      'graduation_year': graduationYear,
      'programme': programme,
      'phone_number': phoneNumber ?? '',
    };

    final response = await _client.post('auth/register/', body: body, includeAuth: false);
    return UserModel.fromJson(response['user']);
  }

  Future<Map<String, dynamic>> lookupGraduate(String registrationNumber) async {
    final reg = registrationNumber.trim().toUpperCase();
    final response = await _client.get('auth/lookup-graduate/?reg_number=$reg', includeAuth: false);
    return response as Map<String, dynamic>;
  }

  Future<UserModel?> getSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(AppConstants.keyUserData);
      if (jsonStr != null) {
        return UserModel.fromJson(jsonDecode(jsonStr));
      }
    } catch (_) {}
    return null;
  }

  Future<UserModel> fetchCurrentUser() async {
    final response = await _client.get('auth/me/');
    final user = UserModel.fromJson(response);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserData, jsonEncode(response));
    } catch (_) {}
    return user;
  }

  Future<void> logout() async {
    await _client.clearTokens();
  }
}
