import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winekeeper/models/wine_bottle.dart';
import 'package:winekeeper/core/app_theme.dart';

class WineDetailScreen extends StatefulWidget {
  final int wineIndex;

  const WineDetailScreen({super.key, required this.wineIndex});

  @override
  State<WineDetailScreen> createState() => _WineDetailScreenState();
}

class _WineDetailScreenState extends State<WineDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
  final _quantityController = TextEditingController();

  String? _selectedCountry;
  String? _selectedColor;
  bool _isSparkling = false;
  bool _isEditMode = false;
  bool _hasChanges = false;

  late Box<WineBottle> wineBox;
  late WineBottle originalWine;

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
    _loadWineData();
  }

  void _loadWineData() {
    final wine = wineBox.getAt(widget.wineIndex);
    if (wine == null) {
      Navigator.pop(context);
      return;
    }

    originalWine = wine;
    _nameController.text = wine.name;
    _yearController.text = wine.year?.toString() ?? '';
    _quantityController.text = wine.quantity.toString();
    _selectedCountry = wine.country;
    _selectedColor = wine.color;
    _isSparkling = wine.isSparkling;
  }

  void _checkForChanges() {
    final currentData = _getCurrentData();
    final hasChanges = !_dataEquals(originalWine, currentData);

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  WineBottle _getCurrentData() {
    return WineBottle(
      name: _nameController.text.trim(),
      country: _selectedCountry,
      year: _yearController.text.isNotEmpty
          ? int.tryParse(_yearController.text)
          : null,
      color: _selectedColor,
      isSparkling: _isSparkling,
      quantity: int.tryParse(_quantityController.text) ?? 1,
    );
  }

  bool _dataEquals(WineBottle wine1, WineBottle wine2) {
    return wine1.name == wine2.name &&
        wine1.country == wine2.country &&
        wine1.year == wine2.year &&
        wine1.color == wine2.color &&
        wine1.isSparkling == wine2.isSparkling &&
        wine1.quantity == wine2.quantity;
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updatedWine = _getCurrentData();
    await wineBox.putAt(widget.wineIndex, updatedWine);

    setState(() {
      originalWine = updatedWine;
      _hasChanges = false;
      _isEditMode = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Изменения сохранены'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deleteWine() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить вино?'),
        content: Text(
            'Вы уверены, что хотите удалить "${originalWine.name}" из перечня?'),
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
      await wineBox.deleteAt(widget.wineIndex);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Вино "${originalWine.name}" удалено'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Color _getWineColor(String? color) {
    return _wineColors[color] ?? Colors.grey.shade600;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          "Карточка вина",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _loadWineData(); // Восстанавливаем оригинальные данные
                  _isEditMode = false;
                  _hasChanges = false;
                });
              },
            ),
        ],
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isEditMode
                      ? TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Пожалуйста, введите название вина';
                            }
                            return null;
                          },
                          onChanged: (_) => _checkForChanges(),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            _nameController.text,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                        _isEditMode
                            ? DropdownButtonFormField<String>(
                                value: _selectedCountry,
                                decoration: const InputDecoration(
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
                                  _checkForChanges();
                                },
                              )
                            : Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  _selectedCountry ?? 'Не указано',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _selectedCountry != null
                                        ? Colors.black87
                                        : Colors.grey.shade600,
                                  ),
                                ),
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
                        _isEditMode
                            ? TextFormField(
                                controller: _yearController,
                                decoration: const InputDecoration(
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
                                onChanged: (_) => _checkForChanges(),
                              )
                            : Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  _yearController.text.isNotEmpty
                                      ? _yearController.text
                                      : 'Не указан',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _yearController.text.isNotEmpty
                                        ? Colors.black87
                                        : Colors.grey.shade600,
                                  ),
                                ),
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
                  _isEditMode
                      ? Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _wineColors.entries.map((entry) {
                            final isSelected = _selectedColor == entry.key;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedColor = entry.key;
                                });
                                _checkForChanges();
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
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedColor != null
                                ? _getWineColor(_selectedColor).withOpacity(0.1)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedColor != null
                                  ? _getWineColor(_selectedColor)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _selectedColor != null
                                      ? _getWineColor(_selectedColor)
                                      : Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedColor ?? 'Не указан',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _selectedColor != null
                                      ? _getWineColor(_selectedColor)
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
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
                        _isEditMode
                            ? SwitchListTile(
                                value: _isSparkling,
                                onChanged: (value) {
                                  setState(() {
                                    _isSparkling = value;
                                  });
                                  _checkForChanges();
                                },
                                title: Text(
                                  _isSparkling ? 'Да' : 'Нет',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                contentPadding: EdgeInsets.zero,
                                activeColor: Colors.amber.shade600,
                              )
                            : Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  _isSparkling ? 'Да' : 'Нет',
                                  style: const TextStyle(fontSize: 16),
                                ),
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
                          ],
                        ),
                        const SizedBox(height: 12),
                        _isEditMode
                            ? TextFormField(
                                controller: _quantityController,
                                decoration: const InputDecoration(
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
                                onChanged: (_) => _checkForChanges(),
                              )
                            : Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  '${_quantityController.text} бут.',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Кнопки действий
            if (_isEditMode) ...[
              // Кнопка сохранения/закрытия в режиме редактирования
              ElevatedButton(
                onPressed: _hasChanges
                    ? _saveChanges
                    : () {
                        setState(() {
                          _isEditMode = false;
                          _hasChanges = false;
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasChanges
                      ? const Color(0xFF4A90E2)
                      : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _hasChanges ? "Сохранить изменения" : "Закрыть",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Кнопка удаления в режиме редактирования
              OutlinedButton(
                onPressed: _deleteWine,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Удалить вино",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else ...[
              // Кнопки в режиме просмотра
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _toggleEditMode,
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
                        "Редактировать",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _deleteWine,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Удалить",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
