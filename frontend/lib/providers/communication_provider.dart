import 'package:flutter/material.dart';
import '../models/communication_model.dart';
import '../services/communication_service.dart';
import '../services/api_client.dart';

class CommunicationProvider with ChangeNotifier {
  final CommunicationService _commService = CommunicationService();

  List<CommunicationModel> _feed = [];
  String _selectedCategory = 'ALL';
  int? _targetYear;
  bool _isLoading = false;
  String? _errorMessage;

  List<CommunicationModel> get feed => _feed;
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

  Future<bool> submitRSVP(int communicationId, String responseType, {String? notes}) async {
    try {
      await _commService.submitRSVP(communicationId, responseType, notes: notes);
      // Refresh feed in background to update attendance counters and my RSVP badge
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

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
