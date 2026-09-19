// lib/screens/cards_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cards_provider.dart';
import '../providers/auth_provider.dart';
import '../models/card_entry_model.dart';
import '../utils/app_theme.dart';

class CardsScreen extends StatelessWidget {
  final String monthKey;
  const CardsScreen({super.key, required this.monthKey});

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<CardsProvider>();
    final total = cards.getTotalRevenueForMonth(monthKey);
    final counts = cards.getCountsByMonth(monthKey);

    return Scaffold(
      appBar: AppBar(
        title: Text('الكروت - ${formatMonthKey(monthKey)}'),
        actions: [
          Container(
            margin: const EdgeInsets.only(left: 12, right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${formatAmount(total)} ريال',
              style: const TextStyle(
                  color: AppTheme.green, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCardSheet(context),
        backgroundColor: AppTheme.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة كروت',
            style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
      ),
      body: Column(
        children: [
          // ملخص الكروت
          _CardsSummarySection(counts: counts, cards: cards),

          // سجل الإدخالات
          Expanded(
            child: cards.entries.isEmpty
                ? _EmptyCards()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: cards.entries.length,
                    itemBuilder: (ctx, i) {
                      final entry = cards.entries[i];
                      return _CardEntryItem(
                        entry: entry,
                        price: cards.getPriceFor(entry.denomination),
                        onDelete: () =>
                            cards.deleteEntry(entry.id, monthKey),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddCardSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddCardsSheet(monthKey: monthKey),
    );
  }
}

// ── ملخص الكروت ─────────────────────────────────────
class _CardsSummarySection extends StatelessWidget {
  final Map<int, int> counts;
  final CardsProvider cards;

  const _CardsSummarySection(
      {required this.counts, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إجمالي الكروت لهذا الشهر',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // شبكة الفئات
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: CardDenominations.values.length,
            itemBuilder: (ctx, i) {
              final d = CardDenominations.values[i];
              final count = counts[d] ?? 0;
              final price = cards.getPriceFor(d);
              final hasCards = count > 0;
              return Container(
                decoration: BoxDecoration(
                  color: hasCards
                      ? AppTheme.green.withValues(alpha: 0.1)
                      : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasCards
                        ? AppTheme.green.withValues(alpha: 0.4)
                        : AppTheme.border,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'أبو $d',
                      style: TextStyle(
                        color: hasCards
                            ? AppTheme.green
                            : AppTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: hasCards
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary.withValues(alpha: 0.5),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hasCards)
                      Text(
                        '${formatAmount(price * count)}ر',
                        style: const TextStyle(
                            color: AppTheme.accent, fontSize: 9),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── نموذج إضافة الكروت ──────────────────────────────
class AddCardsSheet extends StatefulWidget {
  final String monthKey;
  const AddCardsSheet({super.key, required this.monthKey});

  @override
  State<AddCardsSheet> createState() => _AddCardsSheetState();
}

class _AddCardsSheetState extends State<AddCardsSheet> {
  int? _selectedDenomination;
  final _countCtrl = TextEditingController();

  @override
  void dispose() {
    _countCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedDenomination == null || _countCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار الفئة وإدخال العدد'),
          backgroundColor: AppTheme.red,
        ),
      );
      return;
    }
    final count = int.tryParse(_countCtrl.text);
    if (count == null || count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال عدد صحيح'),
          backgroundColor: AppTheme.red,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final cards = context.read<CardsProvider>();
    final price = cards.getPriceFor(_selectedDenomination!);

    await cards.addCardEntry(
      denomination: _selectedDenomination!,
      count: count,
      monthKey: widget.monthKey,
      addedBy: auth.currentUser?.name ?? 'غير محدد',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تمت إضافة $count كرت أبو $_selectedDenomination | المبلغ: ${formatAmount(price * count)} ريال',
          ),
          backgroundColor: AppTheme.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<CardsProvider>();
    final selectedPrice = _selectedDenomination != null
        ? cards.getPriceFor(_selectedDenomination!)
        : 0.0;
    final count = int.tryParse(_countCtrl.text) ?? 0;
    final expectedRevenue = selectedPrice * count;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'إضافة كروت مطبوعة',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // اختيار الفئة
          const Text('اختر الفئة:',
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CardDenominations.values.map((d) {
              final isSelected = _selectedDenomination == d;
              return InkWell(
                onTap: () => setState(() => _selectedDenomination = d),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.green.withValues(alpha: 0.2)
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.green
                          : AppTheme.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    'أبو $d',
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.green
                          : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // عدد الكروت
          TextField(
            controller: _countCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.textPrimary),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'عدد الكروت *',
              prefixIcon:
                  Icon(Icons.credit_card, color: AppTheme.accent),
            ),
          ),
          const SizedBox(height: 14),

          // معاينة الإيرادات
          if (_selectedDenomination != null && count > 0)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$count كرت × ${formatAmount(selectedPrice)} ريال',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  Text(
                    '= ${formatAmount(expectedRevenue)} ريال',
                    style: const TextStyle(
                      color: AppTheme.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.green,
                  foregroundColor: Colors.white),
              child: const Text('إضافة'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── عنصر إدخال الكروت ───────────────────────────────
class _CardEntryItem extends StatelessWidget {
  final CardEntryModel entry;
  final double price;
  final VoidCallback onDelete;

  const _CardEntryItem(
      {required this.entry, required this.price, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final total = price * entry.count;
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppTheme.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.red),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('حذف الإدخال',
              style: TextStyle(color: AppTheme.textPrimary)),
          content: const Text('هل تريد حذف هذا الإدخال؟',
              style: TextStyle(color: AppTheme.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف',
                  style: TextStyle(color: AppTheme.red)),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.credit_card,
                  color: AppTheme.green, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'كرت أبو ${entry.denomination}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${entry.count} كرت | ${DateFormat('dd/MM').format(entry.date)} - ${entry.addedBy}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '+${formatAmount(total)} ريال',
              style: const TextStyle(
                color: AppTheme.green,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off_outlined,
              size: 70,
              color: AppTheme.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('لا توجد كروت مسجلة',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('اضغط + لإضافة كروت مطبوعة',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
