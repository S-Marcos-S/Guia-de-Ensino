import 'package:app/core/localization/app_strings.dart';
import 'package:app/core/responsive/responsive_layout.dart';
import 'package:app/presentation/screens/calendar_screen.dart';
import 'package:app/presentation/screens/classrooms_screen.dart';
import 'package:app/presentation/screens/contents_screen.dart';
import 'package:app/presentation/screens/home_screen.dart';
import 'package:app/presentation/screens/replanning_screen.dart';
import 'package:flutter/material.dart';

/// Estrutura de navegação principal adaptável (BottomNavigationBar para Mobile, NavigationRail para Desktop).
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(onNavigateToTab: _onTabSelected),
      const ClassroomsScreen(),
      const CalendarScreen(),
      const ContentsScreen(),
      const ReplanningScreen(),
    ];

    return ResponsiveLayout(
      // Layout Móvel (BottomNavigationBar com botões grandes e ícones claros)
      mobileBody: Scaffold(
        body: IndexedStack(index: _currentIndex, children: screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: AppStrings.navHome,
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups),
              label: AppStrings.navClassrooms,
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: AppStrings.navCalendar,
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: AppStrings.navContents,
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_mode_outlined),
              selectedIcon: Icon(Icons.auto_mode),
              label: AppStrings.navReplanning,
            ),
          ],
        ),
      ),
      // Layout Desktop (NavigationRail lateral para telas amplas)
      desktopBody: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTabSelected,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Icon(
                  Icons.school,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text(AppStrings.navHome),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups),
                  label: Text(AppStrings.navClassrooms),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: Text(AppStrings.navCalendar),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: Text(AppStrings.navContents),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.auto_mode_outlined),
                  selectedIcon: Icon(Icons.auto_mode),
                  label: Text(AppStrings.navReplanning),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: screens),
            ),
          ],
        ),
      ),
    );
  }
}
