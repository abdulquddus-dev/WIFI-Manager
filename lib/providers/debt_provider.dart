// lib/providers/debt_provider.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/debt_model.dart';

class DebtProvider extends ChangeNotifier {
  static const String _boxName = 'debts';
  final _uuid = const Uuid();
  List<DebtModel> _debts = [];

  List<DebtModel> get debts => _debts;
  List<DebtModel> get activeDebts =>
      _debts.where((d) => !d.isSettled).toList();
  List<DebtModel> get settledDebts =>
      _debts.where((d) => d.isSettled).toList();

  // ديون لي (الآخرون مدينون لي)
  List<DebtModel> get debtsForMe =>
      activeDebts.where((d) => d.type == 'لي').toList();

  // ديون عليّ (أنا المدين)
  List<DebtModel> get debtsOnMe =>
      activeDebts.where((d) => d.type == 'عليّ').toList();

  double get totalForMe =>
      debtsForMe.fold(0.0, (s, d) => s + d.remainingAmount);
  double get totalOnMe =>
      debtsOnMe.fold(0.0, (s, d) => s + d.remainingAmount);

  static Future<void> initBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<DebtModel>(_boxName);
    }
  }

  void loadAll() {
    if (!Hive.isBoxOpen(_boxName)) return;
    final box = Hive.box<DebtModel>(_boxName);
    _debts = box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> addDebt({
    required String personName,
    required String type,
    required double amount,
    required String description,
    required DateTime date,
    required String monthKey,
    required String addedBy,
  }) async {
    final debt = DebtModel(
      id: _uuid.v4(),
      personName: personName,
      type: type,
      amount: amount,
      description: description,
      date: date,
      monthKey: monthKey,
      addedBy: addedBy,
    );
    final box = Hive.box<DebtModel>(_boxName);
    await box.put(debt.id, debt);
    loadAll();
  }

  Future<void> updateDebt(DebtModel debt) async {
    final box = Hive.box<DebtModel>(_boxName);
    await box.put(debt.id, debt);
    loadAll();
  }

  Future<void> addPayment(String debtId, double payment) async {
    final box = Hive.box<DebtModel>(_boxName);
    final debt = box.get(debtId);
    if (debt == null) return;
    debt.paidAmount = (debt.paidAmount + payment).clamp(0, debt.amount);
    if (debt.paidAmount >= debt.amount) debt.isSettled = true;
    await box.put(debtId, debt);
    loadAll();
  }

  Future<void> settleDebt(String debtId) async {
    final box = Hive.box<DebtModel>(_boxName);
    final debt = box.get(debtId);
    if (debt == null) return;
    debt.paidAmount = debt.amount;
    debt.isSettled = true;
    await box.put(debtId, debt);
    loadAll();
  }

  Future<void> deleteDebt(String debtId) async {
    final box = Hive.box<DebtModel>(_boxName);
    await box.delete(debtId);
    loadAll();
  }
}
