import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../models/mentorship_model.dart';
import '../models/roster_model.dart';
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
  String? _filterSkill;
  int? _filterGradYear;
  String? _filterProgramme;
  bool? _filterIsVerified;

  // Suggestion 3: Mentorship state
  List<MentorModel> _mentors = [];
  List<MentorshipRequestModel> _mentorshipRequests = [];

  // Suggestion 2: Graduation Roster state
  List<GraduationRosterModel> _rosterRecords = [];

  AlumniProfileModel? get myProfile => _myProfile;
  List<AlumniDirectoryItemModel> get directory => _directory;
  AlumniProfileModel? get selectedAlumnus => _selectedAlumnus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  String? get filterSkill => _filterSkill;
  int? get filterGradYear => _filterGradYear;
  String? get filterProgramme => _filterProgramme;
  bool? get filterIsVerified => _filterIsVerified;

  List<MentorModel> get mentors => _mentors;
  List<MentorshipRequestModel> get mentorshipRequests => _mentorshipRequests;
  List<GraduationRosterModel> get rosterRecords => _rosterRecords;

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
    String? skill,
    int? gradYear,
    String? programme,
    bool? isVerified,
  }) async {
    if (q != null) _searchQuery = q;
    if (skill != null) _filterSkill = skill.isEmpty ? null : skill;
    if (gradYear != null) _filterGradYear = gradYear == 0 ? null : gradYear;
    if (programme != null) _filterProgramme = programme.isEmpty ? null : programme;
    if (isVerified != null) _filterIsVerified = isVerified;

    _setLoading(true);
    _errorMessage = null;
    try {
      _directory = await _alumniService.getDirectory(
        q: _searchQuery,
        skill: _filterSkill,
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
            skills: item.skills,
            skillsList: item.skillsList,
            isAvailableForMentorship: item.isAvailableForMentorship,
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

  // ===========================================================================
  // Suggestion 3: Mentorship Methods
  // ===========================================================================

  Future<void> fetchMentors({String? q, String? skill, String? topic}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _mentors = await _alumniService.getMentors(q: q, skill: skill, topic: topic);
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchMentorshipRequests() async {
    try {
      _mentorshipRequests = await _alumniService.getMentorshipRequests();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<bool> sendMentorshipRequest({
    required int mentorId,
    required String topic,
    required String message,
  }) async {
    try {
      final req = await _alumniService.sendMentorshipRequest(
        mentorId: mentorId,
        topic: topic,
        message: message,
      );
      _mentorshipRequests.insert(0, req);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> respondToMentorshipRequest({
    required int requestId,
    required String status,
    String? responseMessage,
  }) async {
    try {
      final updated = await _alumniService.respondToMentorshipRequest(
        requestId: requestId,
        status: status,
        responseMessage: responseMessage,
      );
      _mentorshipRequests = _mentorshipRequests.map((r) => r.id == requestId ? updated : r).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // Suggestion 2: Graduation Roster Methods
  // ===========================================================================

  Future<void> fetchGraduationRoster({String? q, int? year}) async {
    _setLoading(true);
    try {
      _rosterRecords = await _alumniService.getGraduationRoster(q: q, year: year);
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<Map<String, dynamic>> autoVerifyPendingAlumni() async {
    _setLoading(true);
    try {
      final res = await _alumniService.autoVerifyPendingAlumni();
      // Refresh directory to reflect newly verified alumni
      await fetchDirectory();
      _setLoading(false);
      return res;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> createAlumnus(Map<String, dynamic> data) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final newAlumnus = await _alumniService.adminCreateAlumnus(data);
      _directory.insert(0, newAlumnus);
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> addRosterRecord(Map<String, dynamic> data) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final newRec = await _alumniService.createRosterRecord(data);
      _rosterRecords.insert(0, newRec);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}


