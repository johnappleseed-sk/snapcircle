import 'package:flutter/foundation.dart';

import '../data/activity_repository.dart';
import '../models/activity_model.dart';

class ActivityProvider extends ChangeNotifier {
  final ActivityRepository _repository;

  ActivityModel? _activity;
  bool _isLoading = false;
  String? _errorMessage;

  ActivityProvider({ActivityRepository? repository})
    : _repository = repository ?? ActivityRepository();

  ActivityModel? get activity => _activity;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchActivity({bool refresh = false}) async {
    if (_isLoading || (!refresh && _activity != null)) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activity = await _repository.getActivity();
    } on ActivityException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load activity.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
