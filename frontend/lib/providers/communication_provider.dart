import 'package:flutter/material.dart';
import '../models/communication_model.dart';
import '../services/communication_service.dart';
import '../services/api_client.dart';

class CommunicationProvider with ChangeNotifier {
  final CommunicationService _commService = CommunicationService();

  List<CommunicationModel> _feed = [];
  List<FeedbackItemModel> _feedbacks = [];
  List<SystemSurveyModel> _surveys = [];
  Map<String, dynamic>? _surveyAnalytics;
  List<DepartmentFeedbackModel> _departmentFeedbacks = [];
  String _selectedCategory = 'ALL';
  int? _targetYear;
  bool _isLoading = false;
  String? _errorMessage;

  List<CommunicationModel> get feed => _feed;
  List<FeedbackItemModel> get feedbacks => _feedbacks;
  List<SystemSurveyModel> get surveys => _surveys;
  Map<String, dynamic>? get surveyAnalytics => _surveyAnalytics;
  List<DepartmentFeedbackModel> get departmentFeedbacks => _departmentFeedbacks;
  String get selectedCategory => _selectedCategory;
  int? get targetYear => _targetYear;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;


  Future<void> fetchFeed({String? category, int? targetYear}) async {
    if (category != null) _selectedCategory = category;
    if (targetYear != null) _targetYear = targetYear == 0 ? null : targetYear;

    _setLoading(true);
    _errorMessage = null;
    try {
      _feed = await _commService.getFeed(
        category: _selectedCategory,
        targetYear: _targetYear,
      );
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchFeedbacks({String? category, String? responseType, bool? withNotes}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _feedbacks = await _commService.getAllFeedbacks(
        category: category,
        responseType: responseType,
        withNotes: withNotes,
      );
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> createBroadcast(Map<String, dynamic> data) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final created = await _commService.createCommunication(data);
      _feed.insert(0, created);
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    }
  }

  Future<bool> postJobVacancy({
    required String title,
    required String company,
    required String description,
    required String location,
    DateTime? applicationDeadline,
    String? applicationLink,
    int? targetGraduationYear,
    String? targetProgramme,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final job = await _commService.postJobVacancy(
        title: title,
        company: company,
        description: description,
        location: location,
        applicationDeadline: applicationDeadline,
        applicationLink: applicationLink,
        targetGraduationYear: targetGraduationYear,
        targetProgramme: targetProgramme,
      );
      _feed.insert(0, job);
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

  Future<bool> submitRSVP(int communicationId, String responseType, {String? notes}) async {
    try {
      await _commService.submitRSVP(communicationId, responseType, notes: notes);
      await fetchFeed();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelRSVP(int communicationId) async {
    try {
      await _commService.cancelRSVP(communicationId);
      await fetchFeed();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchSurveys() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _surveys = await _commService.getSystemSurveys();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchSurveyAnalytics() async {
    try {
      _surveyAnalytics = await _commService.getSurveyAnalytics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching survey analytics: $e');
    }
  }

  Future<bool> submitSystemSurvey({
    required int overallRating,
    int easeOfUseRating = 5,
    int featuresRating = 5,
    int performanceRating = 5,
    String systemAspect = 'GENERAL',
    String? whatWorksWell,
    String? improvementsNeeded,
    bool wouldRecommend = true,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final survey = await _commService.submitSystemSurvey(
        overallRating: overallRating,
        easeOfUseRating: easeOfUseRating,
        featuresRating: featuresRating,
        performanceRating: performanceRating,
        systemAspect: systemAspect,
        whatWorksWell: whatWorksWell,
        improvementsNeeded: improvementsNeeded,
        wouldRecommend: wouldRecommend,
      );
      _surveys.insert(0, survey);
      await fetchSurveyAnalytics();
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

  Future<void> fetchDepartmentFeedbacks() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _departmentFeedbacks = await _commService.getDepartmentFeedbacks();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> submitDepartmentFeedback({
    required String subject,
    required String category,
    required String message,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final fb = await _commService.submitDepartmentFeedback(
        subject: subject,
        category: category,
        message: message,
      );
      _departmentFeedbacks.insert(0, fb);
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

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}

