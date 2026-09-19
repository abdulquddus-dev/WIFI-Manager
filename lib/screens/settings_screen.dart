// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cards_provider.dart';
import '../providers/update_provider.dart';
import '../models/card_entry_model.dart';
import '../utils/app_theme.dart';
import '../widgets/update_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final update = context.watch<UpdateProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        actions: [
          if (update.hasUpdate)
            Container(
              margin: const EdgeInsets.only(left: 12, right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.new_releases, color: AppTheme.accent, size: 14),
                  SizedBox(width: 4),
                  Text('تحديث',
                      style: TextStyle(color: AppTheme.accent, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader(title: 'الحساب'),
          _UserInfoCard(user: auth.currentUser),
          const SizedBox(height: 20),

          const _SectionHeader(title: 'أسعار الكروت'),
          _CardPricesSection(),
          const SizedBox(height: 20),

          // ── قسم التحديثات ──────────────────────────────
          const _SectionHeader(title: 'التحديثات'),
          _UpdateCard(update: update),
          const SizedBox(height: 20),

          // ── تسجيل الخروج ───────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.surface,
                    title: const Text('تسجيل الخروج',
                        style: TextStyle(color: AppTheme.textPrimary)),
                    content: const Text('هل تريد تسجيل الخروج؟',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('خروج',
                            style: TextStyle(color: AppTheme.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  context.read<AuthProvider>().signOut();
                }
              },
              icon: const Icon(Icons.logout, color: AppTheme.red),
              label: const Text('تسجيل الخروج',
                  style: TextStyle(color: AppTheme.red, fontFamily: 'Cairo')),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 30),

          const Center(
            child: Text(
              'WiFi Manager v$kCurrentAppVersion\nجميع الحقوق محفوظة',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── بطاقة التحديث ────────────────────────────────────
class _UpdateCard extends StatelessWidget {
  final UpdateProvider update;
  const _UpdateCard({required this.update});

  @override
  Widget build(BuildContext context) {
    final hasUpdate = update.hasUpdate;
    final color = hasUpdate ? AppTheme.accent : AppTheme.green;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasUpdate
              ? AppTheme.accent.withValues(alpha: 0.4)
              : AppTheme.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasUpdate ? Icons.system_update : Icons.check_circle_outline,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasUpdate
                          ? 'يوجد تحديث جديد!'
                          : 'التطبيق محدّث',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      hasUpdate
                          ? 'الإصدار ${update.info?.currentVersion} متاح'
                          : 'الإصدار v${update.currentVersion} — آخر إصدار',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // زر الفحص / التحديث
              update.checking
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.accent),
                    )
                  : hasUpdate
                      ? ElevatedButton(
                          onPressed: () => showDialog(
                            context: context,
                            barrierDismissible: !update.forceUpdate,
                            builder: (_) => UpdateDialog(
                              info: update.info!,
                              forceUpdate: update.forceUpdate,
                              currentVersion: update.currentVersion,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(
                                fontFamily: 'Cairo', fontSize: 13),
                          ),
                          child: const Text('تحديث'),
                        )
                      : TextButton(
                          onPressed: () =>
                              update.checkForUpdate(silent: false),
                          child: const Text('فحص',
                              style: TextStyle(
                                  color: AppTheme.accent,
                                  fontFamily: 'Cairo')),
                        ),
            ],
          ),

          // ملاحظات الإصدار الحالي إذا وُجدت
          if (hasUpdate && update.info!.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                update.info!.releaseNotes,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── باقي مكوّنات الإعدادات ──────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5)),
    );
  }
}

class _UserInfoCard extends StatelessWidget {
  final dynamic user;
  const _UserInfoCard({required this.user});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
            radius: 28,
            child: Text(
              user?.name?.isNotEmpty == true
                  ? user!.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.name ?? 'غير محدد',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Text(user?.email ?? '',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: user?.isAdmin == true
                      ? AppTheme.gold.withValues(alpha: 0.15)
                      : AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user?.isAdmin == true ? '👑 مدير' : '👤 موظف',
                  style: TextStyle(
                      color: user?.isAdmin == true
                          ? AppTheme.gold
                          : AppTheme.accent,
                      fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardPricesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cards = context.watch<CardsProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: CardDenominations.values.asMap().entries.map((e) {
          final d = e.value;
          final price = cards.getPriceFor(d);
          final isLast = e.key == CardDenominations.values.length - 1;
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(
                      bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('كرت أبو $d',
                    style:
                        const TextStyle(color: AppTheme.textPrimary)),
                Row(
                  children: [
                    Text('${formatAmount(price)} ريال',
                        style: const TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppTheme.textSecondary, size: 18),
                      onPressed: () =>
                          _showEditPriceDialog(context, d, price),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showEditPriceDialog(
      BuildContext context, int denomination, double currentPrice) {
    final ctrl =
        TextEditingController(text: currentPrice.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('سعر كرت أبو $denomination',
            style: const TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'السعر (ريال)',
            suffixText: 'ريال',
            suffixStyle: TextStyle(color: AppTheme.textSecondary),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final price = double.tryParse(ctrl.text);
              if (price != null && price > 0) {
                await context
                    .read<CardsProvider>()
                    .updatePrice(denomination, price);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ',
                style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }
}
