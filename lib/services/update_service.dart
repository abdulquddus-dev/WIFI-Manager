// lib/services/update_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppVersionInfo {
  final String currentVersion;
  final String minVersion;
  final String updateUrl;   // رابط تنزيل الـ APK من GitHub Releases
  final String releaseNotes;
  final bool forceUpdate;

  const AppVersionInfo({
    required this.currentVersion,
    required this.minVersion,
    required this.updateUrl,
    required this.releaseNotes,
    required this.forceUpdate,
  });

  factory AppVersionInfo.fromMap(Map<String, dynamic> map) {
    return AppVersionInfo(
      currentVersion: (map['current_version'] as String?) ?? '1.0.0',
      minVersion: (map['min_version'] as String?) ?? '1.0.0',
      updateUrl: (map['update_url'] as String?) ?? '',
      releaseNotes: (map['release_notes'] as String?) ?? '',
      forceUpdate: (map['force_update'] as bool?) ?? false,
    );
  }
}

class UpdateService {
  static final _db = FirebaseFirestore.instance;

  /// جلب معلومات الإصدار من Firebase
  static Future<AppVersionInfo?> fetchVersionInfo() async {
    try {
      final doc = await _db
          .collection('app_config')
          .doc('version')
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return AppVersionInfo.fromMap(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  /// مقارنة إصدارين
  /// يُرجع true إذا كان [remote] أحدث من [local]
  static bool isNewerVersion(String local, String remote) {
    final l = _parseVersion(local);
    final r = _parseVersion(remote);
    for (int i = 0; i < 3; i++) {
      if (r[i] > l[i]) return true;
      if (r[i] < l[i]) return false;
    }
    return false; // متساويان
  }

  static List<int> _parseVersion(String v) {
    final parts = v.trim().replaceAll('v', '').split('.');
    return List.generate(
      3,
      (i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0,
    );
  }
}
