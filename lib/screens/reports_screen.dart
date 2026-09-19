// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../providers/cards_provider.dart';
import '../providers/debt_provider.dart';
import '../services/hive_service.dart';
import '../utils/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  final String currentMonthKey;
  const ReportsScreen({super.key, required this.currentMonthKey});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير والإحصائيات'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'الشهر الحالي'),
            Tab(text: 'مقارنة الأشهر'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CurrentMonthReport(monthKey: widget.currentMonthKey),
          _MonthComparisonReport(currentMonthKey: widget.currentMonthKey),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// تقرير الشهر الحالي
// ─────────────────────────────────────────────────────
class _CurrentMonthReport extends StatefulWidget {
  final String monthKey;
  const _CurrentMonthReport({required this.monthKey});
  @override
  State<_CurrentMonthReport> createState() => _CurrentMonthReportState();
}

class _CurrentMonthReportState extends State<_CurrentMonthReport> {
  int? _touchedPieIndex;

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final cards = context.watch<CardsProvider>();
    final debts = context.watch<DebtProvider>();

    final totalExpenses = expenses.getTotalForMonth(widget.monthKey);
    // الديون "لي" غير المسددة = خصم من الأرباح
    final pendingDebts = debts.debtsForMe
        .fold(0.0, (s, d) => s + d.remainingAmount);
    final totalRevenue = cards.getTotalRevenueForMonth(widget.monthKey);
    // الربح = إيرادات - مصاريف - ديون معلقة علينا
    final netProfit = totalRevenue - totalExpenses - pendingDebts;
    final isProfitable = netProfit >= 0;

    final categoryTotals = expenses.getCategoryTotals(widget.monthKey);
    final cardCounts = cards.getCountsByMonth(widget.monthKey);

    // نسب الأعمال
    final profitMargin =
        totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0.0;
    final expenseRatio =
        totalRevenue > 0 ? (totalExpenses / totalRevenue) * 100 : 0.0;
    final debtRatio =
        totalRevenue > 0 ? (pendingDebts / totalRevenue) * 100 : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── بطاقة الملخص المالي الرئيسية ──────────────
          _FinancialSummaryCard(
            totalRevenue: totalRevenue,
            totalExpenses: totalExpenses,
            pendingDebts: pendingDebts,
            netProfit: netProfit,
            isProfitable: isProfitable,
            profitMargin: profitMargin,
          ),
          const SizedBox(height: 16),

          // ── مؤشرات الأداء (KPIs) ──────────────────────
          const _SectionTitle(title: '📊 مؤشرات الأداء'),
          const SizedBox(height: 10),
          _KpiGrid(
            profitMargin: profitMargin,
            expenseRatio: expenseRatio,
            debtRatio: debtRatio,
            isProfitable: isProfitable,
          ),
          const SizedBox(height: 16),

          // ── شريط توزيع الدخل ─────────────────────────
          if (totalRevenue > 0) ...[
            const _SectionTitle(title: '📈 توزيع الإيرادات'),
            const SizedBox(height: 10),
            _RevenueDistributionBar(
              totalRevenue: totalRevenue,
              totalExpenses: totalExpenses,
              pendingDebts: pendingDebts,
              netProfit: netProfit,
            ),
            const SizedBox(height: 16),
          ],

          // ── رسم دائري للمصاريف ────────────────────────
          if (categoryTotals.isNotEmpty) ...[
            const _SectionTitle(title: '💸 توزيع المصاريف'),
            const SizedBox(height: 10),
            _InteractivePieChart(
              categoryTotals: categoryTotals,
              touchedIndex: _touchedPieIndex,
              onTouch: (i) => setState(() => _touchedPieIndex = i),
            ),
            const SizedBox(height: 16),
          ],

          // ── رسم بياني الكروت ──────────────────────────
          if (cardCounts.isNotEmpty) ...[
            const _SectionTitle(title: '🎴 إيرادات الكروت'),
            const SizedBox(height: 10),
            _CardsRevenueChart(cardCounts: cardCounts, cards: cards),
            const SizedBox(height: 16),
          ],

          // ── ملاحظة الديون ─────────────────────────────
          if (pendingDebts > 0)
            _DebtWarningCard(pendingDebts: pendingDebts),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ── بطاقة الملخص المالي ─────────────────────────────
class _FinancialSummaryCard extends StatelessWidget {
  final double totalRevenue, totalExpenses, pendingDebts, netProfit;
  final bool isProfitable;
  final double profitMargin;

  const _FinancialSummaryCard({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.pendingDebts,
    required this.netProfit,
    required this.isProfitable,
    required this.profitMargin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                .withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان والحالة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isProfitable ? '✅ شهر رابح' : '⚠️ شهر خاسر',
                style: TextStyle(
                  color: isProfitable ? AppTheme.green : AppTheme.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isProfitable ? AppTheme.green : AppTheme.red)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${profitMargin.toStringAsFixed(1)}% هامش ربح',
                  style: TextStyle(
                    color: isProfitable ? AppTheme.green : AppTheme.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // صافي الربح الكبير
          Text(
            '${isProfitable ? '+' : ''}${formatAmount(netProfit)} ريال',
            style: TextStyle(
              color: isProfitable ? AppTheme.green : AppTheme.red,
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text('صافي الربح / الخسارة',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),

          // الأرقام التفصيلية
          _FinRow(label: 'الإيرادات الإجمالية',
              value: totalRevenue, color: AppTheme.green, prefix: '+'),
          const SizedBox(height: 6),
          _FinRow(label: 'المصاريف',
              value: totalExpenses, color: AppTheme.red, prefix: '-'),
          if (pendingDebts > 0) ...[
            const SizedBox(height: 6),
            _FinRow(label: 'ديون معلقة (خصم)',
                value: pendingDebts, color: Colors.orange, prefix: '-'),
          ],
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2A4A6A), height: 1),
          const SizedBox(height: 12),
          _FinRow(
            label: 'الصافي',
            value: netProfit.abs(),
            color: isProfitable ? AppTheme.green : AppTheme.red,
            prefix: isProfitable ? '=' : '= -',
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _FinRow extends StatelessWidget {
  final String label, prefix;
  final double value;
  final Color color;
  final bool isBold;
  const _FinRow({
    required this.label,
    required this.value,
    required this.color,
    required this.prefix,
    this.isBold = false,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: isBold ? 14 : 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text('$prefix ${formatAmount(value)} ريال',
            style: TextStyle(
                color: color,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                fontSize: isBold ? 16 : 13)),
      ],
    );
  }
}

// ── مؤشرات الأداء KPIs ──────────────────────────────
class _KpiGrid extends StatelessWidget {
  final double profitMargin, expenseRatio, debtRatio;
  final bool isProfitable;
  const _KpiGrid({
    required this.profitMargin,
    required this.expenseRatio,
    required this.debtRatio,
    required this.isProfitable,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: 'هامش الربح',
                value: '${profitMargin.toStringAsFixed(1)}%',
                subtitle: profitMargin >= 30
                    ? 'ممتاز'
                    : profitMargin >= 10
                        ? 'جيد'
                        : 'ضعيف',
                color: profitMargin >= 30
                    ? AppTheme.green
                    : profitMargin >= 10
                        ? AppTheme.gold
                        : AppTheme.red,
                icon: Icons.trending_up,
                progress: (profitMargin / 100).clamp(0.0, 1.0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                title: 'نسبة المصاريف',
                value: '${expenseRatio.toStringAsFixed(1)}%',
                subtitle: expenseRatio <= 50
                    ? 'ممتاز'
                    : expenseRatio <= 70
                        ? 'مقبول'
                        : 'مرتفع',
                color: expenseRatio <= 50
                    ? AppTheme.green
                    : expenseRatio <= 70
                        ? AppTheme.gold
                        : AppTheme.red,
                icon: Icons.pie_chart_outline,
                progress: (expenseRatio / 100).clamp(0.0, 1.0),
                invertColor: true,
              ),
            ),
          ],
        ),
        if (debtRatio > 0) ...[
          const SizedBox(height: 10),
          _KpiCard(
            title: 'نسبة الديون المعلقة',
            value: '${debtRatio.toStringAsFixed(1)}%',
            subtitle: 'من الإيرادات',
            color: Colors.orange,
            icon: Icons.handshake_outlined,
            progress: (debtRatio / 100).clamp(0.0, 1.0),
            invertColor: true,
          ),
        ],
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title, value, subtitle;
  final Color color;
  final IconData icon;
  final double progress;
  final bool invertColor;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.progress,
    this.invertColor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(subtitle,
                    style: TextStyle(color: color, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.surfaceLight,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── شريط توزيع الإيرادات ─────────────────────────────
class _RevenueDistributionBar extends StatelessWidget {
  final double totalRevenue, totalExpenses, pendingDebts, netProfit;
  const _RevenueDistributionBar({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.pendingDebts,
    required this.netProfit,
  });

  @override
  Widget build(BuildContext context) {
    final expensePct = totalRevenue > 0 ? totalExpenses / totalRevenue : 0.0;
    final debtPct = totalRevenue > 0 ? pendingDebts / totalRevenue : 0.0;
    final profitPct = (1 - expensePct - debtPct).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // الشريط
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 28,
              child: Row(
                children: [
                  if (expensePct > 0)
                    Flexible(
                      flex: (expensePct * 1000).toInt(),
                      child: Container(
                        color: AppTheme.red,
                        child: const Center(
                          child: Text('مصاريف',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  if (debtPct > 0)
                    Flexible(
                      flex: (debtPct * 1000).toInt(),
                      child: Container(
                        color: Colors.orange,
                        child: const Center(
                          child: Text('ديون',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  if (profitPct > 0)
                    Flexible(
                      flex: (profitPct * 1000).toInt(),
                      child: Container(
                        color: AppTheme.green,
                        child: const Center(
                          child: Text('ربح',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // المفاتيح مع النسب
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DistLegend(
                  color: AppTheme.red,
                  label: 'مصاريف',
                  pct: expensePct * 100,
                  value: totalExpenses),
              if (pendingDebts > 0)
                _DistLegend(
                    color: Colors.orange,
                    label: 'ديون',
                    pct: debtPct * 100,
                    value: pendingDebts),
              _DistLegend(
                  color: AppTheme.green,
                  label: 'ربح',
                  pct: profitPct * 100,
                  value: netProfit.abs()),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistLegend extends StatelessWidget {
  final Color color;
  final String label;
  final double pct, value;
  const _DistLegend(
      {required this.color,
      required this.label,
      required this.pct,
      required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
        Text('${pct.toStringAsFixed(1)}%',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        Text('${formatAmount(value)} ريال',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }
}

// ── رسم دائري تفاعلي ─────────────────────────────────
class _InteractivePieChart extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final int? touchedIndex;
  final ValueChanged<int?> onTouch;

  const _InteractivePieChart({
    required this.categoryTotals,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppTheme.red, AppTheme.accent, AppTheme.gold,
      AppTheme.green, Colors.purple, Colors.orange,
      Colors.teal, Colors.pink, Colors.indigo,
    ];
    final entries = categoryTotals.entries.toList();
    final total = entries.fold(0.0, (s, e) => s + e.value);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            onTouch(null);
                            return;
                          }
                          onTouch(response
                              .touchedSection!.touchedSectionIndex);
                        },
                      ),
                      sections: entries.asMap().entries.map((e) {
                        final isTouched = touchedIndex == e.key;
                        final pct = (e.value.value / total * 100);
                        return PieChartSectionData(
                          value: e.value.value,
                          color: colors[e.key % colors.length],
                          title: isTouched
                              ? '${pct.toStringAsFixed(1)}%'
                              : '${pct.toStringAsFixed(0)}%',
                          titleStyle: TextStyle(
                            color: Colors.white,
                            fontSize: isTouched ? 14 : 11,
                            fontWeight: FontWeight.bold,
                          ),
                          radius: isTouched ? 90 : 75,
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 35,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // أسطورة جانبية
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entries.asMap().entries.map((e) {
                    final isSelected = touchedIndex == e.key;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 14 : 10,
                            height: isSelected ? 14 : 10,
                            decoration: BoxDecoration(
                              color: colors[e.key % colors.length],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            e.value.key,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                              fontSize: isSelected ? 12 : 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // تفاصيل العنصر المحدد
          if (touchedIndex != null &&
              touchedIndex! < entries.length) ...[
            const SizedBox(height: 12),
            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entries[touchedIndex!].key,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  '${formatAmount(entries[touchedIndex!].value)} ريال (${(entries[touchedIndex!].value / total * 100).toStringAsFixed(1)}%)',
                  style: TextStyle(
                    color: colors[touchedIndex! % colors.length],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── رسم بياني كروت ───────────────────────────────────
class _CardsRevenueChart extends StatefulWidget {
  final Map<int, int> cardCounts;
  final CardsProvider cards;
  const _CardsRevenueChart({required this.cardCounts, required this.cards});
  @override
  State<_CardsRevenueChart> createState() => _CardsRevenueChartState();
}

class _CardsRevenueChartState extends State<_CardsRevenueChart> {
  int? _touchedBar;

  @override
  Widget build(BuildContext context) {
    final entries = widget.cardCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (entries.isEmpty) return const SizedBox();

    final revenues = entries
        .map((e) => widget.cards.getPriceFor(e.key) * e.value)
        .toList();
    final maxVal = revenues.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.25,
                barTouchData: BarTouchData(
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.spot == null) {
                      setState(() => _touchedBar = null);
                      return;
                    }
                    setState(() => _touchedBar =
                        response.spot!.spot.x.toInt());
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.surfaceLight,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${formatAmount(rod.toY)} ريال',
                        const TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo'),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final i = val.toInt();
                        if (i < entries.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'أبو\n${entries[i].key}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 9),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 36,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (val, meta) => Text(
                        formatAmount(val),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 9),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppTheme.border, strokeWidth: 1),
                  getDrawingVerticalLine: (_) =>
                      const FlLine(color: Colors.transparent),
                ),
                borderData: FlBorderData(show: false),
                barGroups: entries.asMap().entries.map((e) {
                  final isTouched = _touchedBar == e.key;
                  final revenue = revenues[e.key];
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: revenue,
                        gradient: LinearGradient(
                          colors: isTouched
                              ? [AppTheme.gold, AppTheme.accent]
                              : [AppTheme.accent, AppTheme.green],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: isTouched ? 22 : 18,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          // تفاصيل أسفل الرسم
          if (_touchedBar != null && _touchedBar! < entries.length) ...[
            const SizedBox(height: 12),
            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('كرت أبو ${entries[_touchedBar!].key}',
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold)),
                Text(
                  '${entries[_touchedBar!].value} كرت × '
                  '${formatAmount(widget.cards.getPriceFor(entries[_touchedBar!].key))} ريال'
                  ' = ${formatAmount(revenues[_touchedBar!])} ريال',
                  style: const TextStyle(
                      color: AppTheme.accent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── تحذير الديون ─────────────────────────────────────
class _DebtWarningCard extends StatelessWidget {
  final double pendingDebts;
  const _DebtWarningCard({required this.pendingDebts});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orange, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ديون معلقة مؤثرة على الأرباح',
                    style: TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold)),
                Text(
                  'تم خصم ${formatAmount(pendingDebts)} ريال من صافي الأرباح بسبب ديون لم تُسدد بعد',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// مقارنة الأشهر
// ─────────────────────────────────────────────────────
class _MonthComparisonReport extends StatefulWidget {
  final String currentMonthKey;
  const _MonthComparisonReport({required this.currentMonthKey});
  @override
  State<_MonthComparisonReport> createState() =>
      _MonthComparisonReportState();
}

class _MonthComparisonReportState
    extends State<_MonthComparisonReport> {
  String? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    final allMonths = HiveService.getAllMonthKeys()
        .where((m) => m != widget.currentMonthKey)
        .toList();

    if (allMonths.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 60, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text('لا توجد بيانات لأشهر سابقة',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    final expenses = context.watch<ExpenseProvider>();
    final cards = context.watch<CardsProvider>();
    final debts = context.watch<DebtProvider>();

    final cExp = expenses.getTotalForMonth(widget.currentMonthKey);
    final cRev = cards.getTotalRevenueForMonth(widget.currentMonthKey);
    final cDebt = debts.debtsForMe
        .fold(0.0, (s, d) => s + d.remainingAmount);
    final cProfit = cRev - cExp - cDebt;

    final pExp = _selectedMonth != null
        ? expenses.getTotalForMonth(_selectedMonth!)
        : 0.0;
    final pRev = _selectedMonth != null
        ? cards.getTotalRevenueForMonth(_selectedMonth!)
        : 0.0;
    final pProfit = pRev - pExp;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedMonth,
            dropdownColor: AppTheme.surfaceLight,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontFamily: 'Cairo'),
            decoration: const InputDecoration(
              labelText: 'اختر شهراً للمقارنة',
              prefixIcon:
                  Icon(Icons.calendar_month, color: AppTheme.accent),
            ),
            items: allMonths
                .map((m) => DropdownMenuItem(
                    value: m, child: Text(formatMonthKey(m))))
                .toList(),
            onChanged: (v) => setState(() => _selectedMonth = v),
          ),
          const SizedBox(height: 20),

          if (_selectedMonth != null) ...[
            // جدول المقارنة الاحترافي
            _ProfessionalCompTable(
              currentMonthKey: widget.currentMonthKey,
              prevMonthKey: _selectedMonth!,
              cRev: cRev, cExp: cExp, cDebt: cDebt, cProfit: cProfit,
              pRev: pRev, pExp: pExp, pProfit: pProfit,
            ),
            const SizedBox(height: 16),

            // رسم بياني للمقارنة
            _CompBarChart(
              currentMonthKey: widget.currentMonthKey,
              prevMonthKey: _selectedMonth!,
              cRev: cRev, cExp: cExp, cProfit: cProfit,
              pRev: pRev, pExp: pExp, pProfit: pProfit,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfessionalCompTable extends StatelessWidget {
  final String currentMonthKey, prevMonthKey;
  final double cRev, cExp, cDebt, cProfit;
  final double pRev, pExp, pProfit;

  const _ProfessionalCompTable({
    required this.currentMonthKey, required this.prevMonthKey,
    required this.cRev, required this.cExp,
    required this.cDebt, required this.cProfit,
    required this.pRev, required this.pExp, required this.pProfit,
  });

  @override
  Widget build(BuildContext context) {
    final cMargin = cRev > 0 ? (cProfit / cRev) * 100 : 0.0;
    final pMargin = pRev > 0 ? (pProfit / pRev) * 100 : 0.0;
    final marginDiff = cMargin - pMargin;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // رأس الجدول
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Expanded(flex: 2, child: SizedBox()),
                Expanded(
                  child: Text(formatMonthKey(currentMonthKey),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                Expanded(
                  child: Text(formatMonthKey(prevMonthKey),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ),
                const Expanded(
                  child: Text('±',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14)),
                ),
              ],
            ),
          ),
          _CompRow2(label: 'الإيرادات', cur: cRev, prev: pRev,
              color: AppTheme.green),
          _CompRow2(label: 'المصاريف', cur: cExp, prev: pExp,
              color: AppTheme.red, invertGood: true),
          if (cDebt > 0)
            _CompRow2(label: 'ديون معلقة', cur: cDebt, prev: 0,
                color: Colors.orange, invertGood: true),
          _CompRow2(label: 'صافي الربح', cur: cProfit, prev: pProfit,
              color: cProfit >= 0 ? AppTheme.green : AppTheme.red,
              isBold: true),
          // هامش الربح
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border)),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text('هامش الربح',
                      style: TextStyle(color: AppTheme.textSecondary,
                          fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Text(
                    '${cMargin.toStringAsFixed(1)}%',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: cMargin >= 0 ? AppTheme.green : AppTheme.red,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${pMargin.toStringAsFixed(1)}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        marginDiff >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: marginDiff >= 0
                            ? AppTheme.green
                            : AppTheme.red,
                        size: 12,
                      ),
                      Text(
                        '${marginDiff.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                            color: marginDiff >= 0
                                ? AppTheme.green
                                : AppTheme.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompRow2 extends StatelessWidget {
  final String label;
  final double cur, prev;
  final Color color;
  final bool isBold, invertGood;

  const _CompRow2({
    required this.label, required this.cur, required this.prev,
    required this.color, this.isBold = false, this.invertGood = false,
  });

  @override
  Widget build(BuildContext context) {
    final diff = cur - prev;
    final isGood = invertGood ? diff <= 0 : diff >= 0;
    final diffColor = isGood ? AppTheme.green : AppTheme.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border))),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: TextStyle(
                    color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          ),
          Expanded(
            child: Text(formatAmount(cur),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(formatAmount(prev),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  diff >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  color: diffColor, size: 11,
                ),
                Text(formatAmount(diff.abs()),
                    style: TextStyle(color: diffColor, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompBarChart extends StatelessWidget {
  final String currentMonthKey, prevMonthKey;
  final double cRev, cExp, cProfit, pRev, pExp, pProfit;

  const _CompBarChart({
    required this.currentMonthKey, required this.prevMonthKey,
    required this.cRev, required this.cExp, required this.cProfit,
    required this.pRev, required this.pExp, required this.pProfit,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = [cRev, cExp, pRev, pExp,
        cProfit.abs(), pProfit.abs()].reduce((a, b) => a > b ? a : b);

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
          const _SectionTitle(title: 'مقارنة بصرية'),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final labels = [
                          formatMonthKey(currentMonthKey).split(' ').first,
                          formatMonthKey(prevMonthKey).split(' ').first,
                        ];
                        if (val.toInt() < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(labels[val.toInt()],
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      getTitlesWidget: (val, meta) => Text(
                        formatAmount(val),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 9),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppTheme.border, strokeWidth: 1),
                  getDrawingVerticalLine: (_) =>
                      const FlLine(color: Colors.transparent),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _group(0, cRev, cExp, cProfit),
                  _group(1, pRev, pExp, pProfit),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: AppTheme.green, label: 'إيرادات'),
              SizedBox(width: 16),
              _Legend(color: AppTheme.red, label: 'مصاريف'),
              SizedBox(width: 16),
              _Legend(color: AppTheme.accent, label: 'ربح'),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _group(int x, double rev, double exp, double profit) {
    return BarChartGroupData(
      x: x,
      groupVertically: false,
      barRods: [
        BarChartRodData(toY: rev, color: AppTheme.green, width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5))),
        BarChartRodData(toY: exp, color: AppTheme.red, width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5))),
        BarChartRodData(toY: profit.abs(), color: AppTheme.accent, width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5))),
      ],
    );
  }
}

// ── مساعدات عامة ─────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold));
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }
}
