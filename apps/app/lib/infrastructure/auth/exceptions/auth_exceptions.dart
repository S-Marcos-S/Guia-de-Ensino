/// Classe base hierárquica para todas as exceções de autenticação no Guia de Ensino.
abstract class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode, this.originalError});

  final String message;
  final int? statusCode;
  final Object? originalError;

  @override
  String toString() => message;
}

/// Disparada quando o backend rejeita as credenciais informadas (HTTP 401).
class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException([
    super.message = 'Credenciais inválidas. Verifique seu e-mail e senha.',
    int? statusCode = 401,
    Object? originalError,
  ]) : super(statusCode: statusCode, originalError: originalError);
}

/// Disparada quando há tentativa de cadastro com e-mail já existente (HTTP 409).
class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException([
    super.message = 'Já existe um usuário cadastrado com este e-mail.',
    int? statusCode = 409,
    Object? originalError,
  ]) : super(statusCode: statusCode, originalError: originalError);
}

/// Disparada quando os dados de entrada violam os requisitos de validação (HTTP 400 ou local).
class AuthValidationException extends AuthException {
  const AuthValidationException(
    super.message, {
    super.statusCode = 400,
    super.originalError,
  });
}

/// Disparada quando ocorre falha de transporte, timeout ou falta de conexão à internet.
class AuthNetworkException extends AuthException {
  const AuthNetworkException(
    super.message, {
    super.statusCode,
    super.originalError,
  });
}

/// Disparada quando o servidor responde com erro interno inesperado (HTTP 500+).
class AuthServerException extends AuthException {
  const AuthServerException(
    super.message, {
    super.statusCode,
    super.originalError,
  });
}

/// Disparada quando o corpo da resposta não pôde ser decodificado como JSON válido.
class AuthFormatException extends AuthException {
  const AuthFormatException(
    super.message, {
    super.statusCode,
    super.originalError,
  });
}

/// Disparada quando uma operação autenticada é requisitada sem sessão ativa.
class UnauthenticatedException extends AuthException {
  const UnauthenticatedException([
    super.message = 'Nenhuma sessão de usuário ativa.',
  ]);
}
