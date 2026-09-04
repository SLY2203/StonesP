import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../services/alumni_service.dart';
import '../services/api_client.dart';

class AlumniProvider with ChangeNotifier {
  final AlumniService _alumniService = AlumniService();

  AlumniProfileModel? _myProfile;
  List<AlumniDirectoryItemModel> _directory = [];
  AlumniProfileModel? _selectedAlumnus;
  bool _isLoading = false;
  String? _errorMessage;

  // Search & Filters
  String _searchQuery = '';
  int? _filterGradYear;
  String? _filterProgramme;
  bool? _filterIsVerified;

  AlumniProfileModel? get myProfile => _myProfile;
  List<AlumniDirectoryItemModel> get directory => _directory;
  AlumniProfileModel? get selectedAlumnus => _selectedAlumnus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  int? get filterGradYear => _filterGradYear;
  String? get filterProgramme => _filterProgramme;
  bool? get filterIsVerified => _filterIsVerified;

  Future<void> fetchMyProfile() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _myProfile = await _alumniService.getMyProfile();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> updateMyProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _myProfile = await _alumniService.updateMyProfile(data);
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchDirectory({
    String? q,
    int? gradYear,
    String? programme,
    bool? isVerified,
  }) async {
    if (q != null) _searchQuery = q;
    if (gradYear != null) _filterGradYear = gradYear == 0 ? null : gradYear;
    if (programme != null) _filterProgramme = programme.isEmpty ? null : programme;
    if (isVerified != null) _filterIsVerified = isVerified;

    _setLoading(true);
    _errorMessage = null;
    try {
      _directory = await _alumniService.getDirectory(
        q: _searchQuery,
        gradYear: _filterGradYear,
        programme: _filterProgramme,
        isVerified: _filterIsVerified,
      );
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchAlumnusDetail(int id) async {
    _setLoading(true);
    _selectedAlumnus = null;
    try {
      _selectedAlumnus = await _alumniService.getAlumnusDetail(id);
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> toggleVerification(int userId, bool newStatus) async {
    try {
      await _alumniService.verifyAlumnus(userId, newStatus);
      // Refresh item in directory
      _directory = _directory.map((item) {
        if (item.userId == userId) {
          return AlumniDirectoryItemModel(
            id: item.id,
            userId: item.userId,
            fullName: item.fullName,
            email: item.email,
            isVerified: newStatus,
            registrationNumber: item.registrationNumber,
            graduationYear: item.graduationYear,
            programme: item.programme,
            phoneNumber: item.phoneNumber,
            currentJobTitle: item.currentJobTitle,
            currentEmployer: item.currentEmployer,
            currentStatus: item.currentStatus,
          );
        }
        return item;
      }).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
