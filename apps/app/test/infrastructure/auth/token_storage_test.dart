import 'dart:io';

import 'package:app/infrastructure/auth/storage/in_memory_token_storage.dart';
import 'package:app/infrastructure/auth/storage/secure_file_token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryTokenStorage', () {
    test('deve iniciar vazio por padrão', () async {
      final storage = InMemoryTokenStorage();
      expect(await storage.readToken(), isNull);
      expect(await storage.hasToken(), isFalse);
    });

    test('deve inicializar com token inicial se fornecido', () async {
      final storage = InMemoryTokenStorage('init-token-123');
      expect(await storage.readToken(), equals('init-token-123'));
      expect(await storage.hasToken(), isTrue);
    });

    test('deve gravar, ler e remover token com sucesso', () async {
      final storage = InMemoryTokenStorage();

      await storage.writeToken('my-secret-jwt');
      expect(await storage.readToken(), equals('my-secret-jwt'));
      expect(await storage.hasToken(), isTrue);

      await storage.deleteToken();
      expect(await storage.readToken(), isNull);
      expect(await storage.hasToken(), isFalse);
    });
  });

  group('SecureFileTokenStorage', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('token_storage_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('deve retornar null quando o arquivo não existir', () async {
      final storage = SecureFileTokenStorage(
        directoryProvider: () async => tempDir,
      );

      expect(await storage.readToken(), isNull);
      expect(await storage.hasToken(), isFalse);
    });

    test(
      'deve persistir token codificado e recuperá-lo integralmente',
      () async {
        final storage = SecureFileTokenStorage(
          directoryProvider: () async => tempDir,
          fileName: 'vault_test.dat',
        );

        const secretToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test-payload';
        await storage.writeToken(secretToken);

        // Verifica se o token é recuperado corretamente
        expect(await storage.readToken(), equals(secretToken));
        expect(await storage.hasToken(), isTrue);

        // Verifica que o arquivo no disco não contém o token em texto puro
        final file = File('${tempDir.path}/vault_test.dat');
        expect(file.existsSync(), isTrue);
        final rawDiskContent = file.readAsStringSync();
        expect(rawDiskContent, isNot(contains(secretToken)));
      },
    );

    test(
      'deve simular reinicialização do app e recuperar sessão persistida',
      () async {
        const secretToken = 'jwt-after-restart-token';

        // 1. Primeira instância grava o token e é descartada
        final storage1 = SecureFileTokenStorage(
          directoryProvider: () async => tempDir,
        );
        await storage1.writeToken(secretToken);

        // 2. Segunda instância é criada apontando para o mesmo diretório
        final storage2 = SecureFileTokenStorage(
          directoryProvider: () async => tempDir,
        );
        expect(await storage2.readToken(), equals(secretToken));
        expect(await storage2.hasToken(), isTrue);

        // 3. Remove o token e valida exclusão
        await storage2.deleteToken();
        expect(await storage2.readToken(), isNull);
        expect(await storage2.hasToken(), isFalse);
      },
    );

    test('deleteToken não deve falhar se o arquivo já não existir', () async {
      final storage = SecureFileTokenStorage(
        directoryProvider: () async => tempDir,
      );

      await expectLater(storage.deleteToken(), completes);
      expect(await storage.readToken(), isNull);
    });
  });
}
