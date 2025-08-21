import 'package:hive/hive.dart';

part 'wine_bottle.g.dart'; // для генерации адаптера

@HiveType(typeId: 0) // уникальный ID модели
class WineBottle {
  @HiveField(0)
  String name;

  @HiveField(1)
  int? year;

  @HiveField(2)
  String? country;

  @HiveField(3)
  String? color; // например: "красное", "белое", "розовое"

  @HiveField(4)
  bool isSparkling; // игристое или нет

  @HiveField(5)
  int quantity;

  @HiveField(6)
  String? barcode; // данные со штрихкода (может быть null, если вручную внесли)

  WineBottle({
    required this.name,
    this.year,
    this.country,
    this.color,
    this.isSparkling = false,
    required this.quantity,
    this.barcode,
  });
}
