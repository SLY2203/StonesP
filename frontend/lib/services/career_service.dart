import '../models/career_model.dart';
import 'api_client.dart';

class CareerService {
  final ApiClient _client = ApiClient();

  Future<List<CareerRecordModel>> getMyCareers() async {
    final response = await _client.get('careers/me/');
    List results = response is Map && response.containsKey('results') ? response['results'] : response;
    return results.map((item) => CareerRecordModel.fromJson(item)).toList();
  }

  Future<CareerRecordModel> addCareer(CareerRecordModel record) async {
    final response = await _client.post('careers/me/', body: record.toJson());
    return CareerRecordModel.fromJson(response);
  }

  Future<CareerRecordModel> updateCareer(int id, CareerRecordModel record) async {
    final response = await _client.put('careers/me/$id/', body: record.toJson());
    return CareerRecordModel.fromJson(response);
  }

  Future<void> deleteCareer(int id) async {
    await _client.delete('careers/me/$id/');
  }

  Future<Map<String, dynamic>> getCareerStats() async {
    final response = await _client.get('careers/stats/');
    return response as Map<String, dynamic>;
  }

  // Objective 2: Tracer Survey API calls
  Future<Map<String, dynamic>?> getMyTracerSurvey() async {
    try {
      final response = await _client.get('careers/tracer-survey/me/');
      return response as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> submitTracerSurvey(Map<String, dynamic> data) async {
    final response = await _client.post('careers/tracer-survey/me/', body: data);
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTracerSurveyAnalytics() async {
    final response = await _client.get('careers/tracer-survey/analytics/');
    return response as Map<String, dynamic>;
  }
}

