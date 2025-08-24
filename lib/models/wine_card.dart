import 'package:hive/hive.dart';

part 'wine_card.g.dart';

@HiveType(typeId: 0) // используем старый ID, так как это основная сущность
class WineCard {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name; // название вина

  @HiveField(2)
  int? year; // год урожая

  @HiveField(3)
  String? country; // страна происхождения

  @HiveField(4)
  String? color; // цвет: "Красное", "Белое", "Розовое", "Оранжевое"

  @HiveField(5)
  bool isSparkling; // игристое или тихое

  @HiveField(6)
  double volume; // объем ОДНОЙ бутылки в литрах (0.75, 1.5 и т.д.)

  @HiveField(7)
  DateTime createdAt; // когда создана карточка

  WineCard({
    required this.id,
    required this.name,
    required this.volume,
    this.year,
    this.country,
    this.color,
    this.isSparkling = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Генерация уникального ID для новой карточки
  static String generateId() {
    return 'card_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Стандартные объемы бутылок для удобства выбора
  static const List<double> standardVolumes = [
    0.187, // Piccolo
    0.375, // Demi/Half
    0.750, // Стандартная
    1.500, // Magnum
    3.000, // Double Magnum
    6.000, // Imperial
  ];

  static const Map<double, String> volumeNames = {
    0.187: 'Piccolo (187 мл)',
    0.375: 'Demi (375 мл)', 
    0.750: 'Стандарт (750 мл)',
    1.500: 'Magnum (1,5 л)',
    3.000: 'Double Magnum (3 л)',
    6.000: 'Imperial (6 л)',
  };

  // Красивое отображение объема с 3 знаками после запятой
  String get displayVolume {
    return '${volume.toStringAsFixed(3)} л';
  }

  // Получить количество активных бутылок (будет вычисляться из базы)
  int getActiveBottlesCount() {
    final bottlesBox = Hive.box<WineBottle>('wine_bottles');
    return bottlesBox.values
        .where((bottle) => bottle.cardId == id && bottle.isActive)
        .length;
  }

  // Получить общий объем всех активных бутылок
  double getTotalVolume() {
    final activeCount = getActiveBottlesCount();
    return activeCount * volume;
  }

  // Красивое отображение общего объема
  String get displayTotalVolume {
    return '${getTotalVolume().toStringAsFixed(3)} л';
  }

  // Краткая информация для отображения в списках
  String get subtitle {
    final parts = <String>[];
    
    if (country != null) parts.add(country!);
    if (year != null) parts.add(year.toString());
    parts.add(displayVolume);
    if (isSparkling) parts.add('Игристое');
    
    return parts.join(' • ');
  }
}