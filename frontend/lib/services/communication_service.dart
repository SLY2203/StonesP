import '../models/communication_model.dart';
import 'api_client.dart';

class CommunicationService {
  final ApiClient _client = ApiClient();

  Future<List<CommunicationModel>> getFeed({String? category, int? targetYear}) async {
    final Map<String, dynamic> params = {};
    if (category != null && category.isNotEmpty && category != 'ALL') {
      params['category'] = category;
    }
    if (targetYear != null) {
      params['target_year'] = targetYear;
    }

    final response = await _client.get('communications/', queryParams: params);
    List results = response is Map && response.containsKey('results') ? response['results'] : response;
    return results.map((item) => CommunicationModel.fromJson(item)).toList();
  }

  Future<CommunicationModel> createCommunication(Map<String, dynamic> data) async {
    final response = await _client.post('communications/', body: data);
    return CommunicationModel.fromJson(response);
  }

  Future<CommunicationModel> postJobVacancy({
    required String title,
    required String company,
    required String description,
    required String location,
    DateTime? applicationDeadline,
    String? applicationLink,
    int? targetGraduationYear,
    String? targetProgramme,
  }) async {
    final Map<String, dynamic> body = {
      'title': title.trim(),
      'content': 'Company: $company\n\n$description',
      'category': 'JOB_VACANCY',
      'location': location.trim(),
    };
    if (applicationDeadline != null) {
      body['application_deadline'] = applicationDeadline.toIso8601String();
    }
    if (applicationLink != null && applicationLink.isNotEmpty) {
      body['external_link'] = applicationLink.trim();
    }
    if (targetGraduationYear != null && targetGraduationYear > 0) {
      body['target_graduation_year'] = targetGraduationYear;
    }
    if (targetProgramme != null && targetProgramme.isNotEmpty) {
      body['target_programme'] = targetProgramme.trim();
    }

    final response = await _client.post('communications/', body: body);
    return CommunicationModel.fromJson(response);
  }

  Future<List<FeedbackItemModel>> getAllFeedbacks({
    String? category,
    String? responseType,
    bool? withNotes,
  }) async {
    final Map<String, dynamic> params = {};
    if (category != null && category.isNotEmpty && category != 'ALL') {
      params['category'] = category;
    }
    if (responseType != null && responseType.isNotEmpty && responseType != 'ALL') {
      params['response_type'] = responseType;
    }
    if (withNotes != null) {
      params['with_notes'] = withNotes ? '1' : '0';
    }

    final response = await _client.get('communications/feedbacks/', queryParams: params);
    List results = response is Map && response.containsKey('results') ? response['results'] : response;
    return results.map((item) => FeedbackItemModel.fromJson(item)).toList();
  }

  Future<Map<String, dynamic>> submitRSVP(int communicationId, String responseType, {String? notes}) async {
    final body = {
      'response_type': responseType,
      'notes': notes ?? '',
    };
    final response = await _client.post('communications/$communicationId/rsvp/', body: body);
    return response as Map<String, dynamic>;
  }

  Future<void> cancelRSVP(int communicationId) async {
    await _client.delete('communications/$communicationId/rsvp/');
  }

  Future<List<dynamic>> getRSVPList(int communicationId) async {
    final response = await _client.get('communications/$communicationId/rsvps/');
    List results = response is Map && response.containsKey('results') ? response['results'] : response;
    return results;
  }

  Future<SystemSurveyModel> submitSystemSurvey({
    required int overallRating,
    int easeOfUseRating = 5,
    int featuresRating = 5,
    int performanceRating = 5,
    String systemAspect = 'GENERAL',
    String? whatWorksWell,
    String? improvementsNeeded,
    bool wouldRecommend = true,
  }) async {
    final body = {
      'overall_rating': overallRating,
      'ease_of_use_rating': easeOfUseRating,
      'features_rating': featuresRating,
      'performance_rating': performanceRating,
      'system_aspect': systemAspect,
      'what_works_well': whatWorksWell ?? '',
      'improvements_needed': improvementsNeeded ?? '',
      'would_recommend': wouldRecommend,
    };
    final response = await _client.post('communications/surveys/', body: body);
    return SystemSurveyModel.fromJson(response);
  }

  Future<List<SystemSurveyModel>> getSystemSurveys() async {
    final response = await _client.get('communications/surveys/');
    List results = response is Map && response.containsKey('results') ? response['results'] : response;
    return results.map((item) => SystemSurveyModel.fromJson(item)).toList();
  }

  Future<Map<String, dynamic>> getSurveyAnalytics() async {
    final response = await _client.get('communications/surveys/analytics/');
    return response as Map<String, dynamic>;
  }

  Future<DepartmentFeedbackModel> submitDepartmentFeedback({
    required String subject,
    required String category,
    required String message,
  }) async {
    final body = {
      'subject': subject.trim(),
      'category': category,
      'message': message.trim(),
    };
    final response = await _client.post('communications/department-feedback/', body: body);
    return DepartmentFeedbackModel.fromJson(response);
  }

  Future<List<DepartmentFeedbackModel>> getDepartmentFeedbacks() async {
    final response = await _client.get('communications/department-feedback/');
    List results = response is Map && response.containsKey('results') ? response['results'] : response;
    return results.map((item) => DepartmentFeedbackModel.fromJson(item)).toList();
  }

  // Objective 4: In-app notifications & read receipts
  Future<void> markCommunicationAsRead(int communicationId) async {
    try {
      await _client.post('communications/$communicationId/read/');
    } catch (_) {}
  }

  Future<Map<String, dynamic>> getInAppNotifications() async {
    final response = await _client.get('communications/notifications/');
    return response as Map<String, dynamic>;
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    await _client.post('communications/notifications/$notificationId/read/');
  }

  Future<void> markAllNotificationsAsRead() async {
    await _client.post('communications/notifications/read-all/');
  }
}

