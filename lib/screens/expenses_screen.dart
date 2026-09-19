// lib/screens/expenses_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../models/expense_model.dart';
import '../utils/app_theme.dart';

class ExpensesScreen extends StatelessWidget {
  final String monthKey;
  const ExpensesScreen({super.key, required this.monthKey});

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final list = expenses.expenses;
    final total = expenses.getTotalForMonth(monthKey);

    return Scaffold(
      appBar: AppBar(
        title: Text('المصاريف - ${formatMonthKey(monthKey)}'),
        actions: [
          Container(
            margin: const EdgeInsets.only(left: 12, right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${formatAmount(total)} ريال',
              style: const TextStyle(
                  color: AppTheme.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseSheet(context),
        backgroundColor: AppTheme.red,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة مصروف',
            style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
      ),
      body: list.isEmpty
          ? _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: list.length,
              itemBuilder: (ctx, i) => _ExpenseItem(
                expense: list[i],
                onDelete: () => expenses.deleteExpense(list[i].id, monthKey),
                onEdit: () => _showEditExpenseSheet(context, list[i], monthKey),
              ),
            ),
    );
  }

  void _showEditExpenseSheet(BuildContext context, ExpenseModel expense, String monthKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EditExpenseSheet(expense: expense, monthKey: monthKey),
    );
  }

  void _showAddExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddExpenseSheet(monthKey: monthKey),
    );
  }
}

// ── نموذج إضافة مصروف ───────────────────────────────
class AddExpenseSheet extends StatefulWidget {
  final String monthKey;
  const AddExpenseSheet({super.key, required this.monthKey});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  String? _selectedCategory;
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedCategory == null || _amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع الحقول المطلوبة'),
          backgroundColor: AppTheme.red,
        ),
      );
      return;
    }
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال مبلغ صحيح'),
          backgroundColor: AppTheme.red,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    await context.read<ExpenseProvider>().addExpense(
          category: _selectedCategory!,
          description: _descCtrl.text.trim(),
          amount: amount,
          date: _selectedDate,
          monthKey: widget.monthKey,
          addedBy: auth.currentUser?.name ?? 'غير محدد',
        );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
          // مقبض السحب
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
            'إضافة مصروف جديد',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // الفئة
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            dropdownColor: AppTheme.surfaceLight,
            style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Cairo'),
            decoration: const InputDecoration(
              labelText: 'نوع المصروف *',
              prefixIcon: Icon(Icons.category_outlined, color: AppTheme.accent),
            ),
            items: ExpenseCategories.items
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v),
          ),
          const SizedBox(height: 14),

          // الوصف
          TextField(
            controller: _descCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'الوصف (اختياري)',
              prefixIcon:
                  Icon(Icons.description_outlined, color: AppTheme.accent),
            ),
          ),
          const SizedBox(height: 14),

          // المبلغ
          TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'المبلغ (ريال) *',
              prefixIcon:
                  Icon(Icons.attach_money, color: AppTheme.accent),
              suffixText: 'ريال',
              suffixStyle: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 14),

          // التاريخ
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppTheme.accent,
                      surface: AppTheme.surface,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (d != null) setState(() => _selectedDate = d);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: const Border.fromBorderSide(
                    BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: AppTheme.accent, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          // زر الحفظ
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.red,
                  foregroundColor: Colors.white),
              child: const Text('حفظ المصروف'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── عنصر المصروف ────────────────────────────────────
class _ExpenseItem extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ExpenseItem({required this.expense, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(expense.id),
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
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text('حذف المصروف',
                style: TextStyle(color: AppTheme.textPrimary)),
            content: const Text('هل أنت متأكد من الحذف؟',
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
        );
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.remove_circle_outline,
                      color: AppTheme.red, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.category,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (expense.description.isNotEmpty)
                        Text(
                          expense.description,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      Text(
                        '${DateFormat('dd/MM').format(expense.date)} - ${expense.addedBy}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${formatAmount(expense.amount)} ريال',
                  style: const TextStyle(
                    color: AppTheme.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined,
                      size: 15, color: AppTheme.accent),
                  label: const Text('تعديل',
                      style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 12,
                          fontFamily: 'Cairo')),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── نموذج تعديل مصروف ───────────────────────────────
class EditExpenseSheet extends StatefulWidget {
  final ExpenseModel expense;
  final String monthKey;
  const EditExpenseSheet(
      {super.key, required this.expense, required this.monthKey});

  @override
  State<EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends State<EditExpenseSheet> {
  late String _category;
  late TextEditingController _descCtrl;
  late TextEditingController _amountCtrl;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _category = widget.expense.category;
    _descCtrl = TextEditingController(text: widget.expense.description);
    _amountCtrl =
        TextEditingController(text: widget.expense.amount.toString());
    _date = widget.expense.date;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    widget.expense.category = _category;
    widget.expense.description = _descCtrl.text.trim();
    widget.expense.amount = amount;
    widget.expense.date = _date;
    await context
        .read<ExpenseProvider>()
        .updateExpense(widget.expense, widget.monthKey);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('تعديل المصروف',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            dropdownColor: AppTheme.surfaceLight,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontFamily: 'Cairo'),
            decoration: const InputDecoration(
              labelText: 'نوع المصروف',
              prefixIcon:
                  Icon(Icons.category_outlined, color: AppTheme.accent),
            ),
            items: ExpenseCategories.items
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'الوصف',
              prefixIcon: Icon(Icons.description_outlined,
                  color: AppTheme.accent),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'المبلغ (ريال)',
              prefixIcon:
                  Icon(Icons.attach_money, color: AppTheme.accent),
              suffixText: 'ريال',
              suffixStyle: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('حفظ التعديلات'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── الحالة الفارغة ──────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 70, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'لا توجد مصاريف هذا الشهر',
            style:
                TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'اضغط + لإضافة مصروف جديد',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
