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
}
