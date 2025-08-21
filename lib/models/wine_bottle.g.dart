// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wine_bottle.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WineBottleAdapter extends TypeAdapter<WineBottle> {
  @override
  final int typeId = 0;

  @override
  WineBottle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WineBottle(
      name: fields[0] as String,
      year: fields[1] as int?,
      country: fields[2] as String?,
      color: fields[3] as String?,
      isSparkling: fields[4] as bool,
      quantity: fields[5] as int,
      barcode: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WineBottle obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.year)
      ..writeByte(2)
      ..write(obj.country)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.isSparkling)
      ..writeByte(5)
      ..write(obj.quantity)
      ..writeByte(6)
      ..write(obj.barcode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WineBottleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
