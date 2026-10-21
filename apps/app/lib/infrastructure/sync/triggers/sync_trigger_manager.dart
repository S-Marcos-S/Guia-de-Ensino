import 'dart:async';

import '../../../core/network/connectivity_service.dart';
import '../../../domain/models/auth_session.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../orchestrator/sync_orchestrator.dart';
import '../outbox/sync_outbox_item.dart';
import '../outbox/sync_outbox_repository.dart';

/// Gerenciador de gatilhos automáticos e manuais de sincronização.
///
/// Coordena a execução de [SyncOrchestrator.synchronize] reagindo a:
/// 1. Entrada ou restauração de sessão autenticada.
/// 2. Retorno de conectividade de rede (offline -> online).
/// 3. Solicitação manual do usuário.
/// 4. Novas mutações locais na Outbox (com debounce).
///
/// Garante que:
/// - Sincronizações ocorram estritamente sob sessão autenticada válida e com rede ativa.
/// - Não ocorram tempestades de requisições através de agrupamento e debounce.
/// - Condições de corrida sejam prevenidas por meio de agendamento sequencial (coalescing).
/// - Falhas transitórias sejam absorvidas com segurança sem perda de operações pendentes.
class SyncTriggerManager {
  SyncTriggerManager({
    required this.orchestratorProvider,
    required this.authRepository,
    required this.connectivityService,
    required this.outboxRepository,
    this.debounceDuration = const Duration(milliseconds: 1500),
  }) {
    _init();
  }

  /// Provedor dinâmico da instância ativa de [SyncOrchestrator].
  final SyncOrchestrator? Function() orchestratorProvider;

  /// Repositório de autenticação para verificação de ciclo de vida e sessão ativa.
  final AuthRepository authRepository;

  /// Serviço observável de conectividade de rede.
  final ConnectivityService connectivityService;

  /// Repositório da Outbox para escuta de mutações locais.
  final SyncOutboxRepository outboxRepository;

  /// Janela de debounce para mutações sucessivas na Outbox.
  final Duration debounceDuration;

  StreamSubscription<AuthSession?>? _sessionSubscription;
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<SyncOutboxItem>? _outboxSubscription;

  final StreamController<bool> _syncingController =
      StreamController<bool>.broadcast();
  final StreamController<SyncResult> _resultController =
      StreamController<SyncResult>.broadcast();

  SyncResult? _lastResult;
  Timer? _debounceTimer;
  bool _hasPendingSyncRequest = false;
  bool _isDisposed = false;

  /// Retorna o último resultado de sincronização registrado nesta sessão.
  SyncResult? get lastResult => _lastResult;

  /// Stream que emite quando o status de execução da sincronização é alterado.
  Stream<bool> get onSyncingChanged => _syncingController.stream;

  /// Stream que emite o resultado de cada ciclo de sincronização concluído.
  Stream<SyncResult> get onSyncCompleted => _resultController.stream;

  /// Indica se um ciclo de sincronização está ativo no momento.
  bool get isSyncing => orchestratorProvider()?.isSyncing ?? false;

  void _init() {
    // Gatilho 1: Entrada ou restauração de sessão autenticada
    _sessionSubscription = authRepository.sessionStream.listen((session) {
      if (session != null) {
        if (connectivityService.isOnline) {
          triggerSync(source: 'session_login');
        }
      } else {
        // Logout ou expiração: cancela agendamentos imediatamente
        cancelPending();
      }
    });

    // Gatilho 2: Retorno da conectividade (offline -> online)
    _connectivitySubscription = connectivityService.onConnectivityChanged
        .listen((online) {
          if (online && authRepository.isAuthenticated) {
            triggerSync(source: 'connectivity_restored');
          }
        });

    // Gatilho 4: Novas mutações na Outbox com debounce
    _outboxSubscription = outboxRepository.mutationStream.listen((_) {
      if (authRepository.isAuthenticated && connectivityService.isOnline) {
        _scheduleDebouncedSync();
      }
    });

    // Se já iniciar autenticado e online, agenda sincronização inicial
    if (authRepository.isAuthenticated && connectivityService.isOnline) {
      triggerSync(source: 'initial_state');
    }
  }

  /// Agenda uma sincronização com debounce após inserção de itens na Outbox.
  void _scheduleDebouncedSync() {
    if (_isDisposed || !authRepository.isAuthenticated) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      triggerSync(source: 'outbox_mutation_debounced');
    });
  }

  /// Cancela o temporizador de debounce e descarta requisições pendentes.
  void cancelPending() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _hasPendingSyncRequest = false;
  }

  /// Gatilho 3 (e despachante central): executa o ciclo de sincronização de forma coordenada.
  ///
  /// Retorna o [SyncResult] da execução, ou `null` caso a sincronização
  /// não possa ser realizada (usuário não autenticado, sem rede, ou disposed).
  Future<SyncResult?> triggerSync({String source = 'manual'}) async {
    if (_isDisposed) return null;

    // Regra inviolável: nunca sincronizar sem autenticação válida
    if (!authRepository.isAuthenticated) {
      return null;
    }

    // Regra: não tentar se estiver offline
    if (!connectivityService.isOnline) {
      return null;
    }

    final orchestrator = orchestratorProvider();
    if (orchestrator == null) {
      return null;
    }

    // Se o orquestrador já está ocupado, registra solicitação pendente para rodar logo após
    if (orchestrator.isSyncing) {
      _hasPendingSyncRequest = true;
      return const SyncResult.alreadyInProgress();
    }

    _syncingController.add(true);
    try {
      final result = await orchestrator.synchronize(rethrowExceptions: false);
      _lastResult = result;
      _resultController.add(result);

      // Ao término, se houver solicitação pendente acumulada durante a execução:
      if (_hasPendingSyncRequest &&
          !_isDisposed &&
          authRepository.isAuthenticated &&
          connectivityService.isOnline) {
        _hasPendingSyncRequest = false;
        // Executa uma rodada subsequente (follow-up) para garantir consistência
        return await triggerSync(source: 'pending_follow_up');
      }

      return result;
    } catch (e) {
      // Captura defensiva de falhas para isolar a interface
      final failure = SyncResult.failure(error: e);
      _lastResult = failure;
      _resultController.add(failure);
      return failure;
    } finally {
      if (!_isDisposed) {
        _syncingController.add(false);
      }
    }
  }

  /// Desativa todos os observadores, cancela timers e libera recursos.
  void dispose() {
    _isDisposed = true;
    cancelPending();
    _sessionSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _outboxSubscription?.cancel();
    _syncingController.close();
    _resultController.close();
  }
}
