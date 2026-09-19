// lib/screens/home_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/cards_provider.dart';
import '../utils/app_theme.dart';
import 'dashboard_screen.dart';
import 'expenses_screen.dart';
import 'cards_screen.dart';
import 'reports_screen.dart';
import 'debts_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  String _monthKey = getCurrentMonthKey();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadMonth(_monthKey);
      context.read<CardsProvider>().loadMonth(_monthKey);
    });
  }

  List<Widget> get _screens => [
        DashboardScreen(monthKey: _monthKey),
        ExpensesScreen(monthKey: _monthKey),
        CardsScreen(monthKey: _monthKey),
        DebtsScreen(monthKey: _monthKey),
        ReportsScreen(currentMonthKey: _monthKey),
        const SettingsScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // شريط الشهر العلوي
          if (_currentIndex != 5)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _MonthSelector(
                currentMonthKey: _monthKey,
                onMonthChanged: (mk) {
                  setState(() => _monthKey = mk);
                  _loadData();
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.border),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.remove_circle_outline),
              activeIcon: Icon(Icons.remove_circle),
              label: 'المصاريف',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.credit_card_outlined),
              activeIcon: Icon(Icons.credit_card),
              label: 'الكروت',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.handshake_outlined),
              activeIcon: Icon(Icons.handshake),
              label: 'الديون',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'التقارير',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}

// ── منتقي الشهر ─────────────────────────────────────
class _MonthSelector extends StatelessWidget {
  final String currentMonthKey;
  final ValueChanged<String> onMonthChanged;

  const _MonthSelector({
    required this.currentMonthKey,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 60),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: AppTheme.surfaceLight.withValues(alpha: 0.95),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // السهم للخلف
          IconButton(
            icon: const Icon(Icons.chevron_right,
                color: AppTheme.accent),
            onPressed: () => _changeMonth(currentMonthKey, 1, onMonthChanged),
            padding: EdgeInsets.zero,
          ),

          // الشهر الحالي
          GestureDetector(
            onTap: () => _showMonthPicker(context),
            child: Text(
              formatMonthKey(currentMonthKey),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),

          // السهم للأمام (حتى الشهر الحالي فقط)
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: currentMonthKey == getCurrentMonthKey()
                  ? AppTheme.textSecondary.withValues(alpha: 0.3)
                  : AppTheme.accent,
            ),
            onPressed: currentMonthKey == getCurrentMonthKey()
                ? null
                : () =>
                    _changeMonth(currentMonthKey, -1, onMonthChanged),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _changeMonth(
      String mk, int delta, ValueChanged<String> onChange) {
    final parts = mk.split('-');
    var year = int.parse(parts[0]);
    var month = int.parse(parts[1]) + delta;

    if (month > 12) {
      month = 1;
      year++;
    } else if (month < 1) {
      month = 12;
      year--;
    }

    final newMk = '$year-${month.toString().padLeft(2, '0')}';
    onChange(newMk);
  }

  void _showMonthPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MonthPickerSheet(
        currentMonthKey: currentMonthKey,
        onSelected: (mk) {
          Navigator.pop(context);
          onMonthChanged(mk);
        },
      ),
    );
  }
}

class _MonthPickerSheet extends StatelessWidget {
  final String currentMonthKey;
  final ValueChanged<String> onSelected;

  const _MonthPickerSheet(
      {required this.currentMonthKey, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    // توليد آخر 24 شهر
    final months = List.generate(24, (i) {
      final now = DateTime.now();
      final d = DateTime(now.year, now.month - i);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        const Text(
          'اختر الشهر',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: months.length,
            itemBuilder: (ctx, i) {
              final mk = months[i];
              final isSelected = mk == currentMonthKey;
              return ListTile(
                title: Text(
                  formatMonthKey(mk),
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.accent
                        : AppTheme.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle,
                        color: AppTheme.accent)
                    : null,
                onTap: () => onSelected(mk),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
