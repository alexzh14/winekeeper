import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winekeeper/models/audit_session.dart';
import 'package:winekeeper/models/wine_card.dart';
import 'package:winekeeper/models/wine_bottle.dart';
import 'package:winekeeper/screens/barcode_scanner_screen.dart';

class AuditDetailScreen extends StatefulWidget {
  final AuditSession audit;

  const AuditDetailScreen({
    super.key,
    required this.audit,
  });

  @override
  State<AuditDetailScreen> createState() => _AuditDetailScreenState();
}

class _AuditDetailScreenState extends State<AuditDetailScreen> {
  late Box<WineCard> cardsBox;
  late Box<WineBottle> bottlesBox;
  late Box<AuditSession> auditBox;
  
  String _filterMode = 'all'; // 'all', 'discrepancies', 'missing', 'excess'

  @override
  void initState() {
    super.initState();
    cardsBox = Hive.box<WineCard>('wine_cards');
    bottlesBox = Hive.box<WineBottle>('wine_bottles');
    auditBox = Hive.box<AuditSession>('audit_sessions');
    
    // Автоматическая синхронизация при открытии экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performAutoSync();
    });
  }

  /// Автоматическая синхронизация при открытии экрана
  Future<void> _performAutoSync() async {
    if (!widget.audit.isActive) return;
    
    final changes = widget.audit.syncWithCurrentState(bottlesBox, cardsBox);
    
    if (changes['hasChanges'] == true) {
      // Сохраняем обновленную сессию
      await auditBox.put(widget.audit.id, widget.audit);
      
      // Обновляем UI
      if (mounted) {
        setState(() {});
        
        // Показываем уведомление об изменениях
        _showSyncNotification(changes);
      }
    }
  }

  /// Показать уведомление об изменениях после синхронизации
  void _showSyncNotification(Map<String, dynamic> changes) {
    final theme = Theme.of(context);
    final soldCount = (changes['soldBottles'] as Map).length;
    final removedExpected = changes['removedFromExpected'] as int;
    final removedScanned = changes['removedFromScanned'] as int;
    
    String message = '🔄 Обнаружены изменения в винотеке!\n';
    message += 'Продано бутылок: $soldCount\n';
    
    if (removedScanned > 0) {
      message += 'Удалено из отсканированных: $removedScanned';
    } else {
      message += 'Обновлены ожидания: -$removedExpected';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: theme.colorScheme.primary,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Подробнее',
          textColor: Colors.white,
          onPressed: () => _showDetailedChanges(changes),
        ),
      ),
    );
  }

  /// Показать подробную информацию об изменениях
  void _showDetailedChanges(Map<String, dynamic> changes) {
    final theme = Theme.of(context);
    final soldBottles = changes['soldBottles'] as Map<String, String>;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.sync_alt, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Изменения в винотеке',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Во время ревизии были проданы следующие бутылки:',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...soldBottles.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.remove_circle, 
                       color: theme.colorScheme.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value, // название карточки
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Ревизия автоматически обновлена с учетом изменений',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getAuditTitle(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              widget.audit.isActive ? 'Активная ревизия' : 'Завершенная ревизия',
              style: TextStyle(
                fontSize: 12,
                color: widget.audit.isActive 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (widget.audit.isActive)
            IconButton(
              onPressed: _continueScanning,
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Продолжить сканирование',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildStatisticsHeader(),
          _buildFilterTabs(),
          Expanded(
            child: _buildDetailsList(),
          ),
        ],
      ),
      floatingActionButton: widget.audit.isActive ? _buildActiveAuditButtons() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  String _getAuditTitle() {
    final date = widget.audit.startTime;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    
    return 'Ревизия $day.$month.$year в $hour:$minute';
  }

  Widget _buildStatisticsHeader() {
    final audit = widget.audit;
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // Используем цвет темы вместо Colors.white
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Основная статистика
          Row(
            children: [
              _buildStatCard(
                'Найдено',
                '${audit.totalFoundBottles}',
                '${audit.totalExpected}',
                Icons.inventory_2,
                theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Прогресс',
                '${audit.progressPercent.toStringAsFixed(0)}%',
                audit.isActive ? 'активна' : 'завершена',
                Icons.trending_up,
                audit.isActive 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.secondary,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Время',
                audit.displayDuration,
                audit.isActive ? 'идет' : 'финиш',
                Icons.timer,
                theme.colorScheme.secondary,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Прогресс-бар
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Общий прогресс',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${audit.totalScanned} из ${audit.totalExpected}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: audit.progressPercent / 100,
                backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  audit.isActive 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.secondary,
                ),
                minHeight: 6,
              ),
            ],
          ),
          
          // Расхождения и проданные бутылки (если есть)
          if (audit.hasDiscrepancies || audit.unknownBottlesCount > 0 || audit.soldBottlesCount > 0) ...[
            const SizedBox(height: 16),
            _buildDiscrepanciesSummary(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscrepanciesSummary() {
    final audit = widget.audit;
    final discrepancies = audit.getDiscrepancies();
    
    // Правильный подсчет: считаем общее количество недостающих и лишних бутылок
    int totalShortage = 0;
    int totalExcess = 0;
    
    for (final discrepancy in discrepancies.values) {
      if (discrepancy < 0) {
        totalShortage += (-discrepancy); // превращаем отрицательное в положительное
      } else if (discrepancy > 0) {
        totalExcess += discrepancy;
      }
    }
    
    final theme = Theme.of(context);
    final warningColor = theme.colorScheme.primary; // Используем primary вместо error для менее агрессивного вида
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warningColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Основная информация о расхождениях
          if (audit.hasDiscrepancies)
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: warningColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${audit.discrepanciesCount} расхождений: $totalShortage недостач, $totalExcess излишков',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: warningColor,
                    ),
                  ),
                ),
              ],
            ),
          
          // Проданные бутылки во время ревизии
          if (audit.soldBottlesCount > 0) ...[
            if (audit.hasDiscrepancies) const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.shopping_cart, color: theme.colorScheme.secondary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Продано во время ревизии: ${audit.soldBottlesCount} бутылок',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          // Неизвестные бутылки и последняя синхронизация
          Row(
            children: [
              if (audit.unknownBottlesCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${audit.unknownBottlesCount} неизв.',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (audit.lastSyncTime != null) ...[
                Expanded(
                  child: Text(
                    'Синхронизация: ${_formatSyncTime(audit.lastSyncTime!)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatSyncTime(DateTime syncTime) {
    final now = DateTime.now();
    final diff = now.difference(syncTime);
    
    if (diff.inMinutes < 1) {
      return 'только что';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} мин назад';
    } else {
      return '${syncTime.hour.toString().padLeft(2, '0')}:${syncTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildFilterTabs() {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'Все карточки', Icons.view_list),
            const SizedBox(width: 8),
            _buildFilterChip('discrepancies', 'Расхождения', Icons.warning_amber),
            const SizedBox(width: 8),
            _buildFilterChip('missing', 'Недостачи', Icons.remove_circle),
            const SizedBox(width: 8),
            _buildFilterChip('excess', 'Излишки', Icons.add_circle),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String mode, String label, IconData icon) {
    final isSelected = _filterMode == mode;
    final theme = Theme.of(context);
    
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected 
              ? Colors.white 
              : theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _filterMode = mode;
        });
      },
      backgroundColor: theme.colorScheme.surface, // Используем цвет темы
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected 
          ? Colors.white 
          : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildDetailsList() {
    final filteredCards = _getFilteredCards();
    
    if (filteredCards.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16).copyWith(bottom: 100), // Отступ для кнопок
      itemCount: filteredCards.length + 
                 (widget.audit.unknownBottlesCount > 0 && _filterMode == 'all' ? 1 : 0),
      itemBuilder: (context, index) {
        // Неизвестные бутылки в конце списка
        if (index == filteredCards.length && widget.audit.unknownBottlesCount > 0) {
          return _buildUnknownBottlesCard();
        }
        
        final cardId = filteredCards[index];
        return _buildCardDetailTile(cardId);
      },
    );
  }

  List<String> _getFilteredCards() {
    final audit = widget.audit;
    final discrepancies = audit.getDiscrepancies();
    
    switch (_filterMode) {
      case 'discrepancies':
        return discrepancies.keys.toList();
      case 'missing':
        return discrepancies.entries
          .where((e) => e.value < 0)
          .map((e) => e.key)
          .toList();
      case 'excess':
        return discrepancies.entries
          .where((e) => e.value > 0)
          .map((e) => e.key)
          .toList();
      default: // 'all'
        return audit.expectedBottles.keys.toList();
    }
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    String message;
    switch (_filterMode) {
      case 'discrepancies':
        message = '🎉 Нет расхождений!\nВсе в порядке';
        break;
      case 'missing':
        message = '✅ Нет недостач!\nВсе бутылки на месте';
        break;
      case 'excess':
        message = '📊 Нет излишков!\nТочное соответствие';
        break;
      default:
        message = '📦 Нет данных\nдля отображения';
    }
    
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildCardDetailTile(String cardId) {
    final audit = widget.audit;
    final card = cardsBox.get(cardId);
    final theme = Theme.of(context);
    
    if (card == null) return const SizedBox.shrink();
    
    final expected = audit.expectedBottles[cardId] ?? 0;
    final found = audit.foundBottles[cardId]?.length ?? 0;
    final discrepancy = found - expected;
    
    // Используем цвета темы для статусов
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (discrepancy == 0) {
      statusColor = theme.colorScheme.secondary; // Используем secondary для "норма"
      statusIcon = Icons.check_circle;
      statusText = 'Норма';
    } else if (discrepancy < 0) {
      statusColor = theme.colorScheme.primary; // Используем primary для недостач (менее агрессивный цвет)
      statusIcon = Icons.remove_circle;
      statusText = 'Недостача ${-discrepancy}';
    } else {
      statusColor = theme.colorScheme.secondary; // Используем secondary для излишков
      statusIcon = Icons.add_circle;
      statusText = 'Излишек +$discrepancy';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // Используем цвет темы
        borderRadius: BorderRadius.circular(16),
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
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.wine_bar,
            color: theme.colorScheme.primary,
            size: 28,
          ),
        ),
        title: Text(
          card.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${card.country} • ${card.year}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Ожидалось: $expected',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Найдено: $found',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnknownBottlesCard() {
    final theme = Theme.of(context);
    final warningColor = theme.colorScheme.primary; // Используем primary вместо error
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // Используем цвет темы
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warningColor.withOpacity(0.3)),
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
            color: warningColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.help_outline,
            color: warningColor,
            size: 28,
          ),
        ),
        title: const Text(
          'Неизвестные бутылки',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            const Text('Штрихкоды не из вашей винотеки'),
            const SizedBox(height: 8),
            Text(
              'Найдено: ${widget.audit.unknownBottlesCount} бутылок',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: warningColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error, color: warningColor, size: 16),
              const SizedBox(width: 4),
              Text(
                'Проверить',
                style: TextStyle(
                  color: warningColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveAuditButtons() {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Кнопка завершения ревизии
          Expanded(
            child: FloatingActionButton.extended(
              onPressed: _completeAudit,
              backgroundColor: theme.colorScheme.secondary, // Используем secondary вместо error
              foregroundColor: Colors.white,
              heroTag: "complete_audit",
              label: const Text(
                'Завершить ревизию',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              icon: const Icon(Icons.check_circle_outline),
            ),
          ),
          const SizedBox(width: 16),
          // Кнопка продолжения сканирования
          Expanded(
            child: FloatingActionButton.extended(
              onPressed: _continueScanning,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              heroTag: "continue_scan",
              label: const Text(
                'Продолжить сканирование',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              icon: const Icon(Icons.qr_code_scanner),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    final theme = Theme.of(context);
    
    return FloatingActionButton.extended(
      onPressed: _continueScanning,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      label: const Text(
        'Продолжить сканирование',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      icon: const Icon(Icons.qr_code_scanner),
    );
  }

  void _continueScanning() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(
          mode: 'audit',
          auditSession: widget.audit,
        ),
      ),
    ).then((_) {
      // Обновляем данные после возврата из сканера
      if (mounted) {
        // Выполняем синхронизацию при возврате
        _performAutoSync();
      }
    });
  }

  void _completeAudit() async {
    final audit = widget.audit;
    final theme = Theme.of(context);
    
    if (audit == null || !audit.isActive) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface, // Используем цвет темы
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Завершить ревизию?',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Отсканировано: ${audit.totalScanned} из ${audit.totalExpected} бутылок',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            Text(
              'Прогресс: ${audit.progressPercent.toStringAsFixed(1)}%',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            if (audit.unknownBottlesCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ Найдено ${audit.unknownBottlesCount} неизвестных бутылок',
                style: TextStyle(color: theme.colorScheme.primary), // Используем primary
              ),
            ],
            if (audit.hasDiscrepancies) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ Обнаружены расхождения в ${audit.discrepanciesCount} карточках',
                style: TextStyle(color: theme.colorScheme.primary), // Используем primary
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отменить'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary, // Используем secondary
            ),
            child: const Text('Завершить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      // Завершаем ревизию
      audit.complete();
      await auditBox.put(audit.id, audit);

      if (mounted) {
        // Возвращаемся к списку ревизий
        Navigator.pop(context);
        
        // Показываем уведомление
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Ревизия завершена!\nРезультаты сохранены'),
            backgroundColor: theme.colorScheme.secondary, // Используем secondary для успеха
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}