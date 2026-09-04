import 'package:flutter/material.dart';
import '../models/career_model.dart';
import '../services/career_service.dart';
import '../services/api_client.dart';

class CareerProvider with ChangeNotifier {
  final CareerService _careerService = CareerService();

  List<CareerRecordModel> _careers = [];
  Map<String, dynamic>? _careerStats;
  bool _isLoading = false;
  String? _errorMessage;

  List<CareerRecordModel> get careers => _careers;
  Map<String, dynamic>? get careerStats => _careerStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CareerRecordModel? get currentPosition => _careers.where((c) => c.isCurrent).firstOrNull;

  Future<void> fetchMyCareers() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _careers = await _careerService.getMyCareers();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> addCareerRecord(CareerRecordModel record) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final created = await _careerService.addCareer(record);
      _careers.insert(0, created);
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateCareerRecord(int id, CareerRecordModel record) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final updated = await _careerService.updateCareer(id, record);
      int index = _careers.indexWhere((c) => c.id == id);
      if (index != -1) {
        _careers[index] = updated;
      }
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteCareerRecord(int id) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _careerService.deleteCareer(id);
      _careers.removeWhere((c) => c.id == id);
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchStats() async {
    try {
      _careerStats = await _careerService.getCareerStats();
      notifyListeners();
    } catch (_) {}
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
