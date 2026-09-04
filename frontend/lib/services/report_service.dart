import '../models/report_model.dart';
import 'api_client.dart';

class ReportService {
  final ApiClient _client = ApiClient();

  Future<ReportSummaryModel> getReportSummary({int? year, String? programme}) async {
    final Map<String, dynamic> params = {};
    if (year != null) params['graduation_year'] = year;
    if (programme != null && programme.isNotEmpty) params['programme'] = programme;

    final response = await _client.get('reports/summary/', queryParams: params);
    return ReportSummaryModel.fromJson(response);
  }

  String getCSVExportUrl({int? year, String? programme}) {
    String url = '${_client.baseUrl}/reports/export/csv/';
    List<String> queryParts = [];
    if (year != null) queryParts.add('graduation_year=$year');
    if (programme != null && programme.isNotEmpty) queryParts.add('programme=${Uri.encodeComponent(programme)}');
    if (queryParts.isNotEmpty) url += '?${queryParts.join('&')}';
    return url;
  }

  String getPDFExportUrl({int? year, String? programme}) {
    String url = '${_client.baseUrl}/reports/export/pdf/';
    List<String> queryParts = [];
    if (year != null) queryParts.add('graduation_year=$year');
    if (programme != null && programme.isNotEmpty) queryParts.add('programme=${Uri.encodeComponent(programme)}');
    if (queryParts.isNotEmpty) url += '?${queryParts.join('&')}';
    return url;
  }
}
