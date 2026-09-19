// lib/models/debt_model.dart
import 'package:hive/hive.dart';

part 'debt_model.g.dart';

@HiveType(typeId: 3)
class DebtModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String personName; // اسم المدين أو الدائن

  @HiveField(2)
  String type; // 'لي' = الشخص مدين لي | 'عليّ' = أنا المدين

  @HiveField(3)
  double amount; // المبلغ الأصلي

  @HiveField(4)
  double paidAmount; // المبلغ المدفوع حتى الآن

  @HiveField(5)
  String description; // وصف الدين

  @HiveField(6)
  DateTime date; // تاريخ الدين

  @HiveField(7)
  String monthKey;

  @HiveField(8)
  String addedBy;

  @HiveField(9)
  bool isSettled; // هل تمت تسويته؟

  DebtModel({
    required this.id,
    required this.personName,
    required this.type,
    required this.amount,
    this.paidAmount = 0,
    required this.description,
    required this.date,
    required this.monthKey,
    required this.addedBy,
    this.isSettled = false,
  });

  double get remainingAmount => amount - paidAmount;
  double get paidPercent => amount > 0 ? (paidAmount / amount) : 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'personName': personName,
        'type': type,
        'amount': amount,
        'paidAmount': paidAmount,
        'description': description,
        'date': date.toIso8601String(),
        'monthKey': monthKey,
        'addedBy': addedBy,
        'isSettled': isSettled,
      };

  factory DebtModel.fromMap(Map<String, dynamic> map) => DebtModel(
        id: map['id'],
        personName: map['personName'],
        type: map['type'],
        amount: (map['amount'] as num).toDouble(),
        paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
        description: map['description'] ?? '',
        date: DateTime.parse(map['date']),
        monthKey: map['monthKey'],
        addedBy: map['addedBy'] ?? '',
        isSettled: map['isSettled'] ?? false,
      );
}
