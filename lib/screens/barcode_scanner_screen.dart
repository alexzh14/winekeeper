import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winekeeper/core/app_theme.dart';
import 'package:winekeeper/models/wine_card.dart';
import 'package:winekeeper/models/wine_bottle.dart';
import 'package:winekeeper/models/sale_record.dart';
import 'package:winekeeper/models/audit_session.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final String? mode; // 'add', 'sell', или 'audit'
  final WineCard? wineCard; // для режима добавления к конкретной карточке
  final AuditSession? auditSession; // для режима ревизии

  const BarcodeScannerScreen({
    super.key,
    this.mode,
    this.wineCard,
    this.auditSession,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _screenOpened = false;

  @override
  void initState() {
    super.initState();
    _screenOpened = false;
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  String get _screenTitle {
    switch (widget.mode) {
      case 'sell':
        return 'Продать бутылку';
      case 'add':
        return 'Добавить бутылку';
      case 'audit':
        return 'Ревизия винотеки';
      default:
        return 'Сканировать штрихкод';
    }
  }

  String get _instructionText {
    switch (widget.mode) {
      case 'sell':
        return 'Наведите камеру на штрихкод\nбутылки для продажи';
      case 'add':
        return 'Наведите камеру на штрихкод\nновой бутылки';
      case 'audit':
        return 'Сканируйте все бутылки\nв винотеке для ревизии';
      default:
        return 'Наведите камеру на штрихкод';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(
          children: [
            Text(_screenTitle),
            if (widget.mode == 'audit' && widget.auditSession != null) ...[
              const SizedBox(height: 4),
              Text(
                'Прогресс: ${widget.auditSession!.totalScanned} из ${widget.auditSession!.totalExpected}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey.shade600, // Заменили на конкретный цвет
                ),
              ),
            ],
          ],
        ),
        backgroundColor: const Color(0xFFFAF5EF),
        foregroundColor: const Color(0xFF362C2A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => cameraController.switchCamera(),
          ),
          if (widget.mode == 'audit')
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: _completeAudit,
              tooltip: 'Завершить ревизию',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Сканер
          MobileScanner(
            controller: cameraController,
            onDetect: _foundBarcode,
          ),
          
          // Оверлей с инструкциями
          _buildScannerOverlay(),
          
          // Кнопка эмуляции (для тестирования)
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: _buildEmulateButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderColor: const Color(0xFFFF857A),
          borderRadius: 20,
          borderLength: 30,
          borderWidth: 5,
          cutOutSize: 250,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Верхний текст
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _instructionText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // Нижний текст с подсказкой
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Убедитесь, что штрихкод\nполностью виден в рамке',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  if (widget.mode == 'audit' && widget.auditSession != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${widget.auditSession!.progressPercent.toStringAsFixed(1)}% завершено',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmulateButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: ElevatedButton.icon(
        onPressed: _emulateBarcodeScan,
        icon: const Icon(Icons.bug_report, color: Colors.white),
        label: const Text(
          '🐛 Эмулировать сканирование',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF857A),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _foundBarcode(BarcodeCapture barcodeCapture) {
    if (_screenOpened) return;

    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    _processBarcode(code);
  }

  void _emulateBarcodeScan() {
    if (_screenOpened) return;

    String testBarcode;
    
    if (widget.mode == 'audit' || widget.mode == 'sell') {
      // Для ревизии и продажи нужен штрихкод СУЩЕСТВУЮЩЕЙ бутылки
      final bottlesBox = Hive.box<WineBottle>('wine_bottles');
      final existingBottles = bottlesBox.values
          .where((bottle) => bottle.isActive)
          .toList();
      
      if (existingBottles.isEmpty) {
        _showMessage(widget.mode == 'audit' 
          ? 'Нет активных бутылок для ревизии' 
          : 'Нет активных бутылок для продажи');
        return;
      }
      
      // Берем штрихкод первой активной бутылки
      testBarcode = existingBottles.first.barcode;
    } else {
      // Для добавления генерируем новый штрихкод
      testBarcode = WineBottle.generateTestBarcode();
    }

    _processBarcode(testBarcode);
  }

  void _processBarcode(String barcode) {
    if (_screenOpened) return;
    _screenOpened = true;

    switch (widget.mode) {
      case 'sell':
        _handleSellMode(barcode);
        break;
      case 'add':
        _handleAddMode(barcode);
        break;
      case 'audit':
        _handleAuditMode(barcode);
        break;
      default:
        _handleDefaultMode(barcode);
    }
  }

  void _handleAuditMode(String barcode) {
    final auditBox = Hive.box<AuditSession>('audit_sessions');
    final audit = widget.auditSession;

    if (audit == null) {
      _showMessage('Ошибка: сессия ревизии не найдена');
      return;
    }

    // ✅ ПРОВЕРКА НА ДУБЛЬ
    if (audit.isBottleScanned(barcode)) {
      _showMessage('🔄 Эта бутылка уже отсканирована\nПропускаем...');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _resetScreen();
        }
      });
      return;
    }

    // Добавляем штрихкод в список отсканированных
    audit.addScannedBarcode(barcode);

    // Ищем бутылку в базе
    final bottlesBox = Hive.box<WineBottle>('wine_bottles');
    final bottle = bottlesBox.values
        .where((b) => b.barcode == barcode && b.isActive)
        .firstOrNull;

    if (bottle != null) {
      // Известная бутылка - добавляем к найденным
      audit.addFoundBottle(bottle.cardId, barcode);
      
      // Получаем название карточки для отображения
      final cardsBox = Hive.box<WineCard>('wine_cards');
      final card = cardsBox.get(bottle.cardId);
      final cardName = card?.name ?? 'Неизвестная карточка';
      
      _showMessage('✅ Найдена бутылка\n$cardName\n\nПрогресс: ${audit.totalScanned} из ${audit.totalExpected}');
    } else {
      // Неизвестная бутылка
      _showMessage('❓ Неизвестная бутылка\nШтрихкод: $barcode\n\nВозможно, не из вашей винотеки');
    }

    // Сохраняем обновленную сессию
    auditBox.put(audit.id, audit);

    // Возвращаемся к сканированию через 3 секунды
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _resetScreen();
      }
    });
  }

  void _handleSellMode(String barcode) {
    final bottlesBox = Hive.box<WineBottle>('wine_bottles');
    final cardsBox = Hive.box<WineCard>('wine_cards');
    
    // Ищем активную бутылку с таким штрихкодом
    WineBottle? bottle;
    try {
      bottle = bottlesBox.values
          .firstWhere((b) => b.barcode == barcode && b.isActive);
    } catch (e) {
      _showMessage('Бутылка с таким штрихкодом не найдена\nили уже продана');
      return;
    }

    // Находим карточку вина
    WineCard? wineCard;
    try {
      wineCard = cardsBox.get(bottle.cardId);
    } catch (e) {
      _showMessage('Ошибка: карточка вина не найдена');
      return;
    }

    if (wineCard == null) {
      _showMessage('Ошибка: карточка вина не найдена');
      return;
    }

    _showSellConfirmation(bottle, wineCard);
  }

  void _handleAddMode(String barcode) {
    final bottlesBox = Hive.box<WineBottle>('wine_bottles');
    
    // Проверяем, не существует ли уже такой штрихкод
    final existingBottle = bottlesBox.values
        .where((bottle) => bottle.barcode == barcode)
        .firstOrNull;

    if (existingBottle != null) {
      _showMessage('Бутылка с таким штрихкодом\nуже существует в системе');
      return;
    }

    if (widget.wineCard != null) {
      // Добавляем к конкретной карточке
      _addBottleToCard(barcode, widget.wineCard!);
    } else {
      // Показываем диалог выбора карточки
      _showCardSelectionDialog(barcode);
    }
  }

  void _handleDefaultMode(String barcode) {
    _showBarcodeInfo(barcode);
  }

  void _completeAudit() async {
    final audit = widget.auditSession;
    if (audit == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAF5EF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Завершить ревизию?',
          style: TextStyle(color: Color(0xFF362C2A)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Отсканировано: ${audit.totalScanned} из ${audit.totalExpected} бутылок',
              style: const TextStyle(color: Color(0xFF362C2A)),
            ),
            Text(
              'Прогресс: ${audit.progressPercent.toStringAsFixed(1)}%',
              style: const TextStyle(color: Color(0xFF362C2A)),
            ),
            if (audit.unknownBottlesCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ Найдено ${audit.unknownBottlesCount} неизвестных бутылок',
                style: const TextStyle(color: Colors.orange),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Продолжить'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF857A), // Используем прямой цвет
            ),
            child: const Text('Завершить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      // Завершаем ревизию
      audit.complete();
      final auditBox = Hive.box<AuditSession>('audit_sessions');
      await auditBox.put(audit.id, audit);

      if (mounted) {
        // Возвращаемся к списку ревизий
        Navigator.pop(context);
        _showMessage('✅ Ревизия завершена!\nРезультаты сохранены');
      }
    }
  }

  void _showSellConfirmation(WineBottle bottle, WineCard wineCard) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAF5EF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Подтверждение продажи',
          style: TextStyle(color: Color(0xFF362C2A)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wine_bar,
              size: 64,
              color: Color(0xFFFF857A),
            ),
            const SizedBox(height: 16),
            Text(
              wineCard.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF362C2A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              wineCard.subtitle,
              style: const TextStyle(color: Color(0xFF362C2A)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF857A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Штрихкод: ${bottle.barcode}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF362C2A),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScreen();
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmSale(bottle, wineCard);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF857A),
            ),
            child: const Text(
              'Продать',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCardSelectionDialog(String barcode) {
    final cardsBox = Hive.box<WineCard>('wine_cards');
    final cards = cardsBox.values.toList();

    if (cards.isEmpty) {
      _showMessage('Сначала создайте карточку вина');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAF5EF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Выберите карточку вина',
          style: TextStyle(color: Color(0xFF362C2A)),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFF857A).withOpacity(0.1),
                  child: const Icon(
                    Icons.wine_bar,
                    color: Color(0xFFFF857A),
                    size: 20,
                  ),
                ),
                title: Text(card.name),
                subtitle: Text(card.subtitle),
                onTap: () {
                  Navigator.pop(context);
                  _addBottleToCard(barcode, card);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScreen();
            },
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _showBarcodeInfo(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAF5EF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Отсканированный код',
          style: TextStyle(color: Color(0xFF362C2A)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.qr_code_2,
              size: 64,
              color: Color(0xFFFF857A),
            ),
            const SizedBox(height: 16),
            Text(
              barcode,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScreen();
            },
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _confirmSale(WineBottle bottle, WineCard wineCard) {
    final bottlesBox = Hive.box<WineBottle>('wine_bottles');
    
    // Деактивируем бутылку
    bottle.isActive = false;
    bottlesBox.put(bottle.id, bottle);

    // Создаем запись о продаже
    final saleRecord = SaleRecord(
      id: SaleRecord.generateId(),
      bottleId: bottle.id,
      cardId: wineCard.id,
      sellerId: 'current_user',
      reason: SaleRecord.REASON_SALE,
      method: SaleRecord.METHOD_SCAN,
    );

    final salesBox = Hive.box<SaleRecord>('sale_records');
    salesBox.put(saleRecord.id, saleRecord);

    _showMessage('Бутылка успешно продана!\n${wineCard.name}');
    
    // Возвращаемся назад
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _addBottleToCard(String barcode, WineCard wineCard) {
    final bottle = WineBottle(
      id: WineBottle.generateId(),
      barcode: barcode,
      cardId: wineCard.id,
    );

    final bottlesBox = Hive.box<WineBottle>('wine_bottles');
    bottlesBox.put(bottle.id, bottle);

    _showMessage('Бутылка успешно добавлена!\n${wineCard.name}');
    
    // Возвращаемся назад
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: const Color(0xFF362C2A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _resetScreen() {
    setState(() {
      _screenOpened = false;
    });
  }
}

// Кастомная форма для оверлея сканера
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path();
    final double cutOutOffset = (rect.width - cutOutSize) / 2;
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cutOutOffset,
          rect.height / 2 - cutOutSize / 2,
          cutOutSize,
          cutOutSize,
        ),
        Radius.circular(borderRadius),
      ),
    );
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final Paint paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        getOuterPath(rect),
      ),
      paint,
    );

    // Рисуем рамку
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final double cutOutOffset = (rect.width - cutOutSize) / 2;
    final Rect cutOutRect = Rect.fromLTWH(
      cutOutOffset,
      rect.height / 2 - cutOutSize / 2,
      cutOutSize,
      cutOutSize,
    );

    // Рисуем углы рамки
    final double cornerSize = borderLength;
    
    // Верхний левый угол
    canvas.drawLine(
      Offset(cutOutRect.left, cutOutRect.top + cornerSize),
      Offset(cutOutRect.left, cutOutRect.top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(cutOutRect.left, cutOutRect.top),
      Offset(cutOutRect.left + cornerSize, cutOutRect.top),
      borderPaint,
    );

    // Верхний правый угол
    canvas.drawLine(
      Offset(cutOutRect.right - cornerSize, cutOutRect.top),
      Offset(cutOutRect.right, cutOutRect.top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(cutOutRect.right, cutOutRect.top),
      Offset(cutOutRect.right, cutOutRect.top + cornerSize),
      borderPaint,
    );

    // Нижний левый угол
    canvas.drawLine(
      Offset(cutOutRect.left, cutOutRect.bottom - cornerSize),
      Offset(cutOutRect.left, cutOutRect.bottom),
      borderPaint,
    );
    canvas.drawLine(
      Offset(cutOutRect.left, cutOutRect.bottom),
      Offset(cutOutRect.left + cornerSize, cutOutRect.bottom),
      borderPaint,
    );

    // Нижний правый угол
    canvas.drawLine(
      Offset(cutOutRect.right - cornerSize, cutOutRect.bottom),
      Offset(cutOutRect.right, cutOutRect.bottom),
      borderPaint,
    );
    canvas.drawLine(
      Offset(cutOutRect.right, cutOutRect.bottom - cornerSize),
      Offset(cutOutRect.right, cutOutRect.bottom),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => QrScannerOverlayShape(
    borderColor: borderColor,
    borderWidth: borderWidth * t,
    overlayColor: overlayColor,
    borderRadius: borderRadius * t,
    borderLength: borderLength * t,
    cutOutSize: cutOutSize * t,
  );
}