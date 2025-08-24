import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winekeeper/models/wine_card.dart';
import 'package:winekeeper/models/wine_bottle.dart';
import 'dart:math';

class BarcodeScannerScreen extends StatefulWidget {
  final WineCard wineCard;
  final String mode; // 'add' для добавления бутылок, 'sell' для продажи

  const BarcodeScannerScreen({
    super.key,
    required this.wineCard,
    this.mode = 'add',
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;
  String? lastScannedBarcode;
  late Box<WineBottle> bottlesBox;

  @override
  void initState() {
    super.initState();
    bottlesBox = Hive.box<WineBottle>('wine_bottles');
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!isScanning) return;

    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null || barcode == lastScannedBarcode) return;

    setState(() {
      isScanning = false;
      lastScannedBarcode = barcode;
    });

    _processBarcode(barcode);
  }

  Future<void> _processBarcode(String barcode) async {
    if (widget.mode == 'add') {
      await _addBottleWithBarcode(barcode);
    } else {
      await _sellBottleWithBarcode(barcode);
    }
  }

  Future<void> _addBottleWithBarcode(String barcode) async {
    // Проверяем, не существует ли уже бутылка с таким штрихкодом
    final existingBottle = bottlesBox.values.firstWhere(
      (bottle) => bottle.barcode == barcode,
      orElse: () => WineBottle(id: '', barcode: '', cardId: ''),
    );

    if (existingBottle.id.isNotEmpty) {
      _showMessage(
        'Ошибка: Бутылка с таким штрихкодом уже существует',
        Colors.red,
      );
      _resumeScanning();
      return;
    }

    // Создаем новую бутылку
    final bottle = WineBottle(
      id: WineBottle.generateId(),
      barcode: barcode,
      cardId: widget.wineCard.id,
    );

    await bottlesBox.put(bottle.id, bottle);

    _showMessage(
      'Бутылка добавлена! Штрихкод: $barcode',
      Colors.green,
    );

    _resumeScanning();
  }

  Future<void> _sellBottleWithBarcode(String barcode) async {
    // Ищем активную бутылку с таким штрихкодом в этой карточке
    final bottle = bottlesBox.values.firstWhere(
      (b) => b.barcode == barcode && b.cardId == widget.wineCard.id && b.isActive,
      orElse: () => WineBottle(id: '', barcode: '', cardId: ''),
    );

    if (bottle.id.isEmpty) {
      _showMessage(
        'Бутылка не найдена или уже продана',
        Colors.red,
      );
      _resumeScanning();
      return;
    }

    // Помечаем как проданную
    bottle.isActive = false;
    await bottlesBox.put(bottle.id, bottle);

    // TODO: Добавить запись в SaleRecord

    _showMessage(
      'Бутылка продана! Штрихкод: $barcode',
      Colors.green,
    );

    _resumeScanning();
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resumeScanning() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isScanning = true;
          lastScannedBarcode = null;
        });
      }
    });
  }

  // Эмуляция сканирования для тестирования без камеры
  void _simulateBarcodeScan() {
    final random = Random();
    final testBarcode = 'TEST-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}${random.nextInt(999).toString().padLeft(3, '0')}';
    
    setState(() {
      isScanning = false;
      lastScannedBarcode = testBarcode;
    });

    _processBarcode(testBarcode);
  }

  @override
  Widget build(BuildContext context) {
    final isAddMode = widget.mode == 'add';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          isAddMode ? 'Добавить бутылки' : 'Продать бутылку',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Кнопка эмуляции для тестирования
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.orange),
            tooltip: 'Эмулировать сканирование',
            onPressed: isScanning ? _simulateBarcodeScan : null,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Камера сканера
          MobileScanner(
            controller: cameraController,
            onDetect: _onBarcodeDetected,
          ),

          // Overlay с рамкой для сканирования
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isScanning ? Colors.green : Colors.orange,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Информационная панель
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.wineCard.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAddMode
                        ? 'Отсканируйте штрихкоды бутылок'
                        : 'Отсканируйте штрихкод для продажи',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder(
                    valueListenable: bottlesBox.listenable(),
                    builder: (context, box, _) {
                      final activeCount = box.values
                          .where((bottle) => bottle.cardId == widget.wineCard.id && bottle.isActive)
                          .length;
                      final totalVolume = activeCount * widget.wineCard.volume;

                      return Text(
                        'В наличии: $activeCount бут. (${totalVolume.toStringAsFixed(3)} л)',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Статус сканирования
          if (!isScanning)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Обработка штрихкода...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Кнопка эмуляции снизу
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: isScanning ? _simulateBarcodeScan : null,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Эмулировать сканирование'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Для тестирования без камеры',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}