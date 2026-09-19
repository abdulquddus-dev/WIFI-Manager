// lib/models/expense_model.dart
import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String category; // نوع المعدة أو "باقة الإنترنت"

  @HiveField(2)
  String description; // وصف تفصيلي

  @HiveField(3)
  double amount; // المبلغ

  @HiveField(4)
  DateTime date; // التاريخ

  @HiveField(5)
  String monthKey; // مثال: "2024-01"

  @HiveField(6)
  String addedBy; // المستخدم الذي أضاف السجل

  ExpenseModel({
    required this.id,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    required this.monthKey,
    required this.addedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'monthKey': monthKey,
      'addedBy': addedBy,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'],
      category: map['category'],
      description: map['description'],
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      monthKey: map['monthKey'],
      addedBy: map['addedBy'],
    );
  }
}

// فئات المصاريف الثابتة
class ExpenseCategories {
  static const List<String> items = [
    'باقة الإنترنت',
    'لوح شمسي',
    'بطارية',
    'عاكس شاشة(إنفرتر)',
    'أنتينا',
    'رأس الشبكة',
    'موديم',
    'كابل',
    'وصلات LAN',
    'ورق طباعة',
    'حامل/تركيب',
    'صيانة',
    'أخرى',
  ];
}
