// GENERATED CODE - DO NOT MODIFY BY HAND
// lib/models/debt_model.g.dart

part of 'debt_model.dart';

class DebtModelAdapter extends TypeAdapter<DebtModel> {
  @override
  final int typeId = 3;

  @override
  DebtModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      // ignore: curly_braces_in_flow_control_structures
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DebtModel(
      id: fields[0] as String,
      personName: fields[1] as String,
      type: fields[2] as String,
      amount: fields[3] as double,
      paidAmount: fields[4] as double,
      description: fields[5] as String,
      date: fields[6] as DateTime,
      monthKey: fields[7] as String,
      addedBy: fields[8] as String,
      isSettled: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DebtModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.personName)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.paidAmount)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.monthKey)
      ..writeByte(8)
      ..write(obj.addedBy)
      ..writeByte(9)
      ..write(obj.isSettled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
