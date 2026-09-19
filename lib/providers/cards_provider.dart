// lib/providers/cards_provider.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/card_entry_model.dart';
import '../models/card_price_model.dart';
import '../services/hive_service.dart';
import '../services/firestore_service.dart';

class CardsProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  List<CardEntryModel> _entries = [];
  bool _loading = false;

  List<CardEntryModel> get entries => _entries;
  bool get loading => _loading;

  void loadMonth(String monthKey) {
    _entries = HiveService.getCardEntriesByMonth(monthKey);
    notifyListeners();
  }

  // إضافة كروت
  Future<void> addCardEntry({
    required int denomination,
    required int count,
    required String monthKey,
    required String addedBy,
  }) async {
    _loading = true;
    notifyListeners();

    final entry = CardEntryModel(
      id: _uuid.v4(),
      denomination: denomination,
      count: count,
      date: DateTime.now(),
      monthKey: monthKey,
      addedBy: addedBy,
    );

    await HiveService.addCardEntry(entry);
    try {
      await FirestoreService.syncCardEntry(entry);
    } catch (_) {}

    _entries = HiveService.getCardEntriesByMonth(monthKey);
    _loading = false;
    notifyListeners();
  }

  // حذف إدخال
  Future<void> deleteEntry(String id, String monthKey) async {
    await HiveService.deleteCardEntry(id);
    try {
      await FirestoreService.deleteCardEntry(id);
    } catch (_) {}
    _entries = HiveService.getCardEntriesByMonth(monthKey);
    notifyListeners();
  }

  // إجمالي الكروت حسب الفئة لشهر
  Map<int, int> getCountsByMonth(String monthKey) {
    return HiveService.getCardCountsByMonth(monthKey);
  }

  // إجمالي الإيرادات المتوقعة
  double getTotalRevenueForMonth(String monthKey) {
    return HiveService.getTotalCardRevenueByMonth(monthKey);
  }

  // بيانات الرسم البياني
  List<Map<String, dynamic>> getMonthlyRevenueChart(
      List<String> monthKeys) {
    return monthKeys.map((mk) {
      return {
        'month': mk,
        'total': HiveService.getTotalCardRevenueByMonth(mk),
      };
    }).toList();
  }

  // ── أسعار الكروت ─────────────────────────────────────
  List<CardPriceModel> getAllPrices() {
    return HiveService.cardPrices.values.toList()
      ..sort((a, b) => a.denomination.compareTo(b.denomination));
  }

  Future<void> updatePrice(int denomination, double price) async {
    await HiveService.updateCardPrice(denomination, price);
    notifyListeners();
    // مزامنة سحابية
    try {
      await FirestoreService.syncCardPrices(getAllPrices());
    } catch (_) {}
  }

  double getPriceFor(int denomination) {
    return HiveService.getCardPrice(denomination);
  }
}
