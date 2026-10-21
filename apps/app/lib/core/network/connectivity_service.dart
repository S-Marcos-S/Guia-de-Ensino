import 'dart:async';
import 'dart:io';

/// Contrato abstrato para observabilidade do estado de conectividade de rede.
/// Desacoplado de plugins de plataforma para viabilizar testes determinísticos.
abstract interface class ConnectivityService {
  /// Retorna o estado atual de conectividade conhecido de forma síncrona.
  bool get isOnline;

  /// Stream que emite atualizações booleanas sempre que a conectividade muda.
  Stream<bool> get onConnectivityChanged;

  /// Força uma verificação ativa de conectividade e atualiza o estado interno.
  Future<bool> checkConnectivity();

  /// Encerra recursos e streams associados.
  void dispose();
}

/// Implementação em memória de [ConnectivityService], ideal para testes e simulações.
class InMemoryConnectivityService implements ConnectivityService {
  InMemoryConnectivityService([bool initialOnline = true])
    : _isOnline = initialOnline;

  bool _isOnline;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  bool get isOnline => _isOnline;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Altera programaticamente o estado de conectividade para simular quedas e retornos de rede.
  void setOnline(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      _controller.add(online);
    }
  }

  @override
  Future<bool> checkConnectivity() async => _isOnline;

  @override
  void dispose() {
    _controller.close();
  }
}

/// Implementação padrão de [ConnectivityService] baseada em resolução de DNS via `dart:io`.
class DefaultConnectivityService implements ConnectivityService {
  DefaultConnectivityService({
    this.lookupHost = 'api.guiadeensino.com.br',
    this.checkInterval = const Duration(seconds: 30),
    bool initialOnline = true,
  }) : _isOnline = initialOnline;

  final String lookupHost;
  final Duration checkInterval;

  bool _isOnline;
  Timer? _timer;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  bool get isOnline => _isOnline;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Inicia monitoramento periódico de conectividade.
  void startMonitoring() {
    _timer?.cancel();
    _timer = Timer.periodic(checkInterval, (_) => checkConnectivity());
  }

  @override
  Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup(lookupHost)
          .timeout(const Duration(seconds: 5));
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _updateStatus(online);
      return online;
    } catch (_) {
      _updateStatus(false);
      return false;
    }
  }

  void _updateStatus(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      _controller.add(online);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
