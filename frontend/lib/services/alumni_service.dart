import '../models/profile_model.dart';
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
    int? gradYear,
    String? programme,
    bool? isVerified,
  }) async {
    final Map<String, dynamic> params = {};
    if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
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
}
