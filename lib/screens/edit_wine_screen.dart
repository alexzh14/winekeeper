import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winekeeper/models/wine_card.dart';
import 'package:winekeeper/core/app_theme.dart';

class EditWineScreen extends StatefulWidget {
  final WineCard wineCard;

  const EditWineScreen({super.key, required this.wineCard});

  @override
  State<EditWineScreen> createState() => _EditWineScreenState();
}

class _EditWineScreenState extends State<EditWineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
  final _customVolumeController = TextEditingController();

  String? _selectedCountry;
  String? _selectedColor;
  bool _isSparkling = false;
  double? _selectedVolume;
  bool _useCustomVolume = false;
  bool _hasChanges = false;

  late Box<WineCard> cardsBox;

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
    'Новая Зеландия',
    'Канада',
    'Южная Африка',
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
    cardsBox = Hive.box<WineCard>('wine_cards');
    _loadExistingData();
  }

  void _loadExistingData() {
    // Заполняем поля данными существующей карточки
    _nameController.text = widget.wineCard.name;
    _yearController.text = widget.wineCard.year?.toString() ?? '';
    _selectedCountry = widget.wineCard.country;
    _selectedColor = widget.wineCard.color;
    _isSparkling = widget.wineCard.isSparkling;

    // Проверяем, является ли объем стандартным
    if (WineCard.standardVolumes.contains(widget.wineCard.volume)) {
      _selectedVolume = widget.wineCard.volume;
      _useCustomVolume = false;
    } else {
      _selectedVolume = 0.750; // по умолчанию
      _useCustomVolume = true;
      _customVolumeController.text = widget.wineCard.volume.toStringAsFixed(3);
    }
  }

  void _checkForChanges() {
    double finalVolume;
    if (_useCustomVolume) {
      finalVolume =
          double.tryParse(_customVolumeController.text.replaceAll(',', '.')) ??
              widget.wineCard.volume;
    } else {
      finalVolume = _selectedVolume!;
    }

    final hasChanges = _nameController.text.trim() != widget.wineCard.name ||
        (_yearController.text.isEmpty
                ? null
                : int.tryParse(_yearController.text)) !=
            widget.wineCard.year ||
        _selectedCountry != widget.wineCard.country ||
        _selectedColor != widget.wineCard.color ||
        _isSparkling != widget.wineCard.isSparkling ||
        finalVolume != widget.wineCard.volume;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _customVolumeController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Определяем финальный объем
    double finalVolume;
    if (_useCustomVolume) {
      finalVolume =
          double.parse(_customVolumeController.text.replaceAll(',', '.'));
    } else {
      finalVolume = _selectedVolume!;
    }

    // Создаем обновленную карточку
    final updatedCard = WineCard(
      id: widget.wineCard.id, // сохраняем тот же ID
      name: _nameController.text.trim(),
      volume: finalVolume,
      country: _selectedCountry,
      year: _yearController.text.isNotEmpty
          ? int.parse(_yearController.text)
          : null,
      color: _selectedColor,
      isSparkling: _isSparkling,
      createdAt: widget.wineCard.createdAt, // сохраняем дату создания
    );

    await cardsBox.put(updatedCard.id, updatedCard);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Карточка "${updatedCard.name}" обновлена'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, updatedCard); // возвращаем обновленную карточку
    }
  }

  Widget _buildVolumeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_drink_outlined,
                color: Colors.grey.shade700, size: 20),
            const SizedBox(width: 8),
            const Text(
              "Объем одной бутылки",
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
        const SizedBox(height: 16),

        // Стандартные объемы
        if (!_useCustomVolume) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WineCard.standardVolumes.map((volume) {
              final isSelected = _selectedVolume == volume;
              final displayName = WineCard.volumeNames[volume] ??
                  '${volume.toStringAsFixed(3)} л';

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVolume = volume;
                  });
                  _checkForChanges();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _useCustomVolume = true;
                _customVolumeController.text =
                    _selectedVolume?.toStringAsFixed(3) ??
                        widget.wineCard.volume.toStringAsFixed(3);
              });
            },
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Указать свой объем'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
            ),
          ),
        ],

        // Пользовательский ввод объема
        if (_useCustomVolume) ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _customVolumeController,
                  decoration: const InputDecoration(
                    hintText: "Например: 0,750",
                    suffixText: 'л',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Укажите объем';
                    }
                    final volume = double.tryParse(value.replaceAll(',', '.'));
                    if (volume == null || volume <= 0 || volume > 50) {
                      return 'Некорректный объем';
                    }
                    return null;
                  },
                  onChanged: (_) => _checkForChanges(),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _useCustomVolume = false;
                    _selectedVolume = 0.750;
                  });
                  _checkForChanges();
                },
                child: const Text('Отмена'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          "Редактировать «${widget.wineCard.name}»",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
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
            // Предупреждение об изменении объема
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_outlined,
                      color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Изменение объема повлияет на расчет общего объема для всех привязанных бутылок.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Название вина
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
                    onChanged: (_) => _checkForChanges(),
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
                      boxShadow: [AppTheme.softShadow],
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
                            _checkForChanges();
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
                      boxShadow: [AppTheme.softShadow],
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
                          onChanged: (_) => _checkForChanges(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Объем бутылки
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [AppTheme.softShadow],
              ),
              child: _buildVolumeSelector(),
            ),

            const SizedBox(height: 16),

            // Цвет вина
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
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Игристое вино
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
                      Icon(Icons.bubble_chart_outlined,
                          color: Colors.grey.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "Игристое вино",
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
                      _checkForChanges();
                    },
                    title: Text(
                      _isSparkling ? 'Да' : 'Нет',
                      style: const TextStyle(fontSize: 16),
                    ),
                    contentPadding: EdgeInsets.zero,
                    activeColor: Colors.amber.shade600,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Кнопки сохранения/отмены
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Отмена",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _hasChanges ? _saveChanges : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasChanges
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Сохранить",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
