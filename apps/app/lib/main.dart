import 'package:app/core/di/app_dependencies.dart';
import 'package:app/core/localization/app_strings.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/presentation/navigation/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  final dependencies = AppDependencies(database: database);
  runApp(GuiaDeEnsinoApp(dependencies: dependencies));
}

/// Widget raiz da aplicação Guia de Ensino com injeção de dependências desacoplada.
class GuiaDeEnsinoApp extends StatelessWidget {
  const GuiaDeEnsinoApp({super.key, this.dependencies});

  final AppDependencies? dependencies;

  @override
  Widget build(BuildContext context) {
    final effectiveDeps =
        dependencies ?? AppDependencies(database: AppDatabase());

    return AppDependencyScope(
      dependencies: effectiveDeps,
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const MainScaffold(),
      ),
    );
  }
}
