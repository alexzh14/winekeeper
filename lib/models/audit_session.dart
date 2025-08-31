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

  @HiveField(9)
  Map<String, List<String>> soldBottlesDuringAudit; // cardId -> [проданные штрихкоды во время ревизии]

  @HiveField(10)
  DateTime? lastSyncTime; // когда последний раз синхронизировались

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
    Map<String, List<String>>? soldBottlesDuringAudit,
    this.lastSyncTime,
  })  : expectedBottles = expectedBottles ?? {},
        expectedBarcodes = expectedBarcodes ?? {},
        scannedBarcodes = scannedBarcodes ?? <String>[],
        foundBottles = foundBottles ?? {},
        soldBottlesDuringAudit = soldBottlesDuringAudit ?? {};

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

  /// Количество бутылок, проданных во время ревизии
  int get soldBottlesCount {
    return soldBottlesDuringAudit.values
        .fold(0, (sum, barcodes) => sum + barcodes.length);
  }

  /// Нужна ли синхронизация (прошло больше минуты с последней)
  bool get needsSync {
    if (!isActive) return false;
    if (lastSyncTime == null) return true;
    
    final now = DateTime.now();
    final timeSinceSync = now.difference(lastSyncTime!);
    return timeSinceSync.inMinutes >= 1; // Синхронизируем если прошла минута
  }

  /// Краткая информация о проданных бутылках для отображения
  String get soldBottlesSummary {
    if (soldBottlesCount == 0) return '';
    return 'Продано во время ревизии: $soldBottlesCount бут.';
  }

  // МЕТОДЫ УПРАВЛЕНИЯ РЕВИЗИЕЙ

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

  // МЕТОДЫ АНАЛИЗА РАСХОЖДЕНИЙ

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

  // СИНХРОНИЗАЦИЯ С ТЕКУЩИМ СОСТОЯНИЕМ ВИНОТЕКИ

  /// Синхронизация с текущим состоянием винотеки
  /// Возвращает информацию об изменениях для уведомления пользователя
  Map<String, dynamic> syncWithCurrentState(Box bottlesBox, Box cardsBox) {
    if (!isActive) return {'hasChanges': false}; // Не синхронизируем завершенные ревизии
    
    final changes = <String, dynamic>{
      'hasChanges': false,
      'soldBottles': <String, String>{}, // barcode -> cardName
      'removedFromExpected': 0,
      'removedFromScanned': 0,
    };
    
    final now = DateTime.now();
    final newSoldBottles = <String, List<String>>{};
    int totalRemovedExpected = 0;
    int totalRemovedScanned = 0;
    
    // Проходим по всем ожидаемым бутылкам
    for (final cardId in expectedBarcodes.keys.toList()) {
      final expectedForCard = expectedBarcodes[cardId] ?? [];
      final soldForCard = <String>[];
      
      for (final barcode in expectedForCard.toList()) {
        // Проверяем, активна ли еще бутылка
        final bottle = bottlesBox.values
            .where((b) => b.barcode == barcode)
            .firstOrNull;
            
        if (bottle == null || !bottle.isActive) {
          // Бутылка продана или удалена
          soldForCard.add(barcode);
          
          // Удаляем из ожидаемых
          expectedBarcodes[cardId]?.remove(barcode);
          totalRemovedExpected++;
          
          // Если была отсканирована - удаляем и оттуда
          if (scannedBarcodes.contains(barcode)) {
            scannedBarcodes.remove(barcode);
            foundBottles[cardId]?.remove(barcode);
            totalRemovedScanned++;
          }
          
          // Добавляем в информацию об изменениях
          final card = cardsBox.get(cardId);
          final cardName = card?.name ?? 'Неизвестная карточка';
          changes['soldBottles'][barcode] = cardName;
          changes['hasChanges'] = true;
        }
      }
      
      if (soldForCard.isNotEmpty) {
        newSoldBottles[cardId] = soldForCard;
      }
      
      // Обновляем количество ожидаемых бутылок для карточки
      final remainingCount = expectedBarcodes[cardId]?.length ?? 0;
      if (remainingCount > 0) {
        expectedBottles[cardId] = remainingCount;
      } else {
        // Если не осталось бутылок - удаляем карточку из ревизии
        expectedBottles.remove(cardId);
        expectedBarcodes.remove(cardId);
        foundBottles.remove(cardId);
      }
    }
    
    // Обновляем информацию о проданных бутылках
    if (newSoldBottles.isNotEmpty) {
      for (final cardId in newSoldBottles.keys) {
        soldBottlesDuringAudit[cardId] ??= <String>[];
        soldBottlesDuringAudit[cardId]!.addAll(newSoldBottles[cardId]!);
      }
    }
    
    // Обновляем время последней синхронизации
    lastSyncTime = now;
    
    // Дополняем информацию об изменениях
    changes['removedFromExpected'] = totalRemovedExpected;
    changes['removedFromScanned'] = totalRemovedScanned;
    
    return changes;
  }

  /// Принудительная очистка проданной бутылки из всех списков ревизии
  void removeBottleFromAudit(String barcode, String cardId) {
    // Удаляем из ожидаемых
    expectedBarcodes[cardId]?.remove(barcode);
    
    // Удаляем из отсканированных
    scannedBarcodes.remove(barcode);
    
    // Удаляем из найденных
    foundBottles[cardId]?.remove(barcode);
    
    // Добавляем в проданные
    soldBottlesDuringAudit[cardId] ??= <String>[];
    if (!soldBottlesDuringAudit[cardId]!.contains(barcode)) {
      soldBottlesDuringAudit[cardId]!.add(barcode);
    }
    
    // Обновляем количество ожидаемых для карточки
    final remainingCount = expectedBarcodes[cardId]?.length ?? 0;
    if (remainingCount > 0) {
      expectedBottles[cardId] = remainingCount;
    } else {
      // Если не осталось бутылок - удаляем карточку из ревизии
      expectedBottles.remove(cardId);
      expectedBarcodes.remove(cardId);
      foundBottles.remove(cardId);
    }
    
    // Обновляем время синхронизации
    lastSyncTime = DateTime.now();
  }

  /// Краткое описание ревизии для списков
  String get summary {
    if (isActive) {
      final soldInfo = soldBottlesCount > 0 ? ' • Продано: $soldBottlesCount' : '';
      return 'Активная • ${progressPercent.toStringAsFixed(0)}% • $displayDuration$soldInfo';
    } else {
      final discrepancyInfo = discrepanciesCount > 0 ? '$discrepanciesCount расхождений' : 'Без расхождений';
      final soldInfo = soldBottlesCount > 0 ? ' • Продано: $soldBottlesCount' : '';
      return 'Завершена • $displayDuration • $discrepancyInfo$soldInfo';
    }
  }

  /// Получить статистику для отображения в интерфейсе
  Map<String, dynamic> getDisplayStats() {
    return {
      'totalExpected': totalExpected,
      'totalScanned': totalScanned,
      'totalFoundBottles': totalFoundBottles,
      'unknownBottlesCount': unknownBottlesCount,
      'soldBottlesCount': soldBottlesCount,
      'progressPercent': progressPercent,
      'discrepanciesCount': discrepanciesCount,
      'isActive': isActive,
      'displayDuration': displayDuration,
      'hasChanges': soldBottlesCount > 0 || hasDiscrepancies || unknownBottlesCount > 0,
    };
  }

  /// Валидация целостности данных ревизии
  bool validate() {
    try {
      // Проверяем, что все ожидаемые штрихкоды соответствуют количеству
      for (final cardId in expectedBottles.keys) {
        final expectedCount = expectedBottles[cardId] ?? 0;
        final barcodesCount = expectedBarcodes[cardId]?.length ?? 0;
        if (expectedCount != barcodesCount) {
          return false;
        }
      }
      
      // Проверяем, что все найденные бутылки есть в отсканированных
      for (final barcodes in foundBottles.values) {
        for (final barcode in barcodes) {
          if (!scannedBarcodes.contains(barcode)) {
            return false;
          }
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Создание копии ревизии (для тестирования или восстановления)
  AuditSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    Map<String, int>? expectedBottles,
    Map<String, List<String>>? expectedBarcodes,
    List<String>? scannedBarcodes,
    Map<String, List<String>>? foundBottles,
    String? notes,
    Map<String, List<String>>? soldBottlesDuringAudit,
    DateTime? lastSyncTime,
  }) {
    return AuditSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      expectedBottles: expectedBottles ?? Map<String, int>.from(this.expectedBottles),
      expectedBarcodes: expectedBarcodes ?? Map<String, List<String>>.from(
        this.expectedBarcodes.map((k, v) => MapEntry(k, List<String>.from(v)))
      ),
      scannedBarcodes: scannedBarcodes ?? List<String>.from(this.scannedBarcodes),
      foundBottles: foundBottles ?? Map<String, List<String>>.from(
        this.foundBottles.map((k, v) => MapEntry(k, List<String>.from(v)))
      ),
      notes: notes ?? this.notes,
      soldBottlesDuringAudit: soldBottlesDuringAudit ?? Map<String, List<String>>.from(
        this.soldBottlesDuringAudit.map((k, v) => MapEntry(k, List<String>.from(v)))
      ),
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  @override
  String toString() {
    return 'AuditSession{id: $id, status: $status, expected: $totalExpected, scanned: $totalScanned, sold: $soldBottlesCount}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuditSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}