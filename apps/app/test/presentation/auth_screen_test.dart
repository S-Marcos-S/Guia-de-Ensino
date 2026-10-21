import 'dart:async';

import 'package:app/core/di/app_dependencies.dart';
import 'package:app/core/localization/app_strings.dart';
import 'package:app/domain/models/auth_session.dart';
import 'package:app/domain/models/auth_user.dart';
import 'package:app/domain/repositories/auth_repository.dart';
import 'package:app/infrastructure/auth/exceptions/auth_exceptions.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/presentation/screens/auth_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthSession? initialSession})
    : _currentSession = initialSession;

  final StreamController<AuthSession?> _controller =
      StreamController<AuthSession?>.broadcast();
  AuthSession? _currentSession;

  String? lastLoginEmail;
  String? lastLoginPassword;
  String? lastRegisterEmail;
  String? lastRegisterPassword;
  bool throwOnLogin = false;
  Exception? loginException;
  bool throwOnRegister = false;
  Exception? registerException;

  @override
  AuthSession? get currentSession => _currentSession;

  @override
  bool get isAuthenticated => _currentSession != null;

  @override
  Stream<AuthSession?> get sessionStream => _controller.stream;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    lastLoginEmail = email;
    lastLoginPassword = password;
    if (throwOnLogin) {
      throw loginException ?? const InvalidCredentialsException();
    }
    final session = AuthSession(
      token: 'fake-jwt-token',
      user: AuthUser(id: 'u1', email: email),
    );
    _currentSession = session;
    _controller.add(session);
    return session;
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    lastRegisterEmail = email;
    lastRegisterPassword = password;
    if (throwOnRegister) {
      throw registerException ?? const EmailAlreadyInUseException();
    }
    final session = AuthSession(
      token: 'fake-jwt-token',
      user: AuthUser(id: 'u2', email: email),
    );
    _currentSession = session;
    _controller.add(session);
    return session;
  }

  @override
  Future<AuthUser> fetchCurrentUser() async {
    if (_currentSession == null) throw const InvalidCredentialsException();
    return _currentSession!.user;
  }

  @override
  Future<AuthSession?> restoreSession() async => _currentSession;

  @override
  Future<void> logout() async {
    _currentSession = null;
    _controller.add(null);
  }

  @override
  void dispose() {
    _controller.close();
  }
}

Widget createTestApp({
  required AppDependencies dependencies,
  AuthFormMode initialMode = AuthFormMode.login,
  VoidCallback? onSuccess,
}) {
  return AppDependencyScope(
    dependencies: dependencies,
    child: MaterialApp(
      home: AuthScreen(initialMode: initialMode, onSuccess: onSuccess),
    ),
  );
}

void main() {
  late AppDatabase db;
  late FakeAuthRepository fakeAuth;
  late AppDependencies dependencies;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    fakeAuth = FakeAuthRepository();
    dependencies = AppDependencies(database: db, authRepository: fakeAuth);
  });

  tearDown(() async {
    dependencies.dispose();
    fakeAuth.dispose();
    await db.close();
  });

  group('AuthScreen Widget Tests', () {
    testWidgets(
      'deve renderizar campos de login e botão de convidado por padrão',
      (tester) async {
        await tester.pumpWidget(createTestApp(dependencies: dependencies));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.authScreenTitleLogin), findsOneWidget);
        expect(find.text(AppStrings.authEmailLabel), findsOneWidget);
        expect(find.text(AppStrings.authPasswordLabel), findsOneWidget);
        expect(find.text(AppStrings.authConfirmPasswordLabel), findsNothing);
        expect(find.text(AppStrings.authLoginButton), findsOneWidget);
        expect(find.text(AppStrings.authGuestButton), findsOneWidget);
      },
    );

    testWidgets(
      'deve alternar para modo cadastro e exibir confirmação de senha',
      (tester) async {
        await tester.pumpWidget(createTestApp(dependencies: dependencies));
        await tester.pumpAndSettle();

        final registerSegment = find.text(AppStrings.authTabRegister);
        await tester.tap(registerSegment);
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.authScreenTitleRegister), findsOneWidget);
        expect(find.text(AppStrings.authConfirmPasswordLabel), findsOneWidget);
        expect(find.text(AppStrings.authRegisterButton), findsOneWidget);
      },
    );

    testWidgets('deve validar formulário contra campos vazios e senha curta', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(dependencies: dependencies));
      await tester.pumpAndSettle();

      // Clica em Entrar com campos em branco
      await tester.tap(find.text(AppStrings.authLoginButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.authValidationEmailRequired), findsOneWidget);
      expect(
        find.text(AppStrings.authValidationPasswordRequired),
        findsOneWidget,
      );

      // Preenche senha menor que 8 caracteres
      await tester.enterText(
        find.widgetWithText(TextFormField, AppStrings.authPasswordLabel),
        '123',
      );
      await tester.tap(find.text(AppStrings.authLoginButton));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.authValidationPasswordMinLength),
        findsOneWidget,
      );
    });

    testWidgets('deve validar divergência entre senhas no modo cadastro', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          dependencies: dependencies,
          initialMode: AuthFormMode.register,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, AppStrings.authEmailLabel),
        'professor@escola.gov.br',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, AppStrings.authPasswordLabel),
        'SenhaForte123!',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, AppStrings.authConfirmPasswordLabel),
        'OutraSenha456!',
      );

      await tester.tap(find.text(AppStrings.authRegisterButton));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.authValidationPasswordsDoNotMatch),
        findsOneWidget,
      );
    });

    testWidgets('deve realizar login com sucesso e disparar callback', (
      tester,
    ) async {
      var successCalled = false;

      await tester.pumpWidget(
        createTestApp(
          dependencies: dependencies,
          onSuccess: () => successCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, AppStrings.authEmailLabel),
        'professor@escola.gov.br',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, AppStrings.authPasswordLabel),
        'SenhaValida123!',
      );

      await tester.tap(find.text(AppStrings.authLoginButton));
      await tester.pumpAndSettle();

      expect(fakeAuth.lastLoginEmail, equals('professor@escola.gov.br'));
      expect(fakeAuth.lastLoginPassword, equals('SenhaValida123!'));
      expect(successCalled, isTrue);
      expect(fakeAuth.isAuthenticated, isTrue);
    });

    testWidgets('deve exibir mensagem de erro amigável ao falhar credenciais', (
      tester,
    ) async {
      fakeAuth.throwOnLogin = true;
      fakeAuth.loginException = const InvalidCredentialsException();

      await tester.pumpWidget(createTestApp(dependencies: dependencies));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, AppStrings.authEmailLabel),
        'invalido@escola.gov.br',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, AppStrings.authPasswordLabel),
        'SenhaIncorreta123!',
      );

      await tester.tap(find.text(AppStrings.authLoginButton));
      await tester.pumpAndSettle();

      expect(
        find.text('Credenciais inválidas. Verifique seu e-mail e senha.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'deve tratar falha de rede sem bloquear e sem simular sucesso',
      (tester) async {
        fakeAuth.throwOnLogin = true;
        fakeAuth.loginException = const AuthNetworkException('Network timeout');

        await tester.pumpWidget(createTestApp(dependencies: dependencies));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, AppStrings.authEmailLabel),
          'offline@escola.gov.br',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, AppStrings.authPasswordLabel),
          'SenhaOffline123!',
        );

        await tester.tap(find.text(AppStrings.authLoginButton));
        await tester.pumpAndSettle();

        expect(
          find.text('Falha de conexão com o servidor. Verifique sua internet.'),
          findsOneWidget,
        );
        expect(fakeAuth.isAuthenticated, isFalse);
      },
    );

    testWidgets('modo convidado deve permitir navegação sem acionar login', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                child: const Text('Abrir Auth'),
                onPressed: () {
                  Navigator.of(ctx).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AppDependencyScope(
                        dependencies: dependencies,
                        child: const AuthScreen(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Auth'));
      await tester.pumpAndSettle();

      expect(find.byType(AuthScreen), findsOneWidget);

      await tester.tap(find.text(AppStrings.authGuestButton));
      await tester.pumpAndSettle();

      expect(find.byType(AuthScreen), findsNothing);
      expect(fakeAuth.lastLoginEmail, isNull);
      expect(fakeAuth.isAuthenticated, isFalse);
    });
  });
}
