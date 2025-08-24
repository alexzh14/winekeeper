// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wine_card.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WineCardAdapter extends TypeAdapter<WineCard> {
  @override
  final int typeId = 0;

  @override
  WineCard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WineCard(
      id: fields[0] as String,
      name: fields[1] as String,
      volume: fields[6] as double,
      year: fields[2] as int?,
      country: fields[3] as String?,
      color: fields[4] as String?,
      isSparkling: fields[5] as bool,
      createdAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, WineCard obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.year)
      ..writeByte(3)
      ..write(obj.country)
      ..writeByte(4)
      ..write(obj.color)
      ..writeByte(5)
      ..write(obj.isSparkling)
      ..writeByte(6)
      ..write(obj.volume)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WineCardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
