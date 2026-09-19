// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';
import '../models/card_entry_model.dart';
import '../models/card_price_model.dart';
import '../models/app_user_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── المستخدمون ────────────────────────────────────────
  static Future<void> saveUser(AppUserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  static Future<AppUserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) return AppUserModel.fromMap(doc.data()!);
    return null;
  }

  static Future<List<AppUserModel>> getAllUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs.map((d) => AppUserModel.fromMap(d.data())).toList();
  }

  static Future<void> updateUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({'role': role});
  }

  // ── المصاريف ─────────────────────────────────────────
  static Future<void> syncExpense(ExpenseModel expense) async {
    await _db
        .collection('expenses')
        .doc(expense.id)
        .set(expense.toMap());
  }

  static Future<void> deleteExpense(String id) async {
    await _db.collection('expenses').doc(id).delete();
  }

  static Future<List<ExpenseModel>> getExpensesByMonth(
      String monthKey) async {
    final snap = await _db
        .collection('expenses')
        .where('monthKey', isEqualTo: monthKey)
        .get();
    return snap.docs
        .map((d) => ExpenseModel.fromMap(d.data()))
        .toList();
  }

  // ── الكروت ────────────────────────────────────────────
  static Future<void> syncCardEntry(CardEntryModel entry) async {
    await _db
        .collection('card_entries')
        .doc(entry.id)
        .set(entry.toMap());
  }

  static Future<void> deleteCardEntry(String id) async {
    await _db.collection('card_entries').doc(id).delete();
  }

  static Future<List<CardEntryModel>> getCardEntriesByMonth(
      String monthKey) async {
    final snap = await _db
        .collection('card_entries')
        .where('monthKey', isEqualTo: monthKey)
        .get();
    return snap.docs
        .map((d) => CardEntryModel.fromMap(d.data()))
        .toList();
  }

  // ── أسعار الكروت ─────────────────────────────────────
  static Future<void> syncCardPrices(
      List<CardPriceModel> prices) async {
    final batch = _db.batch();
    for (final p in prices) {
      final ref = _db
          .collection('card_prices')
          .doc(p.denomination.toString());
      batch.set(ref, p.toMap());
    }
    await batch.commit();
  }

  static Future<List<CardPriceModel>> getCardPrices() async {
    final snap = await _db.collection('card_prices').get();
    return snap.docs
        .map((d) => CardPriceModel.fromMap(d.data()))
        .toList();
  }

  // ── مزامنة كاملة: سحب البيانات من السحابة ────────────
  static Future<Map<String, dynamic>> pullAllDataForMonth(
      String monthKey) async {
    final expenses = await getExpensesByMonth(monthKey);
    final cards = await getCardEntriesByMonth(monthKey);
    return {'expenses': expenses, 'cards': cards};
  }
}
