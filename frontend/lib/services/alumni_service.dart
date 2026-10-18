import '../models/profile_model.dart';
import '../models/mentorship_model.dart';
import '../models/roster_model.dart';
import 'api_client.dart';

class AlumniService {
  final ApiClient _client = ApiClient();

  Future<AlumniProfileModel> getMyProfile() async {
    final response = await _client.get('alumni/profile/me/');
    return AlumniProfileModel.fromJson(response);
  }

  Future<AlumniProfileModel> updateMyProfile(Map<String, dynamic> data) async {
    final response = await _client.patch('alumni/profile/me/', body: data);
    return AlumniProfileModel.fromJson(response);
  }

  Future<List<AlumniDirectoryItemModel>> getDirectory({
    String? q,
    String? skill,
    int? gradYear,
    String? programme,
    bool? isVerified,
  }) async {
    final Map<String, dynamic> params = {};
    if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
    if (skill != null && skill.trim().isNotEmpty) params['skill'] = skill.trim();
    if (gradYear != null) params['graduation_year'] = gradYear;
    if (programme != null && programme.isNotEmpty) params['programme'] = programme;
    if (isVerified != null) params['is_verified'] = isVerified.toString();

    final response = await _client.get('alumni/directory/', queryParams: params);
    List results = response is Map && response.containsKey('results') ? response['results'] : response;
    return results.map((item) => AlumniDirectoryItemModel.fromJson(item)).toList();
  }

  Future<AlumniProfileModel> getAlumnusDetail(int id) async {
    final response = await _client.get('alumni/directory/$id/');
    return AlumniProfileModel.fromJson(response);
  }

  Future<bool> verifyAlumnus(int userId, bool isVerified) async {
    final response = await _client.post(
      'auth/alumni/$userId/verify/',
      body: {'is_verified': isVerified},
    );
    return response['is_verified'] ?? isVerified;
  }

  // ===========================================================================
  // Suggestion 3: Mentorship APIs
  // ===========================================================================

  Future<List<MentorModel>> getMentors({
    String? q,
    String? skill,
    String? topic,
  }) async {
    final Map<String, dynamic> params = {};
    if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
    if (skill != null && skill.trim().isNotEmpty) params['skill'] = skill.trim();
    if (topic != null && topic.trim().isNotEmpty) params['topic'] = topic.trim();

    final response = await _client.get('alumni/mentors/', queryParams: params);
    List results = response is Map && response.containsKey('results') ? response['results'] : response;
    return results.map((item) => MentorModel.fromJson(item)).toList();
  }

  Future<List<MentorshipRequestModel>> getMentorshipRequests() async {
    final response = await _client.get('alumni/mentorship/requests/');
    List results = response is Map && response.containsKey('results') ? response['results'] : response;
    return results.map((item) => MentorshipRequestModel.fromJson(item)).toList();
  }

  Future<MentorshipRequestModel> sendMentorshipRequest({
    required int mentorId,
    required String topic,
    required String message,
  }) async {
    final response = await _client.post(
      'alumni/mentorship/requests/',
      body: {
        'mentor_id': mentorId,
        'topic': topic,
        'message': message,
      },
    );
    return MentorshipRequestModel.fromJson(response);
  }

  Future<MentorshipRequestModel> respondToMentorshipRequest({
    required int requestId,
    required String status,
    String? responseMessage,
  }) async {
    final response = await _client.patch(
      'alumni/mentorship/requests/$requestId/respond/',
      body: {
        'status': status,
        if (responseMessage != null) 'response_message': responseMessage,
      },
    );
    return MentorshipRequestModel.fromJson(response);
  }

  // ===========================================================================
  // Suggestion 2: Graduation Roster & Auto-Verification APIs
  // ===========================================================================

  Future<List<GraduationRosterModel>> getGraduationRoster({String? q, int? year}) async {
    final Map<String, dynamic> params = {};
    if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
    if (year != null) params['graduation_year'] = year;

    final response = await _client.get('alumni/roster/', queryParams: params);
    List results = response is Map && response.containsKey('results') ? response['results'] : response;
    return results.map((item) => GraduationRosterModel.fromJson(item)).toList();
  }

  Future<Map<String, dynamic>> autoVerifyPendingAlumni() async {
    final response = await _client.post('alumni/roster/auto-verify-pending/');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> batchUploadRoster({String? csvText, List<Map<String, dynamic>>? records}) async {
    final response = await _client.post(
      'alumni/roster/batch/',
      body: {
        if (csvText != null) 'roster_csv': csvText,
        if (records != null) 'records': records,
      },
    );
    return response as Map<String, dynamic>;
  }
}

