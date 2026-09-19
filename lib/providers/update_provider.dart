// lib/providers/update_provider.dart
import 'package:flutter/material.dart';
import '../services/update_service.dart';

// ── الإصدار الحالي للتطبيق — غيّره عند كل إصدار ──────
const String kCurrentAppVersion = '1.0.0';

class UpdateProvider extends ChangeNotifier {
  AppVersionInfo? _info;
  bool _checking = false;
  bool _hasUpdate = false;
  bool _forceUpdate = false;
  String? _error;

  AppVersionInfo? get info => _info;
  bool get checking => _checking;
  bool get hasUpdate => _hasUpdate;
  bool get forceUpdate => _forceUpdate;
  String? get error => _error;
  String get currentVersion => kCurrentAppVersion;

  /// يُستدعى عند فتح التطبيق أو من شاشة الإعدادات
  Future<void> checkForUpdate({bool silent = true}) async {
    _checking = true;
    _error = null;
    if (!silent) notifyListeners();

    try {
      _info = await UpdateService.fetchVersionInfo();
      if (_info != null) {
        _hasUpdate = UpdateService.isNewerVersion(
            kCurrentAppVersion, _info!.currentVersion);
        _forceUpdate = _hasUpdate && _info!.forceUpdate;
      }
    } catch (e) {
      _error = 'تعذّر الاتصال بالخادم';
    }

    _checking = false;
    notifyListeners();
  }
}
