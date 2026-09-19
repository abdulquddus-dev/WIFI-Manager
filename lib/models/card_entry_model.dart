// lib/models/card_entry_model.dart
import 'package:hive/hive.dart';

part 'card_entry_model.g.dart';

@HiveType(typeId: 1)
class CardEntryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int denomination; // الفئة: 100, 200, 300, 500, 1000, 3000, 5000, 10000

  @HiveField(2)
  int count; // عدد الكروت المضافة في هذه العملية

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String monthKey; // مثال: "2024-01"

  @HiveField(5)
  String addedBy;

  CardEntryModel({
    required this.id,
    required this.denomination,
    required this.count,
    required this.date,
    required this.monthKey,
    required this.addedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'denomination': denomination,
      'count': count,
      'date': date.toIso8601String(),
      'monthKey': monthKey,
      'addedBy': addedBy,
    };
  }

  factory CardEntryModel.fromMap(Map<String, dynamic> map) {
    return CardEntryModel(
      id: map['id'],
      denomination: map['denomination'],
      count: map['count'],
      date: DateTime.parse(map['date']),
      monthKey: map['monthKey'],
      addedBy: map['addedBy'],
    );
  }
}

// فئات الكروت
class CardDenominations {
  static const List<int> values = [100, 200, 300, 500, 1000, 3000, 5000, 10000];
}
