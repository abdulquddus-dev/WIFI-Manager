// lib/services/hive_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart';
import '../models/card_entry_model.dart';
import '../models/card_price_model.dart';
import '../models/debt_model.dart';

class HiveService {
  static const String expensesBox = 'expenses';
  static const String cardEntriesBox = 'card_entries';
  static const String cardPricesBox = 'card_prices';

  // ── تهيئة Hive ──────────────────────────────────────
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ExpenseModelAdapter());
    Hive.registerAdapter(CardEntryModelAdapter());
    Hive.registerAdapter(CardPriceModelAdapter());
    Hive.registerAdapter(DebtModelAdapter());

    await Hive.openBox<ExpenseModel>(expensesBox);
    await Hive.openBox<CardEntryModel>(cardEntriesBox);
    await Hive.openBox<CardPriceModel>(cardPricesBox);
    await Hive.openBox<DebtModel>('debts');

    await _initDefaultCardPrices();
  }

  // تهيئة الأسعار الافتراضية إذا لم تكن موجودة
  static Future<void> _initDefaultCardPrices() async {
    final box = Hive.box<CardPriceModel>(cardPricesBox);
    if (box.isEmpty) {
      for (final entry in CardPriceModel.defaultPrices.entries) {
        await box.put(
          entry.key.toString(),
          CardPriceModel(denomination: entry.key, price: entry.value),
        );
      }
    }
  }

  // ── المصاريف ─────────────────────────────────────────
  static Box<ExpenseModel> get expenses =>
      Hive.box<ExpenseModel>(expensesBox);

  static Future<void> addExpense(ExpenseModel expense) async {
    await expenses.put(expense.id, expense);
  }

  static Future<void> deleteExpense(String id) async {
    await expenses.delete(id);
  }

  static List<ExpenseModel> getExpensesByMonth(String monthKey) {
    return expenses.values
        .where((e) => e.monthKey == monthKey)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static double getTotalExpensesByMonth(String monthKey) {
    return getExpensesByMonth(monthKey)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // ── الكروت ────────────────────────────────────────────
  static Box<CardEntryModel> get cardEntries =>
      Hive.box<CardEntryModel>(cardEntriesBox);

  static Future<void> addCardEntry(CardEntryModel entry) async {
    await cardEntries.put(entry.id, entry);
  }

  static Future<void> deleteCardEntry(String id) async {
    await cardEntries.delete(id);
  }

  static List<CardEntryModel> getCardEntriesByMonth(String monthKey) {
    return cardEntries.values
        .where((e) => e.monthKey == monthKey)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // إجمالي عدد الكروت لكل فئة في شهر معين
  static Map<int, int> getCardCountsByMonth(String monthKey) {
    final entries = getCardEntriesByMonth(monthKey);
    final Map<int, int> counts = {};
    for (final e in entries) {
      counts[e.denomination] = (counts[e.denomination] ?? 0) + e.count;
    }
    return counts;
  }

  // إجمالي الإيرادات المتوقعة من الكروت في شهر معين
  static double getTotalCardRevenueByMonth(String monthKey) {
    final counts = getCardCountsByMonth(monthKey);
    final prices = Hive.box<CardPriceModel>(cardPricesBox);
    double total = 0;
    counts.forEach((denomination, count) {
      final priceModel = prices.get(denomination.toString());
      if (priceModel != null) {
        total += priceModel.price * count;
      }
    });
    return total;
  }

  // ── أسعار الكروت ─────────────────────────────────────
  static Box<CardPriceModel> get cardPrices =>
      Hive.box<CardPriceModel>(cardPricesBox);

  static Future<void> updateCardPrice(int denomination, double price) async {
    await cardPrices.put(
      denomination.toString(),
      CardPriceModel(denomination: denomination, price: price),
    );
  }

  static double getCardPrice(int denomination) {
    return cardPrices.get(denomination.toString())?.price ??
        CardPriceModel.defaultPrices[denomination] ??
        0;
  }

  // ── الأشهر المتاحة ──────────────────────────────────
  static List<String> getAllMonthKeys() {
    final Set<String> months = {};
    for (final e in expenses.values) { months.add(e.monthKey); }
    for (final e in cardEntries.values) { months.add(e.monthKey); }
    final list = months.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }
}
