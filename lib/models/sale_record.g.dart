// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SaleRecordAdapter extends TypeAdapter<SaleRecord> {
  @override
  final int typeId = 2;

  @override
  SaleRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SaleRecord(
      id: fields[0] as String,
      bottleId: fields[1] as String,
      cardId: fields[2] as String,
      sellerId: fields[3] as String,
      reason: fields[5] as String,
      method: fields[6] as String,
      timestamp: fields[4] as DateTime?,
      notes: fields[7] as String?,
      price: fields[8] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, SaleRecord obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bottleId)
      ..writeByte(2)
      ..write(obj.cardId)
      ..writeByte(3)
      ..write(obj.sellerId)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.reason)
      ..writeByte(6)
      ..write(obj.method)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.price);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
