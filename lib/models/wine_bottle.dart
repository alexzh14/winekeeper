import 'package:hive/hive.dart';

part 'wine_bottle.g.dart';

@HiveType(typeId: 1) // изменил ID, так как это теперь другая сущность
class WineBottle {
  @HiveField(0)
  String id; // уникальный ID бутылки

  @HiveField(1)
  String barcode; // штрихкод бутылки (уникальный)

  @HiveField(2)
  String cardId; // ID карточки вина к которой привязана

  @HiveField(3)
  bool isActive; // true = на складе, false = продана/списана

  @HiveField(4)
  DateTime createdAt; // когда добавлена в систему

  @HiveField(5)
  String? notes; // заметки к конкретной бутылке

  WineBottle({
    required this.id,
    required this.barcode,
    required this.cardId,
    this.isActive = true,
    DateTime? createdAt,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  // Генерация уникального ID для новой бутылки
  static String generateId() {
    return 'bottle_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Генерация тестового штрихкода
  static String generateTestBarcode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'TEST-${timestamp.toString().substring(8)}'; // TEST-12345
  }
}