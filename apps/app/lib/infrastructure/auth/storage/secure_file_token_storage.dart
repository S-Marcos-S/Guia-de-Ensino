import 'dart:convert';
import 'dart:io';

import 'token_storage.dart';

/// Implementação de [TokenStorage] que persiste o token no diretório privado e
/// restrito da aplicação no dispositivo (conforme ADR 0004).
///
/// No Android e Linux, arquivos criados no diretório privado da aplicação
/// possuem controle de acesso discricionário (DAC) exclusivo para o UID do app.
/// O conteúdo do token é armazenado de forma isolada e nunca é exposto em logs.
class SecureFileTokenStorage implements TokenStorage {
  SecureFileTokenStorage({
    required this.directoryProvider,
    this.fileName = '.auth_token_vault',
  });

  final Future<Directory> Function() directoryProvider;
  final String fileName;

  Future<File> _getFile() async {
    final dir = await directoryProvider();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}/$fileName');
  }

  @override
  Future<String?> readToken() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return null;
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return null;
      }
      final decodedBytes = base64Decode(raw.trim());
      final token = utf8.decode(decodedBytes).trim();
      return token.isNotEmpty ? token : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeToken(String token) async {
    final file = await _getFile();
    final encoded = base64Encode(utf8.encode(token.trim()));
    await file.writeAsString(encoded, flush: true);

    try {
      if (!Platform.isWindows) {
        await Process.run('chmod', ['600', file.path]);
      }
    } catch (_) {
      // Ignora falha silenciosa de chmod em ambientes que não suportem o comando
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignora erro se o arquivo já não existir
    }
  }

  @override
  Future<bool> hasToken() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }
}
