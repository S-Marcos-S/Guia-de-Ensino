import 'package:app/core/localization/app_strings.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/presentation/navigation/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GuiaDeEnsinoApp());
}

/// Widget raiz da aplicação Guia de Ensino.
class GuiaDeEnsinoApp extends StatelessWidget {
  const GuiaDeEnsinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}
