import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winekeeper/models/wine_card.dart';
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
  final _customVolumeController = TextEditingController();
  final _customCountryController = TextEditingController();

  String? _selectedCountry;
  String? _selectedColor;
  bool _isSparkling = false;
  double? _selectedVolume;
  bool _useCustomVolume = false;
  bool _useCustomCountry = false;

  late Box<WineCard> cardsBox;

  final List<String> _countries = [
    'Франция',
    'Италия',
    'Испания',
    'Германия',
    'Португалия',
    'Австрия',
    'Грузия',
    'США',
    'Чили',
    'Аргентина',
    'Австралия',
    'ЮАР',
    'Новая Зеландия',
    'Другое',
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
    _selectedVolume = 0.750; // По умолчанию стандартная бутылка
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _customVolumeController.dispose();
    _customCountryController.dispose();
    super.dispose();
  }

  void _saveCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Определяем финальный объем
    double finalVolume;
    if (_useCustomVolume) {
      finalVolume = double.parse(_customVolumeController.text.replaceAll(',', '.'));
    } else {
      finalVolume = _selectedVolume!;
    }

    final card = WineCard(
      id: WineCard.generateId(),
      name: _nameController.text.trim(),
      volume: finalVolume,
      country: _useCustomCountry
          ? _customCountryController.text.trim()
          : _selectedCountry,
      year: _yearController.text.isNotEmpty
          ? int.tryParse(_yearController.text)
          : null,
      color: _selectedColor,
      isSparkling: _isSparkling,
    );

    try {
      await cardsBox.put(card.id, card);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Карточка "${card.name}" создана'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при создании карточки'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Новое вино'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Название вина
                _buildSection(
                  title: 'Название',
                  required: true,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: "Например: Château Margaux",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Пожалуйста, введите название вина';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Страна - полная ширина для мобильного
                _buildSection(
                  title: 'Страна',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_useCustomCountry) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedCountry,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          hint: const Text('Выберите страну'),
                          items: _countries.map((country) {
                            return DropdownMenuItem<String>(
                              value: country,
                              child: Text(country),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == 'Другое') {
                              setState(() {
                                _selectedCountry = null;
                                _useCustomCountry = true;
                              });
                            } else {
                              setState(() {
                                _selectedCountry = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _useCustomCountry = true;
                              _selectedCountry = null;
                            });
                          },
                          child: const Text('Ввести вручную'),
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _customCountryController,
                          decoration: const InputDecoration(
                            hintText: "Введите страну",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Укажите страну';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _useCustomCountry = false;
                              _selectedCountry = null;
                              _customCountryController.clear();
                            });
                          },
                          child: const Text('Выбрать из списка'),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Год
                _buildSection(
                  title: 'Год урожая',
                  child: TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(
                      hintText: "Например: 2018",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final year = int.tryParse(value);
                        if (year == null || year < 1800 || year > DateTime.now().year + 5) {
                          return 'Введите корректный год (1800-${DateTime.now().year + 5})';
                        }
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Цвет вина
                _buildSection(
                  title: 'Цвет вина',
                  child: Wrap(
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? entry.value.withOpacity(0.1)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? entry.value : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
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
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? entry.value : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // Объем
                _buildSection(
                  title: 'Объем бутылки',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_useCustomVolume) ...[
                        DropdownButtonFormField<double>(
                          value: _selectedVolume,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          items: WineCard.standardVolumes.map((volume) {
                            return DropdownMenuItem<double>(
                              value: volume,
                              child: Text('${volume.toStringAsFixed(3)} л'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedVolume = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Выберите объем бутылки';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _useCustomVolume = true;
                            });
                          },
                          child: const Text('Ввести свой объем'),
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _customVolumeController,
                          decoration: const InputDecoration(
                            hintText: "Например: 0.375",
                            suffixText: "л",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Введите объем';
                            }
                            final volume = double.tryParse(value.replaceAll(',', '.'));
                            if (volume == null || volume <= 0 || volume > 30) {
                              return 'Введите корректный объем (0-30 л)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _useCustomVolume = false;
                              _selectedVolume = 0.750;
                              _customVolumeController.clear();
                            });
                          },
                          child: const Text('Выбрать стандартный'),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Игристое вино
                _buildSection(
                  title: 'Тип вина',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bubble_chart_outlined, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Игристое вино',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Switch(
                          value: _isSparkling,
                          onChanged: (value) {
                            setState(() {
                              _isSparkling = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Кнопка создания карточки
                ElevatedButton(
                  onPressed: _saveCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Создать карточку вина",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Подсказка
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'После создания карточки вы сможете привязать к ней конкретные бутылки, отсканировав их штрихкоды.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    bool required = false,
  }) {
    return Container(
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
              Icon(
                _getIconForSection(title),
                color: Colors.grey.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (required) const Text(
                " *",
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  IconData _getIconForSection(String title) {
    switch (title) {
      case 'Название':
        return Icons.wine_bar_outlined;
      case 'Страна':
        return Icons.public_outlined;
      case 'Год урожая':
        return Icons.calendar_today_outlined;
      case 'Цвет вина':
        return Icons.palette_outlined;
      case 'Объем бутылки':
        return Icons.straighten_outlined;
      case 'Тип вина':
        return Icons.bubble_chart_outlined;
      default:
        return Icons.info_outlined;
    }
  }
}