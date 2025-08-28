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

enum SortBy { name, year, bottleCount }

class WineFilters {
  Set<String> colors = {};
  Set<String> countries = {};
  bool? onlyInStock;
  bool? onlySparkling;
  SortBy sortBy = SortBy.name;
  bool sortAscending = true;

  bool get hasActiveFilters =>
      colors.isNotEmpty ||
      countries.isNotEmpty ||
      onlyInStock == true ||
      onlySparkling != null;

  void clear() {
    colors.clear();
    countries.clear();
    onlyInStock = null;
    onlySparkling = null;
    sortBy = SortBy.name;
    sortAscending = true;
  }
}

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
  WineFilters filters = WineFilters();
  bool showFilters = false;

  @override
  void initState() {
    super.initState();
    cardsBox = Hive.box<WineCard>('wine_cards');
    bottlesBox = Hive.box<WineBottle>('wine_bottles');
  }

  Future<void> _logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', false);

  // Используем pushNamedAndRemoveUntil для полной перезагрузки
  Navigator.pushNamedAndRemoveUntil(
    context, 
    '/login',
    (route) => false,
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
            backgroundColor: AppTheme.error,
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

  List<WineCard> _getFilteredAndSortedCards() {
    var cards = cardsBox.values.toList();

    // Применяем поиск
    if (searchQuery.isNotEmpty) {
      cards = cards
          .where((card) =>
              card.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    // Применяем фильтры
    if (filters.colors.isNotEmpty) {
      cards =
          cards.where((card) => filters.colors.contains(card.color)).toList();
    }

    if (filters.countries.isNotEmpty) {
      cards = cards
          .where((card) =>
              card.country != null && filters.countries.contains(card.country))
          .toList();
    }

    if (filters.onlyInStock == true) {
      cards =
          cards.where((card) => _getActiveBottlesCount(card.id) > 0).toList();
    }

    if (filters.onlySparkling != null) {
      cards = cards
          .where((card) => card.isSparkling == filters.onlySparkling)
          .toList();
    }

    // Применяем сортировку
    cards.sort((a, b) {
      int comparison = 0;

      switch (filters.sortBy) {
        case SortBy.name:
          comparison = a.name.compareTo(b.name);
          break;
        case SortBy.year:
          final yearA = a.year ?? 0;
          final yearB = b.year ?? 0;
          comparison = yearA.compareTo(yearB);
          break;
        case SortBy.bottleCount:
          final countA = _getActiveBottlesCount(a.id);
          final countB = _getActiveBottlesCount(b.id);
          comparison = countA.compareTo(countB);
          break;
      }

      return filters.sortAscending ? comparison : -comparison;
    });

    return cards;
  }

  Widget _buildColorFilter() {
    final wineColors = ['Красное', 'Белое', 'Розовое', 'Оранжевое'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Цвет вина:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: wineColors.map((color) {
            final isSelected = filters.colors.contains(color);
            return FilterChip(
              label: Text(color),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    filters.colors.add(color);
                  } else {
                    filters.colors.remove(color);
                  }
                });
              },
              avatar: CircleAvatar(
                backgroundColor: _getWineColorByName(color),
                radius: 8,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCountryFilter() {
    final availableCountries = _getAvailableCountries().toList()..sort();

    if (availableCountries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Страна:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: availableCountries.map((country) {
            final isSelected = filters.countries.contains(country);
            return FilterChip(
              label: Text(country),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    filters.countries.add(country);
                  } else {
                    filters.countries.remove(country);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStockFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Наличие:', style: TextStyle(fontWeight: FontWeight.w500)),
        CheckboxListTile(
          title: const Text('Только в наличии'),
          value: filters.onlyInStock ?? false,
          onChanged: (value) {
            setState(() {
              filters.onlyInStock = value == true ? true : null;
            });
          },
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ],
    );
  }

  Widget _buildSparklingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Тип:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        DropdownButton<bool?>(
          value: filters.onlySparkling,
          hint: const Text('Все'),
          onChanged: (value) {
            setState(() {
              filters.onlySparkling = value;
            });
          },
          items: const [
            DropdownMenuItem(value: null, child: Text('Все')),
            DropdownMenuItem(value: true, child: Text('Игристое')),
            DropdownMenuItem(value: false, child: Text('Тихое')),
          ],
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Сортировка:',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButton<SortBy>(
                value: filters.sortBy,
                isExpanded: true,
                onChanged: (value) {
                  setState(() {
                    filters.sortBy = value!;
                  });
                },
                items: const [
                  DropdownMenuItem(
                      value: SortBy.name, child: Text('По названию')),
                  DropdownMenuItem(value: SortBy.year, child: Text('По году')),
                  DropdownMenuItem(
                      value: SortBy.bottleCount, child: Text('По количеству')),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: Icon(
                filters.sortAscending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                setState(() {
                  filters.sortAscending = !filters.sortAscending;
                });
              },
              tooltip: filters.sortAscending ? 'По возрастанию' : 'По убыванию',
            ),
          ],
        ),
      ],
    );
  }

  Color _getWineColorByName(String colorName) {
    switch (colorName) {
      case 'Красное':
        return AppTheme.wineRed;
      case 'Белое':
        return AppTheme.wineWhite;
      case 'Розовое':
        return AppTheme.wineRose;
      case 'Оранжевое':
        return AppTheme.wineOrange;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Set<String> _getAvailableCountries() {
    return cardsBox.values
        .where((card) => card.country != null)
        .map((card) => card.country!)
        .toSet();
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
    return _getFilteredAndSortedCards(); // Используем новый метод с фильтрами
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Винотека",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface, // Ivory
        foregroundColor:
            Theme.of(context).colorScheme.onSurface, // Dark Chocolate
        elevation: 0,
        iconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.onSurface), // иконки темные
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
          // Панель поиска и кнопка фильтров
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск по названию...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(
                    showFilters ? Icons.filter_list_off : Icons.filter_list,
                    color: filters.hasActiveFilters
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onPressed: () {
                    setState(() {
                      showFilters = !showFilters;
                    });
                  },
                  tooltip: 'Фильтры',
                ),
              ],
            ),
          ),

          // Панель фильтров (показывается при showFilters = true)
          if (showFilters) _buildFiltersPanel(),
          // Индикатор активных фильтров
          if (filters.hasActiveFilters && !showFilters)
            _buildActiveFiltersIndicator(),

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
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
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
                                            ? AppTheme.success.withOpacity(
                                                0.1) // Системный зеленый с прозрачностью
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: activeBottlesCount > 0
                                            ? Border.all(
                                                color: AppTheme.success
                                                    .withOpacity(0.3))
                                            : null,
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
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .onSurface // Системный цвет шрифта (Dark Chocolate)
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            "бут.",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: activeBottlesCount > 0
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .onSurface // Системный цвет шрифта (Dark Chocolate)
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
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Widget _buildFiltersPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок и кнопка сброса
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Фильтры',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (filters.hasActiveFilters)
                TextButton(
                  onPressed: () {
                    setState(() {
                      filters.clear();
                    });
                  },
                  child: const Text('Сбросить все'),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Фильтр по цвету
          _buildColorFilter(),
          const SizedBox(height: 12),

          // Фильтр по стране
          _buildCountryFilter(),
          const SizedBox(height: 12),

          // Переключатели
          Row(
            children: [
              Expanded(child: _buildStockFilter()),
              const SizedBox(width: 16),
              Expanded(child: _buildSparklingFilter()),
            ],
          ),
          const SizedBox(height: 12),

          // Сортировка
          _buildSortOptions(),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.filter_alt,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                ...filters.colors.map((color) => Chip(
                      label: Text(color),
                      backgroundColor: _getWineColorByName(color),
                      labelStyle:
                          const TextStyle(color: Colors.white, fontSize: 12),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          filters.colors.remove(color);
                        });
                      },
                    )),
                ...filters.countries.map((country) => Chip(
                      label: Text(country),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      labelStyle: const TextStyle(fontSize: 12),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          filters.countries.remove(country);
                        });
                      },
                    )),
                if (filters.onlyInStock == true)
                  Chip(
                    label: const Text('В наличии'),
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    labelStyle: const TextStyle(fontSize: 12),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        filters.onlyInStock = null;
                      });
                    },
                  ),
                if (filters.onlySparkling == true)
                  Chip(
                    label: const Text('Игристое'),
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    labelStyle: const TextStyle(fontSize: 12),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        filters.onlySparkling = null;
                      });
                    },
                  ),
                if (filters.onlySparkling == false)
                  Chip(
                    label: const Text('Тихое'),
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    labelStyle: const TextStyle(fontSize: 12),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        filters.onlySparkling = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
