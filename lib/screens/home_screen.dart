import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winekeeper/models/wine_card.dart';
import 'package:winekeeper/models/wine_bottle.dart';
import 'package:winekeeper/screens/admin_users_screen.dart';
import 'package:winekeeper/screens/login_screen.dart';
import 'package:winekeeper/screens/add_wine_screen.dart';
import 'package:winekeeper/screens/wine_card_detail_screen.dart';
import 'package:winekeeper/core/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<WineCard> cardsBox;
  late Box<WineBottle> bottlesBox;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    cardsBox = Hive.box<WineCard>('wine_cards');
    bottlesBox = Hive.box<WineBottle>('wine_bottles');
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _deleteCard(WineCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить карточку вина?'),
        content: Text(
          'Вы уверены, что хотите удалить "${card.name}"?\n\n'
          'Это также удалит все привязанные к ней бутылки (${_getActiveBottlesCount(card.id)} шт.).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Удаляем все связанные бутылки
      final bottlesToDelete = bottlesBox.values
          .where((bottle) => bottle.cardId == card.id)
          .toList();

      for (final bottle in bottlesToDelete) {
        await bottlesBox.delete(bottle.id);
      }

      // Удаляем саму карточку
      await cardsBox.delete(card.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Карточка "${card.name}" удалена'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Подсчет активных бутылок для конкретной карточки
  int _getActiveBottlesCount(String cardId) {
    return bottlesBox.values
        .where((bottle) => bottle.cardId == cardId && bottle.isActive)
        .length;
  }

  // Подсчет общего объема для конкретной карточки
  double _getTotalVolume(WineCard card) {
    final activeCount = _getActiveBottlesCount(card.id);
    return activeCount * card.volume;
  }

  Color _getWineColor(String? color) {
    return AppTheme.getWineColor(color);
  }

  // Фильтрация карточек по поисковому запросу
  List<WineCard> _getFilteredCards() {
    if (searchQuery.isEmpty) {
      return cardsBox.values.toList();
    }

    return cardsBox.values.where((card) {
      return card.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (card.country?.toLowerCase().contains(searchQuery.toLowerCase()) ??
              false);
    }).toList();
  }

  // Добавление тестовых данных для отладки
  Future<void> _addTestData() async {
    // Создаем несколько тестовых карточек
    final testCards = [
      WineCard(
        id: WineCard.generateId(),
        name: 'Château Margaux',
        volume: 0.750,
        year: 2018,
        country: 'Франция',
        color: 'Красное',
        isSparkling: false,
      ),
      WineCard(
        id: WineCard.generateId(),
        name: 'Dom Pérignon',
        volume: 0.750,
        year: 2012,
        country: 'Франция',
        color: 'Белое',
        isSparkling: true,
      ),
      WineCard(
        id: WineCard.generateId(),
        name: 'Barolo Riserva',
        volume: 0.750,
        year: 2016,
        country: 'Италия',
        color: 'Красное',
        isSparkling: false,
      ),
    ];

    for (final card in testCards) {
      await cardsBox.put(card.id, card);

      // Для каждой карточки создаем несколько тестовых бутылок
      for (int i = 1; i <= 6; i++) {
        final bottle = WineBottle(
          id: WineBottle.generateId(),
          barcode: '${WineBottle.generateTestBarcode()}-$i',
          cardId: card.id,
        );
        await bottlesBox.put(bottle.id, bottle);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Тестовые данные добавлены'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text("Винотека",
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Кнопка тестовых данных (только для разработки)
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            tooltip: "Добавить тестовые данные",
            onPressed: _addTestData,
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: "Админ панель",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminUsersScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: "Выйти",
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Поле поиска
          if (cardsBox.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск вин...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              searchController.clear();
                              searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),

          // Список карточек вин
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: cardsBox.listenable(),
              builder: (context, Box<WineCard> box, _) {
                final filteredCards = _getFilteredCards();

                if (box.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wine_bar_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Винотека пуста",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Создайте первую карточку вина",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _addTestData,
                          icon: const Icon(Icons.bug_report),
                          label: const Text("Добавить тестовые данные"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (filteredCards.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Ничего не найдено",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ValueListenableBuilder(
                  valueListenable: bottlesBox.listenable(),
                  builder: (context, Box<WineBottle> bottleBox, _) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredCards.length,
                      itemBuilder: (context, index) {
                        final card = filteredCards[index];
                        final activeBottlesCount =
                            _getActiveBottlesCount(card.id);
                        final totalVolume = _getTotalVolume(card);

                        return Dismissible(
                          key: Key(card.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            await _deleteCard(card);
                            return false;
                          },
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.delete_outline,
                                    color: Colors.white, size: 24),
                                SizedBox(width: 8),
                                Text('Удалить',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16)),
                              ],
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      WineCardDetailScreen(cardId: card.id),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    // Цветной индикатор типа вина
                                    Container(
                                      width: 4,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: _getWineColor(card.color),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Основная информация
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  card.name,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              if (card.isSparkling)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                      left: 8),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.amber.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.bubble_chart,
                                                        size: 14,
                                                        color: Colors
                                                            .amber.shade700,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        "Игристое",
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Colors
                                                              .amber.shade700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            card.subtitle,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Показываем общий объем всех бутылок
                                          Text(
                                            'Общий объем: ${totalVolume.toStringAsFixed(3)} л',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Количество бутылок справа
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: activeBottlesCount > 0
                                            ? Colors.green.shade100
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            activeBottlesCount.toString(),
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: activeBottlesCount > 0
                                                  ? Colors.green.shade700
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            "бут.",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: activeBottlesCount > 0
                                                  ? Colors.green.shade600
                                                  : Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddWineScreen()),
          );
        },
        backgroundColor: const Color(0xFF4A90E2),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Создать карточку",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
