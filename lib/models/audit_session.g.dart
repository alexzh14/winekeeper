// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuditSessionAdapter extends TypeAdapter<AuditSession> {
  @override
  final int typeId = 3;

  @override
  AuditSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuditSession(
      id: fields[0] as String,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime?,
      status: fields[3] as String,
      expectedBottles: (fields[4] as Map?)?.cast<String, int>(),
      expectedBarcodes: (fields[5] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<String>())),
      scannedBarcodes: (fields[6] as List?)?.cast<String>(),
      foundBottles: (fields[7] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<String>())),
      notes: fields[8] as String?,
      soldBottlesDuringAudit: (fields[9] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<String>())),
      lastSyncTime: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AuditSession obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.expectedBottles)
      ..writeByte(5)
      ..write(obj.expectedBarcodes)
      ..writeByte(6)
      ..write(obj.scannedBarcodes)
      ..writeByte(7)
      ..write(obj.foundBottles)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.soldBottlesDuringAudit)
      ..writeByte(10)
      ..write(obj.lastSyncTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
