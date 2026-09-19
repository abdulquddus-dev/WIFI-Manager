// lib/screens/debts_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/debt_provider.dart';
import '../providers/auth_provider.dart';
import '../models/debt_model.dart';
import '../utils/app_theme.dart';

class DebtsScreen extends StatefulWidget {
  final String monthKey;
  const DebtsScreen({super.key, required this.monthKey});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<DebtProvider>().loadAll());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debts = context.watch<DebtProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الديون'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('لي'),
                  if (debts.debtsForMe.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _Badge(count: debts.debtsForMe.length,
                        color: AppTheme.green),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('عليّ'),
                  if (debts.debtsOnMe.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _Badge(count: debts.debtsOnMe.length,
                        color: AppTheme.red),
                  ],
                ],
              ),
            ),
            const Tab(text: 'مسوّاة'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDebtSheet(context),
        backgroundColor: AppTheme.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة دين',
            style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
      ),
      body: Column(
        children: [
          // ملخص
          _DebtSummaryBar(
            totalForMe: debts.totalForMe,
            totalOnMe: debts.totalOnMe,
          ),
          // القوائم
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _DebtList(
                    items: debts.debtsForMe,
                    emptyMsg: 'لا أحد مدين لك حالياً'),
                _DebtList(
                    items: debts.debtsOnMe,
                    emptyMsg: 'لا توجد ديون عليك حالياً'),
                _DebtList(
                    items: debts.settledDebts,
                    emptyMsg: 'لا توجد ديون مسوّاة بعد',
                    isSettled: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDebtSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddDebtSheet(monthKey: widget.monthKey),
    );
  }
}

// ── شريط الملخص ─────────────────────────────────────
class _DebtSummaryBar extends StatelessWidget {
  final double totalForMe;
  final double totalOnMe;
  const _DebtSummaryBar(
      {required this.totalForMe, required this.totalOnMe});

  @override
  Widget build(BuildContext context) {
    final net = totalForMe - totalOnMe;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'مدينون لي',
              amount: totalForMe,
              color: AppTheme.green,
              icon: Icons.arrow_downward,
            ),
          ),
          Container(width: 1, height: 40, color: AppTheme.border),
          Expanded(
            child: _SummaryItem(
              label: 'عليّ',
              amount: totalOnMe,
              color: AppTheme.red,
              icon: Icons.arrow_upward,
            ),
          ),
          Container(width: 1, height: 40, color: AppTheme.border),
          Expanded(
            child: _SummaryItem(
              label: 'الصافي',
              amount: net.abs(),
              color: net >= 0 ? AppTheme.green : AppTheme.red,
              icon: net >= 0 ? Icons.trending_up : Icons.trending_down,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  const _SummaryItem(
      {required this.label,
      required this.amount,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 3),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${formatAmount(amount)} ريال',
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}

// ── قائمة الديون ─────────────────────────────────────
class _DebtList extends StatelessWidget {
  final List<DebtModel> items;
  final String emptyMsg;
  final bool isSettled;
  const _DebtList(
      {required this.items,
      required this.emptyMsg,
      this.isSettled = false});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake_outlined,
                size: 60,
                color: AppTheme.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(emptyMsg,
                style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: items.length,
      itemBuilder: (ctx, i) =>
          _DebtCard(debt: items[i], isSettled: isSettled),
    );
  }
}

// ── بطاقة الدين ─────────────────────────────────────
class _DebtCard extends StatelessWidget {
  final DebtModel debt;
  final bool isSettled;
  const _DebtCard({required this.debt, required this.isSettled});

  @override
  Widget build(BuildContext context) {
    final isForMe = debt.type == 'لي';
    final color = isSettled
        ? AppTheme.textSecondary
        : (isForMe ? AppTheme.green : AppTheme.red);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // رأس البطاقة
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // الأيقونة
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSettled
                        ? Icons.check_circle_outline
                        : (isForMe
                            ? Icons.arrow_circle_down
                            : Icons.arrow_circle_up),
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // المعلومات
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            debt.personName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              debt.type,
                              style: TextStyle(
                                  color: color, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      if (debt.description.isNotEmpty)
                        Text(
                          debt.description,
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12),
                        ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(debt.date),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // المبلغ
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${formatAmount(debt.amount)} ريال',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (debt.paidAmount > 0 && !debt.isSettled)
                      Text(
                        'متبقي: ${formatAmount(debt.remainingAmount)} ريال',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // شريط التقدم
          if (!debt.isSettled && debt.paidAmount > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: debt.paidPercent.clamp(0.0, 1.0),
                  backgroundColor: AppTheme.surfaceLight,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 5,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // أزرار الإجراءات
          if (!debt.isSettled) ...[
            const Divider(color: AppTheme.border, height: 1),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  // تعديل
                  TextButton.icon(
                    onPressed: () =>
                        _showEditSheet(context, debt),
                    icon: const Icon(Icons.edit_outlined,
                        size: 16, color: AppTheme.accent),
                    label: const Text('تعديل',
                        style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 12,
                            fontFamily: 'Cairo')),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8)),
                  ),
                  // دفعة جزئية
                  TextButton.icon(
                    onPressed: () =>
                        _showPaymentSheet(context, debt),
                    icon: const Icon(Icons.payments_outlined,
                        size: 16, color: AppTheme.gold),
                    label: const Text('دفعة',
                        style: TextStyle(
                            color: AppTheme.gold,
                            fontSize: 12,
                            fontFamily: 'Cairo')),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8)),
                  ),
                  const Spacer(),
                  // تسوية كاملة
                  TextButton.icon(
                    onPressed: () =>
                        _confirmSettle(context, debt),
                    icon: const Icon(Icons.check_circle_outline,
                        size: 16, color: AppTheme.green),
                    label: const Text('تسوية',
                        style: TextStyle(
                            color: AppTheme.green,
                            fontSize: 12,
                            fontFamily: 'Cairo')),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8)),
                  ),
                  // حذف
                  TextButton.icon(
                    onPressed: () =>
                        _confirmDelete(context, debt),
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: AppTheme.red),
                    label: const Text('حذف',
                        style: TextStyle(
                            color: AppTheme.red,
                            fontSize: 12,
                            fontFamily: 'Cairo')),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPaymentSheet(BuildContext context, DebtModel debt) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          'تسجيل دفعة - ${debt.personName}',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'المتبقي: ${formatAmount(debt.remainingAmount)} ريال',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'مبلغ الدفعة',
                suffixText: 'ريال',
                suffixStyle: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(ctrl.text);
              if (amount != null && amount > 0) {
                await ctx
                    .read<DebtProvider>()
                    .addPayment(debt.id, amount);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('تسجيل',
                style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  void _confirmSettle(BuildContext context, DebtModel debt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('تسوية الدين',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'هل تم سداد كامل مبلغ ${formatAmount(debt.amount)} ريال من ${debt.personName}؟',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await ctx.read<DebtProvider>().settleDebt(debt.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('نعم، تمت التسوية',
                style: TextStyle(color: AppTheme.green)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DebtModel debt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('حذف الدين',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('هل أنت متأكد من الحذف؟',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await ctx.read<DebtProvider>().deleteDebt(debt.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('حذف',
                style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, DebtModel debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditDebtSheet(debt: debt),
    );
  }
}

// ── نموذج إضافة دين ─────────────────────────────────
class _AddDebtSheet extends StatefulWidget {
  final String monthKey;
  const _AddDebtSheet({required this.monthKey});

  @override
  State<_AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<_AddDebtSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _type = 'لي';
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('يرجى إدخال الاسم والمبلغ'),
        backgroundColor: AppTheme.red,
      ));
      return;
    }
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('يرجى إدخال مبلغ صحيح'),
        backgroundColor: AppTheme.red,
      ));
      return;
    }
    final auth = context.read<AuthProvider>();
    await context.read<DebtProvider>().addDebt(
          personName: _nameCtrl.text.trim(),
          type: _type,
          amount: amount,
          description: _descCtrl.text.trim(),
          date: _date,
          monthKey: widget.monthKey,
          addedBy: auth.currentUser?.name ?? '',
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
          const Text('إضافة دين جديد',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // نوع الدين
          Row(
            children: [
              Expanded(
                child: _TypeButton(
                  label: 'دين لي',
                  subtitle: 'الشخص مدين لي',
                  selected: _type == 'لي',
                  color: AppTheme.green,
                  onTap: () => setState(() => _type = 'لي'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeButton(
                  label: 'دين عليّ',
                  subtitle: 'أنا المدين',
                  selected: _type == 'عليّ',
                  color: AppTheme.red,
                  onTap: () => setState(() => _type = 'عليّ'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: _type == 'لي'
                  ? 'اسم الشخص المدين *'
                  : 'اسم الشخص الذي أنا مدين له *',
              prefixIcon:
                  const Icon(Icons.person_outline, color: AppTheme.accent),
            ),
          ),
          const SizedBox(height: 12),

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
          const SizedBox(height: 12),

          TextField(
            controller: _descCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'الوصف (اختياري)',
              prefixIcon: Icon(Icons.description_outlined,
                  color: AppTheme.accent),
            ),
          ),
          const SizedBox(height: 12),

          // التاريخ
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
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
              if (d != null) setState(() => _date = d);
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
                  Text(DateFormat('dd/MM/yyyy').format(_date),
                      style:
                          const TextStyle(color: AppTheme.textPrimary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _type == 'لي' ? AppTheme.green : AppTheme.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('حفظ'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── نموذج تعديل دين ─────────────────────────────────
class _EditDebtSheet extends StatefulWidget {
  final DebtModel debt;
  const _EditDebtSheet({required this.debt});

  @override
  State<_EditDebtSheet> createState() => _EditDebtSheetState();
}

class _EditDebtSheetState extends State<_EditDebtSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _amountCtrl;
  late String _type;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.debt.personName);
    _descCtrl = TextEditingController(text: widget.debt.description);
    _amountCtrl =
        TextEditingController(text: widget.debt.amount.toString());
    _type = widget.debt.type;
    _date = widget.debt.date;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    widget.debt.personName = _nameCtrl.text.trim();
    widget.debt.description = _descCtrl.text.trim();
    widget.debt.amount = amount;
    widget.debt.type = _type;
    widget.debt.date = _date;
    await context.read<DebtProvider>().updateDebt(widget.debt);
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
          const Text('تعديل الدين',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'الاسم',
              prefixIcon: Icon(Icons.person_outline, color: AppTheme.accent),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'المبلغ',
              prefixIcon: Icon(Icons.attach_money, color: AppTheme.accent),
              suffixText: 'ريال',
              suffixStyle: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'الوصف',
              prefixIcon: Icon(Icons.description_outlined, color: AppTheme.accent),
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

// ── مساعدات ─────────────────────────────────────────
class _TypeButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TypeButton({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppTheme.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    color: selected ? color : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold)),
            Text(subtitle,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final Color color;
  const _Badge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$count',
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
