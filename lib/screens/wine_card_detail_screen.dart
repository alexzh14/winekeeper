import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winekeeper/models/wine_card.dart';
import 'package:winekeeper/models/wine_bottle.dart';
import 'package:winekeeper/screens/barcode_scanner_screen.dart';
import 'package:winekeeper/core/app_theme.dart';
import 'package:winekeeper/screens/edit_wine_screen.dart';

class WineCardDetailScreen extends StatefulWidget {
  final String cardId;

  const WineCardDetailScreen({super.key, required this.cardId});

  @override
  State<WineCardDetailScreen> createState() => _WineCardDetailScreenState();
}

class _WineCardDetailScreenState extends State<WineCardDetailScreen> {
  late Box<WineCard> cardsBox;
  late Box<WineBottle> bottlesBox;
  WineCard? wineCard;

  @override
  void initState() {
    super.initState();
    cardsBox = Hive.box<WineCard>('wine_cards');
    bottlesBox = Hive.box<WineBottle>('wine_bottles');
    _loadCard();
  }

  void _loadCard() {
    wineCard = cardsBox.get(widget.cardId);
    if (wineCard == null) {
      Navigator.pop(context);
    }
  }

  List<WineBottle> _getActiveBottles() {
    return bottlesBox.values
        .where((bottle) => bottle.cardId == widget.cardId && bottle.isActive)
        .toList();
  }

  List<WineBottle> _getSoldBottles() {
    return bottlesBox.values
        .where((bottle) => bottle.cardId == widget.cardId && !bottle.isActive)
        .toList();
  }

  Color _getWineColor(String? color) {
    return AppTheme.getWineColor(color);
  }

  Future<void> _sellBottleManually(WineBottle bottle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Продать бутылку?'),
        content: Text('Продать бутылку со штрихкодом:\n${bottle.barcode}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Продать'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      bottle.isActive = false;
      await bottlesBox.put(bottle.id, bottle);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Бутылка ${bottle.barcode} продана'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (wineCard == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          wineCard!.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: bottlesBox.listenable(),
        builder: (context, Box<WineBottle> box, _) {
          final activeBottles = _getActiveBottles();
          final soldBottles = _getSoldBottles();
          final totalVolume = activeBottles.length * wineCard!.volume;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Основная информация о карточке
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [AppTheme.softShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Цветной индикатор
                        Container(
                          width: 6,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getWineColor(wineCard!.color),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                wineCard!.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                wineCard!.subtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (wineCard!.isSparkling)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bubble_chart,
                                    size: 14, color: Colors.amber.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  "Игристое",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Статистика
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  activeBottles.length.toString(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                Text(
                                  'В наличии',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${totalVolume.toStringAsFixed(3)} л',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                Text(
                                  'Общий объем',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  soldBottles.length.toString(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  'Продано',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Кнопки действий - вертикальное размещение
              Column(
                children: [
                  // Кнопка редактирования карточки
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final updatedCard = await Navigator.push<WineCard>(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditWineScreen(wineCard: wineCard!),
                          ),
                        );
                        if (updatedCard != null) {
                          setState(() {
                            wineCard = updatedCard;
                          });
                        }
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Редактировать карточку'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Кнопка добавления бутылок
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BarcodeScannerScreen(
                              wineCard: wineCard!,
                              mode: 'add',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Добавить бутылки'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Кнопка продажи
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: activeBottles.isNotEmpty
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BarcodeScannerScreen(
                                    wineCard: wineCard!,
                                    mode: 'sell',
                                  ),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      label: const Text('Продать бутылку'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warning,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Список активных бутылок
              if (activeBottles.isNotEmpty) ...[
                Text(
                  'Бутылки в наличии (${activeBottles.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                ...activeBottles.map((bottle) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [AppTheme.softShadow],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.qr_code, color: Colors.grey.shade600),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bottle.barcode,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Добавлена: ${bottle.createdAt.day.toString().padLeft(2, '0')}.${bottle.createdAt.month.toString().padLeft(2, '0')}.${bottle.createdAt.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _sellBottleManually(bottle),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange,
                          ),
                          child: const Text('Продать'),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],

              if (activeBottles.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Нет бутылок в наличии',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Отсканируйте штрихкоды бутылок чтобы добавить их в карточку',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Проданные бутылки (свернуто)
              if (soldBottles.isNotEmpty) ...[
                ExpansionTile(
                  title: Text('Проданные бутылки (${soldBottles.length})'),
                  leading: Icon(Icons.history, color: Colors.grey.shade600),
                  children: soldBottles.map((bottle) {
                    return ListTile(
                      leading: Icon(Icons.qr_code, color: Colors.grey.shade400),
                      title: Text(
                        bottle.barcode,
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      subtitle: Text(
                        'Продана: ${bottle.createdAt.day.toString().padLeft(2, '0')}.${bottle.createdAt.month.toString().padLeft(2, '0')}.${bottle.createdAt.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
