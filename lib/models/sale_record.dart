import 'package:hive/hive.dart';

part 'sale_record.g.dart';

@HiveType(typeId: 2)
class SaleRecord {
  @HiveField(0)
  String id;

  @HiveField(1)
  String bottleId; // ID проданной бутылки

  @HiveField(2)
  String cardId; // ID карточки вина

  @HiveField(3)
  String sellerId; // ID пользователя который продал

  @HiveField(4)
  DateTime timestamp; // когда произошла операция

  @HiveField(5)
  String reason; // причина: "sale", "damage", "theft", "write_off"

  @HiveField(6)
  String method; // способ: "scan", "manual"

  @HiveField(7)
  String? notes; // дополнительные заметки

  @HiveField(8)
  double? price; // цена продажи (опционально)

  SaleRecord({
    required this.id,
    required this.bottleId,
    required this.cardId,
    required this.sellerId,
    required this.reason,
    required this.method,
    DateTime? timestamp,
    this.notes,
    this.price,
  }) : timestamp = timestamp ?? DateTime.now();

  // Генерация уникального ID
  static String generateId() {
    return 'sale_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Константы для причин
  static const String REASON_SALE = 'sale';
  static const String REASON_DAMAGE = 'damage';
  static const String REASON_THEFT = 'theft';
  static const String REASON_WRITE_OFF = 'write_off';

  // Константы для методов
  static const String METHOD_SCAN = 'scan';
  static const String METHOD_MANUAL = 'manual';

  // Красивые названия причин
  static const Map<String, String> reasonNames = {
    REASON_SALE: 'Продажа',
    REASON_DAMAGE: 'Брак/Порча',
    REASON_THEFT: 'Кража',
    REASON_WRITE_OFF: 'Списание',
  };

  // Красивые названия методов
  static const Map<String, String> methodNames = {
    METHOD_SCAN: 'Сканирование',
    METHOD_MANUAL: 'Вручную',
  };

  // Получить красивое название причины
  String get displayReason => reasonNames[reason] ?? reason;

  // Получить красивое название метода
  String get displayMethod => methodNames[method] ?? method;

  // Форматированная дата и время
  String get displayTimestamp {
    return '${timestamp.day.toString().padLeft(2, '0')}.${timestamp.month.toString().padLeft(2, '0')}.${timestamp.year} '
           '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}