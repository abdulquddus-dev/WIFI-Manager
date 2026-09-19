// GENERATED CODE - DO NOT MODIFY BY HAND
// lib/models/card_entry_model.g.dart

part of 'card_entry_model.dart';

class CardEntryModelAdapter extends TypeAdapter<CardEntryModel> {
  @override
  final int typeId = 1;

  @override
  CardEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      // ignore: curly_braces_in_flow_control_structures
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CardEntryModel(
      id: fields[0] as String,
      denomination: fields[1] as int,
      count: fields[2] as int,
      date: fields[3] as DateTime,
      monthKey: fields[4] as String,
      addedBy: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CardEntryModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.denomination)
      ..writeByte(2)
      ..write(obj.count)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.monthKey)
      ..writeByte(5)
      ..write(obj.addedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
