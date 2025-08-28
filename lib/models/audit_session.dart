import 'package:hive/hive.dart';

part 'audit_session.g.dart';

@HiveType(typeId: 3) // Новый typeId для ревизий
class AuditSession {
  @HiveField(0)
  String id;

  @HiveField(1) 
  DateTime startTime; // Когда началась ревизия

  @HiveField(2)
  DateTime? endTime; // Когда завершена (null = активная)

  @HiveField(3)
  String status; // 'active', 'completed', 'paused'

  @HiveField(4)
  Map<String, int> expectedBottles; // cardId -> ожидаемое количество на момент начала

  @HiveField(5)
  Map<String, List<String>> expectedBarcodes; // cardId -> [список ожидаемых штрихкодов]

  @HiveField(6)
  List<String> scannedBarcodes; // УЖЕ отсканированные штрихкоды 

  @HiveField(7)
  Map<String, List<String>> foundBottles; // cardId -> [найденные штрихкоды]

  @HiveField(8)
  String? notes; // Заметки к ревизии

  // Константы статусов
  static const String STATUS_ACTIVE = 'active';
  static const String STATUS_COMPLETED = 'completed'; 
  static const String STATUS_PAUSED = 'paused';

  AuditSession({
    required this.id,
    required this.startTime,
    this.endTime,
    this.status = STATUS_ACTIVE,
    Map<String, int>? expectedBottles,
    Map<String, List<String>>? expectedBarcodes,
    List<String>? scannedBarcodes,
    Map<String, List<String>>? foundBottles,
    this.notes,
  })  : expectedBottles = expectedBottles ?? {},
        expectedBarcodes = expectedBarcodes ?? {},
        scannedBarcodes = scannedBarcodes ?? <String>[],
        foundBottles = foundBottles ?? {};

  // Генерация уникального ID для новой ревизии
  static String generateId() {
    return 'audit_${DateTime.now().millisecondsSinceEpoch}';
  }

  // ВЫЧИСЛЯЕМЫЕ ПОЛЯ ДЛЯ СТАТИСТИКИ

  /// Общее количество ожидаемых бутылок
  int get totalExpected => expectedBottles.values.fold(0, (a, b) => a + b);

  /// Общее количество отсканированных бутылок  
  int get totalScanned => scannedBarcodes.length;

  /// Прогресс ревизии в процентах
  double get progressPercent => totalExpected > 0 ? (totalScanned / totalExpected * 100) : 0;

  /// Количество обработанных карточек (в которых хоть что-то нашли)
  int get processedCardsCount => foundBottles.length;

  /// Общее количество карточек в ревизии
  int get totalCardsCount => expectedBottles.length;

  /// Количество найденных бутылок (только известных из базы)
  int get totalFoundBottles => foundBottles.values.fold(0, (sum, barcodes) => sum + barcodes.length);

  /// Количество неизвестных бутылок (отсканированных, но не из нашей базы)
  int get unknownBottlesCount => totalScanned - totalFoundBottles;

  /// Активна ли ревизия
  bool get isActive => status == STATUS_ACTIVE;

  /// Завершена ли ревизия
  bool get isCompleted => status == STATUS_COMPLETED;

  /// Длительность ревизии
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Красивое отображение длительности
  String get displayDuration {
    final d = duration;
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}ч ${minutes}мин';
    } else {
      return '${minutes}мин';
    }
  }

  /// Проверка, была ли уже отсканирована бутылка
  bool isBottleScanned(String barcode) {
    return scannedBarcodes.contains(barcode);
  }

  /// Добавление отсканированного штрихкода
  void addScannedBarcode(String barcode) {
    if (!scannedBarcodes.contains(barcode)) {
      scannedBarcodes.add(barcode);
    }
  }

  /// Добавление найденной бутылки к карточке
  void addFoundBottle(String cardId, String barcode) {
    foundBottles[cardId] ??= <String>[];
    if (!foundBottles[cardId]!.contains(barcode)) {
      foundBottles[cardId]!.add(barcode);
    }
  }

  /// Завершение ревизии
  void complete() {
    status = STATUS_COMPLETED;
    endTime = DateTime.now();
  }

  /// Постановка на паузу
  void pause() {
    status = STATUS_PAUSED;
  }

  /// Возобновление ревизии
  void resume() {
    status = STATUS_ACTIVE;
  }

  /// Расчет расхождений для конкретной карточки
  int getDiscrepancy(String cardId) {
    final expected = expectedBottles[cardId] ?? 0;
    final found = foundBottles[cardId]?.length ?? 0;
    return found - expected; // положительное = излишек, отрицательное = недостача
  }

  /// Получить все расхождения (только карточки с расхождениями)
  Map<String, int> getDiscrepancies() {
    final discrepancies = <String, int>{};
    
    for (final cardId in expectedBottles.keys) {
      final discrepancy = getDiscrepancy(cardId);
      if (discrepancy != 0) {
        discrepancies[cardId] = discrepancy;
      }
    }
    
    return discrepancies;
  }

  /// Есть ли расхождения в ревизии
  bool get hasDiscrepancies => getDiscrepancies().isNotEmpty;

  /// Общее количество карточек с расхождениями
  int get discrepanciesCount => getDiscrepancies().length;

  /// Краткое описание ревизии для списков
  String get summary {
    if (isActive) {
      return 'Активная • ${progressPercent.toStringAsFixed(0)}% • $displayDuration';
    } else {
      return 'Завершена • $displayDuration • ${discrepanciesCount > 0 ? '$discrepanciesCount расхождений' : 'Без расхождений'}';
    }
  }
}