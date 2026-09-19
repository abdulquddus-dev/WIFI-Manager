// lib/models/card_price_model.dart
import 'package:hive/hive.dart';

part 'card_price_model.g.dart';

@HiveType(typeId: 2)
class CardPriceModel extends HiveObject {
  @HiveField(0)
  int denomination; // الفئة

  @HiveField(1)
  double price; // سعر البيع للكرت الواحد

  CardPriceModel({
    required this.denomination,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'denomination': denomination,
      'price': price,
    };
  }

  factory CardPriceModel.fromMap(Map<String, dynamic> map) {
    return CardPriceModel(
      denomination: map['denomination'],
      price: (map['price'] as num).toDouble(),
    );
  }

  // الأسعار الافتراضية (يمكن تعديلها من الإعدادات)
  static Map<int, double> defaultPrices = {
    100: 100,
    200: 200,
    300: 300,
    500: 500,
    1000: 1000,
    3000: 3000,
    5000: 5000,
    10000: 10000,
  };
}
