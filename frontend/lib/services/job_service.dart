import 'api_client.dart';

class JobService {
  final ApiClient _client = ApiClient();

  // ===========================================================================
  // Alumni Endpoints
  // ===========================================================================

  /// Fetches AI-matched jobs personalized for the logged-in alumnus.
  Future<List<Map<String, dynamic>>> getMatchedJobs() async {
    final response = await _client.get('jobs/alumni/matched/');
    List results = response is Map && response.containsKey('results') ? response['results'] : response;
    return List<Map<String, dynamic>>.from(results);
  }

  /// Browses all published jobs.
  Future<List<Map<String, dynamic>>> browseJobs({String? query}) async {
    String endpoint = 'jobs/alumni/browse/';
    if (query != null && query.isNotEmpty) {
      endpoint += '?q=${Uri.encodeComponent(query)}';
    }
    final response = await _client.get(endpoint);
    List results = response is Map && response.containsKey('results') ? response['results'] : response;
    return List<Map<String, dynamic>>.from(results);
  }

  /// Submits an application / expression of interest for a job.
  Future<Map<String, dynamic>> applyToJob(int jobId, {String? coverNote}) async {
    final response = await _client.post(
      'jobs/alumni/apply/$jobId/',
      body: {'cover_note': coverNote ?? ''},
    );
    return response as Map<String, dynamic>;
  }

  // ===========================================================================
  // Admin Endpoints
  // ===========================================================================

  /// Submits raw job advert text for AI extraction (Gemini / NLP).
  Future<Map<String, dynamic>> extractJobFromAdvert(
    String rawText, {
    Map<String, dynamic>? overrides,
  }) async {
    final body = {
      'raw_advert_text': rawText,
      if (overrides != null) ...overrides,
    };
    final response = await _client.post('jobs/admin/vacancies/ai-extract/', body: body);
    return response as Map<String, dynamic>;
  }

  /// Lists all vacancies for admin (with optional status or search filter).
  Future<List<Map<String, dynamic>>> listAdminJobs({String? status, String? query}) async {
    final params = <String>[];
    if (status != null && status.isNotEmpty) params.add('status=${Uri.encodeComponent(status)}');
    if (query != null && query.isNotEmpty) params.add('q=${Uri.encodeComponent(query)}');

    String endpoint = 'jobs/admin/vacancies/';
    if (params.isNotEmpty) endpoint += '?${params.join('&')}';

    final response = await _client.get(endpoint);
    List results = response is Map && response.containsKey('results') ? response['results'] : response;
    return List<Map<String, dynamic>>.from(results);
  }

  /// Publishes a draft job and triggers the AI alumni matching engine.
  Future<Map<String, dynamic>> publishJobAndMatch(int jobId) async {
    final response = await _client.post('jobs/admin/vacancies/$jobId/publish-and-match/');
    return response as Map<String, dynamic>;
  }

  /// Gets matched alumni for a specific job vacancy.
  Future<List<Map<String, dynamic>>> getJobMatches(int jobId) async {
    final response = await _client.get('jobs/admin/vacancies/$jobId/matches/');
    List results = response is Map && response.containsKey('results') ? response['results'] : response;
    return List<Map<String, dynamic>>.from(results);
  }

  /// Gets applications submitted for a specific job.
  Future<List<Map<String, dynamic>>> getJobApplications(int jobId) async {
    final response = await _client.get('jobs/admin/vacancies/$jobId/applications/');
    List results = response is Map && response.containsKey('results') ? response['results'] : response;
    return List<Map<String, dynamic>>.from(results);
  }

  /// Gets high-level job matching analytics.
  Future<Map<String, dynamic>> getJobAnalytics() async {
    final response = await _client.get('jobs/admin/analytics/');
    return response as Map<String, dynamic>;
  }
}
