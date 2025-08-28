import 'package:flutter/material.dart';
import 'package:winekeeper/core/app_theme.dart';
import 'package:winekeeper/screens/home_screen.dart';
import 'package:winekeeper/screens/add_wine_screen.dart';
import 'package:winekeeper/screens/barcode_scanner_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 2; // Винотека по умолчанию (центральная)

  // Только экраны с сохранением состояния (без модальных)
  final List<Widget> _screens = [
    const PlaceholderScreen(title: 'Создать', icon: Icons.add_circle),
    const PlaceholderScreen(title: 'Продать', icon: Icons.attach_money),
    const HomeScreen(), // Винотека
    const PlaceholderScreen(title: 'Ревизия', icon: Icons.inventory_2),
    const PlaceholderScreen(title: 'Отчеты', icon: Icons.analytics),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFFAF5EF), // Ivory
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: SafeArea(
      child: SizedBox(
        height: 80,
        child: Stack(
          clipBehavior: Clip.none, // Позволяет выходить за границы
          alignment: Alignment.center,
          children: [
            // Основная панель навигации (без центральной кнопки)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.add_circle_outline, Icons.add_circle, 'Создать'),
                _buildNavItem(1, Icons.attach_money_outlined, Icons.attach_money, 'Продать'),
                const SizedBox(width: 70), // Пространство для центральной кнопки
                _buildNavItem(3, Icons.inventory_2_outlined, Icons.inventory_2, 'Ревизия'),
                _buildNavItem(4, Icons.analytics_outlined, Icons.analytics, 'Отчеты'),
              ],
            ),
            
            // Выпуклая кнопка Винотека - выходит за границы панели
            Positioned(
              top: -15, // Поднимаем кнопку выше панели
              child: GestureDetector(
                onTap: () => _onDestinationSelected(2),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: _currentIndex == 2 
                        ? const Color(0xFFFF857A) 
                        : const Color(0xFFFAF5EF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF857A),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF857A).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.wine_bar,
                    size: 32,
                    color: _currentIndex == 2 
                        ? Colors.white 
                        : const Color(0xFFFF857A),
                  ),
                ),
              ),
            ),
            
            // Текст "Винотека" на уровне других надписей
            Positioned(
              bottom: 8, // На том же уровне, что и другие надписи
              child: Text(
                'Винотека',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: _currentIndex == 2 ? FontWeight.bold : FontWeight.normal,
                  color: _currentIndex == 2 
                      ? const Color(0xFFFF857A)
                      : const Color(0xFF362C2A).withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label) {
    final bool isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => _onDestinationSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF857A).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 24,
              color: isSelected 
                  ? const Color(0xFFFF857A)
                  : const Color(0xFF362C2A).withOpacity(0.7),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? const Color(0xFFFF857A)
                    : const Color(0xFF362C2A).withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDestinationSelected(int index) {
    // Обработка модальных экранов
    switch (index) {
      case 0: // Создать
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddWineScreen()),
        );
        break;
      case 1: // Продать
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const BarcodeScannerScreen(mode: 'sell'),
          ),
        );
        break;
      default:
        // Обычная навигация по вкладкам
        setState(() {
          _currentIndex = index;
        });
    }
  }
}

// Заглушка для будущих экранов с красивым дизайном
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFFFAF5EF),
        foregroundColor: const Color(0xFF362C2A),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFFAF5EF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFF857A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                icon,
                size: 60,
                color: const Color(0xFFFF857A),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF362C2A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Функционал будет реализован\nв следующих версиях',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF362C2A).withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}