import 'token_storage.dart';

/// Implementação em memória de [TokenStorage], ideal para testes e ambientes simulados.
class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage([String? initialToken]) : _token = initialToken;

  String? _token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> writeToken(String token) async {
    _token = token;
  }

  @override
  Future<void> deleteToken() async {
    _token = null;
  }

  @override
  Future<bool> hasToken() async => _token != null && _token!.isNotEmpty;
}
