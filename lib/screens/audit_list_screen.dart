import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winekeeper/models/audit_session.dart';
import 'package:winekeeper/models/wine_card.dart';
import 'package:winekeeper/models/wine_bottle.dart';
import 'package:winekeeper/screens/barcode_scanner_screen.dart';
import 'package:winekeeper/core/app_theme.dart';

class AuditListScreen extends StatefulWidget {
  const AuditListScreen({super.key});

  @override
  State<AuditListScreen> createState() => _AuditListScreenState();
}

class _AuditListScreenState extends State<AuditListScreen> {
  late Box<AuditSession> auditBox;
  late Box<WineCard> cardsBox;
  late Box<WineBottle> bottlesBox;

  @override
  void initState() {
    super.initState();
    auditBox = Hive.box<AuditSession>('audit_sessions');
    cardsBox = Hive.box<WineCard>('wine_cards');
    bottlesBox = Hive.box<WineBottle>('wine_bottles');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Ревизии',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: ValueListenableBuilder(
        valueListenable: auditBox.listenable(),
        builder: (context, Box<AuditSession> box, _) {
          final audits = box.values.toList()
            ..sort((a, b) => b.startTime.compareTo(a.startTime)); // Новые сначала

          if (audits.isEmpty) {
            return _buildEmptyState();
          }

          return _buildAuditsList(audits);
        },
      ),
      floatingActionButton: _buildStartAuditButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Пока нет ревизий',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Начните первую ревизию винотеки,\nчтобы сверить фактическое наличие\nс данными в системе',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 100), // Отступ для кнопки
          ],
        ),
      ),
    );
  }

  Widget _buildAuditsList(List<AuditSession> audits) {
    return ListView.builder(
      padding: const EdgeInsets.all(16).copyWith(bottom: 100), // Отступ для кнопки
      itemCount: audits.length,
      itemBuilder: (context, index) {
        final audit = audits[index];
        return _buildAuditCard(audit);
      },
    );
  }

  Widget _buildAuditCard(AuditSession audit) {
    final isActive = audit.isActive;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isActive 
          ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
          : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isActive 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isActive ? Icons.play_circle_filled : Icons.inventory_2,
            color: isActive 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).colorScheme.secondary,
            size: 28,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                _getAuditTitle(audit),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'АКТИВНАЯ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              audit.summary,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _buildProgressBar(audit),
          ],
        ),
        trailing: isActive 
          ? IconButton(
              onPressed: () => _continueAudit(audit),
              icon: Icon(
                Icons.play_arrow,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              tooltip: 'Продолжить сканирование',
            )
          : Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.outline,
            ),
        onTap: () => _openAuditDetails(audit),
      ),
    );
  }

  Widget _buildProgressBar(AuditSession audit) {
    final progress = audit.progressPercent / 100;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${audit.totalScanned} из ${audit.totalExpected} бутылок',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            Text(
              '${audit.progressPercent.toStringAsFixed(0)}%',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            audit.isActive 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).colorScheme.secondary,
          ),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildStartAuditButton() {
    final hasActiveAudit = auditBox.values.any((audit) => audit.isActive);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: FloatingActionButton.extended(
        onPressed: hasActiveAudit ? null : _startNewAudit,
        backgroundColor: hasActiveAudit 
          ? Colors.grey.shade400 
          : Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: hasActiveAudit ? 2 : 6,
        label: Text(
          hasActiveAudit ? 'У вас есть активная ревизия' : 'Начать новую ревизию',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        icon: Icon(
          hasActiveAudit ? Icons.pause_circle_outline : Icons.play_circle_filled,
          size: 24,
        ),
      ),
    );
  }

  String _getAuditTitle(AuditSession audit) {
    final date = audit.startTime;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    
    return 'Ревизия $day.$month.$year в $hour:$minute';
  }

  void _startNewAudit() async {
    // Проверяем, есть ли данные для ревизии
    if (cardsBox.isEmpty) {
      _showMessage('Невозможно начать ревизию:\nВ винотеке нет карточек вина');
      return;
    }

    final activeBottlesCount = bottlesBox.values.where((bottle) => bottle.isActive).length;
    if (activeBottlesCount == 0) {
      _showMessage('Невозможно начать ревизию:\nНет активных бутылок в винотеке');
      return;
    }

    // Создаем снапшот текущего состояния
    final expectedBottles = <String, int>{};
    final expectedBarcodes = <String, List<String>>{};

    for (final card in cardsBox.values) {
      final cardBottles = bottlesBox.values
          .where((bottle) => bottle.cardId == card.id && bottle.isActive)
          .toList();
      
      if (cardBottles.isNotEmpty) {
        expectedBottles[card.id] = cardBottles.length;
        expectedBarcodes[card.id] = cardBottles.map((b) => b.barcode).toList();
      }
    }

    // Создаем новую сессию ревизии
    final audit = AuditSession(
      id: AuditSession.generateId(),
      startTime: DateTime.now(),
      expectedBottles: expectedBottles,
      expectedBarcodes: expectedBarcodes,
    );

    await auditBox.put(audit.id, audit);

    // Открываем сканер в режиме ревизии
    _openAuditScanner(audit);
  }

  void _continueAudit(AuditSession audit) {
    _openAuditScanner(audit);
  }

  void _openAuditScanner(AuditSession audit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(
          mode: 'audit',
          auditSession: audit, // Передаем сессию в сканер
        ),
      ),
    );
  }

  void _openAuditDetails(AuditSession audit) {
    // TODO: Реализуем в следующем шаге
    _showMessage('Экран деталей ревизии\nбудет реализован в следующем шаге');
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.onSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}