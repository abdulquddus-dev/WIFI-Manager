// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/cards_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  final String monthKey;
  const DashboardScreen({super.key, required this.monthKey});

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final cards = context.watch<CardsProvider>();
    final auth = context.watch<AuthProvider>();

    final totalExpenses = expenses.getTotalForMonth(monthKey);
    final totalRevenue = cards.getTotalRevenueForMonth(monthKey);
    final profit = totalRevenue - totalExpenses;
    final isProfitable = profit >= 0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          expenses.loadMonth(monthKey);
          cards.loadMonth(monthKey);
        },
        child: CustomScrollView(
          slivers: [
            // AppBar مخصص
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primary, AppTheme.primaryDark],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرحباً، ${auth.currentUser?.name ?? ''}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            formatMonthKey(monthKey),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                          border: const Border.fromBorderSide(
                            BorderSide(color: AppTheme.border),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.wifi, color: AppTheme.accent, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'WiFi Manager',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // بطاقة الملخص الكبيرة
                  _SummaryHeroCard(
                    profit: profit,
                    isProfitable: isProfitable,
                    totalRevenue: totalRevenue,
                    totalExpenses: totalExpenses,
                  ),
                  const SizedBox(height: 16),

                  // بطاقتان صغيرتان
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'الإيرادات',
                          amount: totalRevenue,
                          icon: Icons.trending_up,
                          color: AppTheme.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'المصاريف',
                          amount: totalExpenses,
                          icon: Icons.trending_down,
                          color: AppTheme.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // توزيع الكروت
                  _CardsBreakdown(monthKey: monthKey),
                  const SizedBox(height: 16),

                  // آخر المصاريف
                  _RecentExpenses(monthKey: monthKey),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── بطاقة الملخص الكبيرة ────────────────────────────
class _SummaryHeroCard extends StatelessWidget {
  final double profit;
  final bool isProfitable;
  final double totalRevenue;
  final double totalExpenses;

  const _SummaryHeroCard({
    required this.profit,
    required this.isProfitable,
    required this.totalRevenue,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isProfitable
              ? [AppTheme.profitDark, AppTheme.profitDeep]
              : [AppTheme.lossDark, AppTheme.lossDeep],
        ),
        border: Border.all(
          color: isProfitable
              ? AppTheme.green.withValues(alpha: 0.3)
              : AppTheme.red.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: (isProfitable ? AppTheme.green : AppTheme.red)
                .withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isProfitable ? '✅ الشهر رابح' : '⚠️ الشهر خاسر',
                style: TextStyle(
                  color: isProfitable ? AppTheme.green : AppTheme.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                isProfitable ? Icons.arrow_upward : Icons.arrow_downward,
                color: isProfitable ? AppTheme.green : AppTheme.red,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'صافي الربح / الخسارة',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            '${isProfitable ? '+' : ''}${formatAmount(profit)} ريال',
            style: TextStyle(
              color: isProfitable ? AppTheme.green : AppTheme.red,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // شريط التقدم
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalRevenue > 0
                  ? (totalExpenses / totalRevenue).clamp(0.0, 1.0)
                  : 0,
              backgroundColor: AppTheme.surfaceLight,
              valueColor: AlwaysStoppedAnimation(
                  isProfitable ? AppTheme.green : AppTheme.red),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المصاريف ${totalRevenue > 0 ? ((totalExpenses / totalRevenue) * 100).toStringAsFixed(0) : 0}%',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
              const Text(
                'من الإيرادات',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── بطاقة إحصائية صغيرة ─────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${formatAmount(amount)} ريال',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── توزيع الكروت ─────────────────────────────────────
class _CardsBreakdown extends StatelessWidget {
  final String monthKey;
  const _CardsBreakdown({required this.monthKey});

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<CardsProvider>();
    final counts = cards.getCountsByMonth(monthKey);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الكروت المطبوعة',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'الإجمالي: ${formatAmount(cards.getTotalRevenueForMonth(monthKey))} ريال',
                style: const TextStyle(
                    color: AppTheme.accent, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (counts.isEmpty)
            const Center(
              child: Text('لا توجد كروت مسجلة',
                  style: TextStyle(color: AppTheme.textSecondary)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: counts.entries.map((e) {
                final price = cards.getPriceFor(e.key);
                final total = price * e.value;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'أبو ${e.key}',
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${e.value} كرت',
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 13),
                      ),
                      Text(
                        '${formatAmount(total)} ريال',
                        style: const TextStyle(
                            color: AppTheme.green, fontSize: 11),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ── آخر المصاريف ─────────────────────────────────────
class _RecentExpenses extends StatelessWidget {
  final String monthKey;
  const _RecentExpenses({required this.monthKey});

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final list = expenses.expenses.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'آخر المصاريف',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const Center(
              child: Text('لا توجد مصاريف',
                  style: TextStyle(color: AppTheme.textSecondary)),
            )
          else
            ...list.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.remove_circle_outline,
                                color: AppTheme.red, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.category,
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 13)),
                              Text(e.description,
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '${formatAmount(e.amount)} ريال',
                        style: const TextStyle(
                            color: AppTheme.red,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
