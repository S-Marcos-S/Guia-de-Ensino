import 'dart:async';

import 'package:app/core/di/app_dependencies.dart';
import 'package:app/core/localization/app_strings.dart';
import 'package:app/core/network/connectivity_service.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/infrastructure/auth/client/auth_api_client.dart';
import 'package:app/infrastructure/auth/repositories/auth_repository_impl.dart';
import 'package:app/infrastructure/auth/storage/secure_file_token_storage.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/presentation/navigation/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();

  final tokenStorage = SecureFileTokenStorage(
    directoryProvider: () => getApplicationDocumentsDirectory(),
  );

  final authRepository = AuthRepositoryImpl(
    apiClient: AuthApiClient(baseUrl: AppDependencies.defaultApiBaseUrl),
    tokenStorage: tokenStorage,
  );

  final connectivityService = DefaultConnectivityService();
  connectivityService.startMonitoring();

  // Inicia restauração assíncrona da sessão sem bloquear a inicialização da UI
  unawaited(authRepository.restoreSession().catchError((_) => null));

  final dependencies = AppDependencies(
    database: database,
    authRepository: authRepository,
    connectivityService: connectivityService,
  );

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
