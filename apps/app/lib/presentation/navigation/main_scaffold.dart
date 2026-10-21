import 'dart:async';

import 'package:app/core/di/app_dependencies.dart';
import 'package:app/core/localization/app_strings.dart';
import 'package:app/core/responsive/responsive_layout.dart';
import 'package:app/presentation/components/sync_status_indicator.dart';
import 'package:app/presentation/screens/auth_screen.dart';
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
  StreamSubscription<dynamic>? _sessionSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final deps = AppDependencyScope.of(context);
    _sessionSub?.cancel();
    _sessionSub = deps.authRepository.sessionStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showAccountDialog(BuildContext context, String email) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        icon: const Icon(Icons.account_circle, size: 40),
        title: const Text(AppStrings.authAccountMenuTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.authLoggedAs,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(email),
            const SizedBox(height: 16),
            const Text(
              'Suas alterações locais são sincronizadas automaticamente com a nuvem quando você está conectado à internet.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(AppStrings.closeButton),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _confirmLogout(context);
            },
            child: const Text(AppStrings.authLogoutButton),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        icon: const Icon(Icons.logout, size: 36),
        title: const Text(AppStrings.authLogoutConfirmTitle),
        content: const Text(AppStrings.authLogoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(confirmCtx).pop(),
            child: const Text(AppStrings.cancelButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              final deps = AppDependencyScope.of(context);
              Navigator.of(confirmCtx).pop();
              await deps.authRepository.logout();
            },
            child: const Text(AppStrings.authLogoutButton),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountButton(BuildContext context) {
    final deps = AppDependencyScope.of(context);
    final isAuth = deps.authRepository.isAuthenticated;
    final user = deps.authRepository.currentSession?.user;

    return IconButton(
      icon: Icon(isAuth ? Icons.account_circle : Icons.account_circle_outlined),
      tooltip: isAuth ? 'Conta: ${user?.email}' : 'Entrar ou Cadastrar',
      onPressed: () {
        if (!isAuth) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const AuthScreen()));
        } else {
          _showAccountDialog(context, user?.email ?? '');
        }
      },
    );
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
        appBar: AppBar(
          title: const Text(AppStrings.appName),
          actions: [
            const SyncStatusIndicator(compact: false),
            const SizedBox(width: 4),
            _buildAccountButton(context),
            const SizedBox(width: 8),
          ],
        ),
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
        appBar: AppBar(
          title: const Text(AppStrings.appName),
          actions: [
            const SyncStatusIndicator(compact: false),
            const SizedBox(width: 8),
            _buildAccountButton(context),
            const SizedBox(width: 16),
          ],
        ),
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
