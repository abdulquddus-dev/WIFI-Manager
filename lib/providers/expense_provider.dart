// lib/providers/expense_provider.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_model.dart';
import '../services/hive_service.dart';
import '../services/firestore_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  List<ExpenseModel> _expenses = [];
  bool _loading = false;

  List<ExpenseModel> get expenses => _expenses;
  bool get loading => _loading;

  // تحميل مصاريف شهر معين
  void loadMonth(String monthKey) {
    _expenses = HiveService.getExpensesByMonth(monthKey);
    notifyListeners();
  }

  // إضافة مصروف
  Future<void> addExpense({
    required String category,
    required String description,
    required double amount,
    required DateTime date,
    required String monthKey,
    required String addedBy,
  }) async {
    _loading = true;
    notifyListeners();

    final expense = ExpenseModel(
      id: _uuid.v4(),
      category: category,
      description: description,
      amount: amount,
      date: date,
      monthKey: monthKey,
      addedBy: addedBy,
    );

    // حفظ محلي
    await HiveService.addExpense(expense);

    // مزامنة سحابية
    try {
      await FirestoreService.syncExpense(expense);
    } catch (_) {
      // سيتم المزامنة لاحقاً
    }

    _expenses = HiveService.getExpensesByMonth(monthKey);
    _loading = false;
    notifyListeners();
  }

  // تعديل مصروف
  Future<void> updateExpense(ExpenseModel updated, String monthKey) async {
    await HiveService.addExpense(updated); // put بنفس الـ id يُحدّث
    try {
      await FirestoreService.syncExpense(updated);
    } catch (_) {}
    _expenses = HiveService.getExpensesByMonth(monthKey);
    notifyListeners();
  }

  // حذف مصروف
  Future<void> deleteExpense(String id, String monthKey) async {
    await HiveService.deleteExpense(id);
    try {
      await FirestoreService.deleteExpense(id);
    } catch (_) {}
    _expenses = HiveService.getExpensesByMonth(monthKey);
    notifyListeners();
  }

  // إجمالي مصاريف شهر
  double getTotalForMonth(String monthKey) {
    return HiveService.getTotalExpensesByMonth(monthKey);
  }

  // مصاريف مجمّعة حسب الفئة لشهر معين
  Map<String, double> getCategoryTotals(String monthKey) {
    final expenses = HiveService.getExpensesByMonth(monthKey);
    final Map<String, double> totals = {};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  // بيانات للرسم البياني لعدة أشهر
  List<Map<String, dynamic>> getMonthlyExpensesChart(
      List<String> monthKeys) {
    return monthKeys.map((mk) {
      return {
        'month': mk,
        'total': HiveService.getTotalExpensesByMonth(mk),
      };
    }).toList();
  }
}
