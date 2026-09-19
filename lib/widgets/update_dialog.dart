// lib/widgets/update_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/update_provider.dart';
import '../services/update_service.dart';
import '../utils/app_theme.dart';

// ─────────────────────────────────────────────────────
// UpdateChecker — يفحص التحديث تلقائياً عند تسجيل الدخول
// ─────────────────────────────────────────────────────
class UpdateChecker extends StatefulWidget {
  final Widget child;
  const UpdateChecker({super.key, required this.child});

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<UpdateProvider>();
      await provider.checkForUpdate(silent: true);
      if (!mounted) return;
      if (provider.hasUpdate) {
        _showUpdateDialog(context, provider);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _showUpdateDialog(BuildContext context, UpdateProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: !provider.forceUpdate,
      builder: (_) => UpdateDialog(
        info: provider.info!,
        forceUpdate: provider.forceUpdate,
        currentVersion: provider.currentVersion,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// نافذة التحديث
// ─────────────────────────────────────────────────────
class UpdateDialog extends StatelessWidget {
  final AppVersionInfo info;
  final bool forceUpdate;
  final String currentVersion;

  const UpdateDialog({
    super.key,
    required this.info,
    required this.forceUpdate,
    required this.currentVersion,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !forceUpdate,
      child: Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أيقونة التحديث
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.accent, Color(0xFF0066FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.system_update,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),

              // العنوان
              Text(
                forceUpdate ? '⚠️ تحديث إجباري مطلوب' : '🎉 يوجد تحديث جديد!',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // مقارنة الإصدارات
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _VersionBadge(
                    label: 'الحالي',
                    version: currentVersion,
                    color: AppTheme.textSecondary,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.arrow_forward,
                      color: AppTheme.accent,
                      size: 20,
                    ),
                  ),
                  _VersionBadge(
                    label: 'الجديد',
                    version: info.currentVersion,
                    color: AppTheme.accent,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ملاحظات الإصدار
              if (info.releaseNotes.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📋 ما الجديد:',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        info.releaseNotes,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // زر تحديث الآن
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _downloadUpdate(context),
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  label: const Text(
                    'تحديث الآن',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Cairo',
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              // زر لاحقاً (فقط إذا لم يكن إجبارياً)
              if (!forceUpdate) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'لاحقاً',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontFamily: 'Cairo',
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],

              if (forceUpdate) ...[
                const SizedBox(height: 10),
                const Text(
                  'يجب التحديث للمتابعة',
                  style: TextStyle(color: AppTheme.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// فتح رابط تنزيل الـ APK من GitHub مباشرة
  Future<void> _downloadUpdate(BuildContext context) async {
    if (info.updateUrl.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('رابط التحديث غير متاح حالياً'),
            backgroundColor: AppTheme.red,
          ),
        );
      }
      return;
    }

    final uri = Uri.parse(info.updateUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذّر فتح رابط التحديث'),
            backgroundColor: AppTheme.red,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذّر فتح رابط التحديث'),
            backgroundColor: AppTheme.red,
          ),
        );
      }
    }
  }
}

// ── شارة الإصدار ─────────────────────────────────────
class _VersionBadge extends StatelessWidget {
  final String label;
  final String version;
  final Color color;

  const _VersionBadge({
    required this.label,
    required this.version,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            'v$version',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
