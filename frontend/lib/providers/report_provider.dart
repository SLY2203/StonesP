import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import '../services/api_client.dart';

class ReportProvider with ChangeNotifier {
  final ReportService _reportService = ReportService();

  ReportSummaryModel? _summary;
  int? _selectedYear;
  String? _selectedProgramme;
  bool _isLoading = false;
  String? _errorMessage;

  ReportSummaryModel? get summary => _summary;
  int? get selectedYear => _selectedYear;
  String? get selectedProgramme => _selectedProgramme;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSummary({int? year, String? programme}) async {
    if (year != null) _selectedYear = year == 0 ? null : year;
    if (programme != null) _selectedProgramme = programme.isEmpty ? null : programme;

    _setLoading(true);
    _errorMessage = null;
    try {
      _summary = await _reportService.getReportSummary(
        year: _selectedYear,
        programme: _selectedProgramme,
      );
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  String getCSVExportUrl() {
    return _reportService.getCSVExportUrl(year: _selectedYear, programme: _selectedProgramme);
  }

  String getPDFExportUrl() {
    return _reportService.getPDFExportUrl(year: _selectedYear, programme: _selectedProgramme);
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
