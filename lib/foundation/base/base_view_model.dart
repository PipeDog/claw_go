import 'package:flutter/foundation.dart';

/// ViewModel 基类。
///
/// 统一封装加载态和错误信息，避免每个业务 ViewModel 重复维护相同字段。
class BaseViewModel extends ChangeNotifier {
  bool _loading = false;
  String? _errorMessage;

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  @protected
  void setLoading(bool value) {
    if (_loading == value) {
      return;
    }
    _loading = value;
    notifyListeners();
  }

  @protected
  void setErrorMessage(String? value) {
    if (_errorMessage == value) {
      return;
    }
    _errorMessage = value;
    notifyListeners();
  }

  @protected
  void clearError() {
    setErrorMessage(null);
  }
}
