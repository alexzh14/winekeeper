import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winekeeper/models/wine_bottle.dart';
import 'package:winekeeper/core/app_theme.dart';

class AddWineScreen extends StatefulWidget {
  const AddWineScreen({super.key});

  @override
  State<AddWineScreen> createState() => _AddWineScreenState();
}

class _AddWineScreenState extends State<AddWineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
  final _quantityController = TextEditingController();

  String? _selectedCountry;
  String? _selectedColor;
  bool _isSparkling = false;

  late Box<WineBottle> wineBox;

  final List<String> _countries = [
    'Франция',
    'Италия',
    'Испания',
    'Германия',
    'Португалия',
    'Австрия',
    'Грузия',
    'Молдова',
    'Россия',
    'США',
    'Чили',
    'Аргентина',
    'Австралия',
    'ЮАР',
  ];

  final Map<String, Color> _wineColors = {
    'Красное': AppTheme.wineRed,
    'Белое': AppTheme.wineWhite,
    'Розовое': AppTheme.wineRose,
    'Оранжевое': AppTheme.wineOrange,
  };

  @override
  void initState() {
    super.initState();
    wineBox = Hive.box<WineBottle>('wine_bottles');
    _quantityController.text = '1'; // По умолчанию 1 бутылка
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _saveWine() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final wine = WineBottle(
      name: _nameController.text.trim(),
      country: _selectedCountry,
      year: _yearController.text.isNotEmpty
          ? int.parse(_yearController.text)
          : null,
      color: _selectedColor,
      isSparkling: _isSparkling,
      quantity: int.parse(_quantityController.text),
    );

    await wineBox.add(wine);

    if (mounted) {
      // Показываем уведомление об успехе
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Вино "${wine.name}" добавлено в перечень'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Возвращаемся на главный экран
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          "Добавить вино",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Название вина
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wine_bar_outlined,
                          color: Colors.grey.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "Название вина",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Text(
                        " *",
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: "Например: Château Margaux",
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Пожалуйста, введите название вина';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Страна и год
            Row(
              children: [
                // Страна
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.public_outlined,
                                color: Colors.grey.shade700, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              "Страна",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedCountry,
                          decoration: const InputDecoration(
                            hintText: "Выберите",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          items: _countries.map((country) {
                            return DropdownMenuItem(
                              value: country,
                              child: Text(country),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCountry = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Год
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                color: Colors.grey.shade700, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              "Год",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _yearController,
                          decoration: const InputDecoration(
                            hintText: "2020",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final year = int.tryParse(value);
                              if (year == null ||
                                  year < 1800 ||
                                  year > DateTime.now().year + 2) {
                                return 'Некорректный год';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Цвет вина
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_outlined,
                          color: Colors.grey.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "Цвет вина",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _wineColors.entries.map((entry) {
                      final isSelected = _selectedColor == entry.key;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = entry.key;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? entry.value.withOpacity(0.1)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? entry.value
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: entry.value,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? entry.value
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Игристое и количество
            Row(
              children: [
                // Игристое
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bubble_chart_outlined,
                                color: Colors.grey.shade700, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              "Игристое",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          value: _isSparkling,
                          onChanged: (value) {
                            setState(() {
                              _isSparkling = value;
                            });
                          },
                          title: Text(
                            _isSparkling ? 'Да' : 'Нет',
                            style: const TextStyle(fontSize: 14),
                          ),
                          contentPadding: EdgeInsets.zero,
                          activeColor: Colors.amber.shade600,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Количество
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.inventory_outlined,
                                color: Colors.grey.shade700, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              "Количество",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const Text(
                              " *",
                              style: TextStyle(color: Colors.red, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            hintText: "1",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            suffixText: 'бут.',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Обязательно';
                            }
                            final quantity = int.tryParse(value);
                            if (quantity == null || quantity <= 0) {
                              return 'Больше 0';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Кнопка сохранения
            ElevatedButton(
              onPressed: _saveWine,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Добавить в перечень",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
