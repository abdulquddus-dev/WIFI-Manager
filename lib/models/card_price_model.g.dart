// GENERATED CODE - DO NOT MODIFY BY HAND
// lib/models/card_price_model.g.dart

part of 'card_price_model.dart';

class CardPriceModelAdapter extends TypeAdapter<CardPriceModel> {
  @override
  final int typeId = 2;

  @override
  CardPriceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      // ignore: curly_braces_in_flow_control_structures
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CardPriceModel(
      denomination: fields[0] as int,
      price: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CardPriceModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.denomination)
      ..writeByte(1)
      ..write(obj.price);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardPriceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
