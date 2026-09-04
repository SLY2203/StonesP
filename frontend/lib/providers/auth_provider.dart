import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _currentUser != null && _apiClient.isAuthenticated;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isAlumnus => _currentUser?.isAlumnus ?? false;
  bool get isVerified => _currentUser?.isVerified ?? false;

  Future<void> initSession() async {
    await _apiClient.initTokens();
    if (_apiClient.isAuthenticated) {
      _currentUser = await _authService.getSavedUser();
      notifyListeners();
      try {
        _currentUser = await _authService.fetchCurrentUser();
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final res = await _authService.login(email, password);
      _currentUser = res['user'] as UserModel;
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = "Login failed: ${e.toString()}";
      _setLoading(false);
      return false;
    }
  }

  Future<bool> registerAlumni({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String registrationNumber,
    required int graduationYear,
    required String programme,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = await _authService.registerAlumni(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        registrationNumber: registrationNumber,
        graduationYear: graduationYear,
        programme: programme,
        phoneNumber: phoneNumber,
      );
      _currentUser = user;
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = "Registration failed: ${e.toString()}";
      _setLoading(false);
      return false;
    }
  }

  Future<void> checkVerificationStatus() async {
    if (!isAuthenticated) return;
    try {
      _currentUser = await _authService.fetchCurrentUser();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
