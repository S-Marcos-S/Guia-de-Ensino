/// Contrato abstrato para persistência segura e isolada de tokens JWT no dispositivo.
///
/// Desacoplado de plugins nativos e do hardware para viabilizar testes unitários
/// e implementações intercambiáveis conforme a plataforma (ADR 0004).
abstract interface class TokenStorage {
  /// Recupera o token persistido, ou `null` caso nenhum token exista.
  Future<String?> readToken();

  /// Grava o token de forma segura e atômica.
  Future<void> writeToken(String token);

  /// Remove permanentemente o token armazenado.
  Future<void> deleteToken();

  /// Verifica se há um token persistido sem expor seu conteúdo.
  Future<bool> hasToken();
}
