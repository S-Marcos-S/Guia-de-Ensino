import 'dart:async';

import 'package:app/core/di/app_dependencies.dart';
import 'package:app/core/localization/app_strings.dart';
import 'package:app/infrastructure/sync/orchestrator/sync_orchestrator.dart';
import 'package:app/infrastructure/sync/outbox/sync_outbox_item.dart';
import 'package:app/presentation/components/sync_conflict_dialog.dart';
import 'package:app/presentation/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Estados representáveis pelo indicador visual de sincronização.
enum SyncUiState {
  /// Ciclo de sincronização em andamento (Push ou Pull).
  syncing,

  /// Dados sincronizados com sucesso e sem alterações pendentes.
  synced,

  /// Existem mutações locais salvas no dispositivo aguardando envio ao servidor.
  pending,

  /// O dispositivo está sem conectividade com a rede.
  offline,

  /// Ocorreu um erro no último ciclo de sincronização.
  error,

  /// Aplicativo em modo convidado / local (não autenticado).
  guest,
}

/// Indicador interativo do status de sincronização em tempo real.
///
/// Reage a alterações na conectividade, fila Outbox, autenticação e progresso
/// do orquestrador de sincronização, sem inventar capacidades nem declarar
/// sincronização concluída quando houver pendências ou falhas.
class SyncStatusIndicator extends StatefulWidget {
  const SyncStatusIndicator({super.key, this.compact = false});

  /// Se verdadeiro, exibe uma versão compacta (ideal para barras superiores densas).
  final bool compact;

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  SyncUiState _state = SyncUiState.guest;
  int _pendingCount = 0;
  String? _lastError;
  DateTime? _lastSyncedAt;
  SyncResult? _lastResult;
  bool _isOnline = true;
  bool _isAuthenticated = false;
  bool _isSyncing = false;

  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<dynamic>? _sessionSub;
  StreamSubscription<bool>? _syncingSub;
  StreamSubscription<SyncResult>? _resultSub;
  StreamSubscription<SyncOutboxItem>? _outboxSub;

  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribeDependencies();
    _refreshState();
  }

  void _subscribeDependencies() {
    final deps = AppDependencyScope.of(context);

    _connectivitySub?.cancel();
    _connectivitySub = deps.connectivityService.onConnectivityChanged.listen((
      online,
    ) {
      if (mounted) {
        setState(() => _isOnline = online);
        _refreshState();
      }
    });

    _sessionSub?.cancel();
    _sessionSub = deps.authRepository.sessionStream.listen((_) {
      if (mounted) {
        _refreshState();
      }
    });

    _syncingSub?.cancel();
    _syncingSub = deps.syncTriggerManager.onSyncingChanged.listen((syncing) {
      if (mounted) {
        setState(() => _isSyncing = syncing);
        if (syncing) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
          _rotationController.reset();
        }
        _refreshState();
      }
    });

    _resultSub?.cancel();
    _resultSub = deps.syncTriggerManager.onSyncCompleted.listen((result) {
      if (mounted) {
        setState(() => _lastResult = result);
        _refreshState();
      }
    });

    _outboxSub?.cancel();
    _outboxSub = deps.syncOutboxRepository.mutationStream.listen((_) {
      if (mounted) {
        _refreshState();
      }
    });
  }

  Future<void> _refreshState() async {
    if (!mounted) return;
    final deps = AppDependencyScope.of(context);

    final isAuth = deps.authRepository.isAuthenticated;
    final isOnline = deps.connectivityService.isOnline;
    final isSyncing = deps.syncTriggerManager.isSyncing;

    int pendingCount = 0;
    SyncStateItem? syncState;

    try {
      pendingCount = await deps.syncOutboxRepository
          .getPendingOperationsCount();
      syncState = await deps.syncOutboxRepository.getOrCreateSyncState();
    } catch (_) {
      // Isolamento defensivo de falhas em SQLite temporário
    }

    if (!mounted) return;

    final lastError = syncState?.lastSyncError;
    final lastSynced = syncState?.lastSyncedAt;

    SyncUiState computed;
    if (isSyncing) {
      computed = SyncUiState.syncing;
    } else if (!isAuth) {
      computed = SyncUiState.guest;
    } else if (!isOnline) {
      computed = SyncUiState.offline;
    } else if (lastError != null && lastError.isNotEmpty) {
      computed = SyncUiState.error;
    } else if (pendingCount > 0) {
      computed = SyncUiState.pending;
    } else {
      computed = SyncUiState.synced;
    }

    setState(() {
      _isAuthenticated = isAuth;
      _isOnline = isOnline;
      _isSyncing = isSyncing;
      _pendingCount = pendingCount;
      _lastError = lastError;
      _lastSyncedAt = lastSynced;
      _state = computed;
    });

    if (computed == SyncUiState.syncing && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (computed != SyncUiState.syncing &&
        _rotationController.isAnimating) {
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _connectivitySub?.cancel();
    _sessionSub?.cancel();
    _syncingSub?.cancel();
    _resultSub?.cancel();
    _outboxSub?.cancel();
    super.dispose();
  }

  void _onTapIndicator() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SyncDetailsSheet(
        state: _state,
        pendingCount: _pendingCount,
        lastError: _lastError,
        lastSyncedAt: _lastSyncedAt,
        lastResult: _lastResult,
        isOnline: _isOnline,
        isAuthenticated: _isAuthenticated,
        isSyncing: _isSyncing,
        onTriggerSync: () async {
          final deps = AppDependencyScope.of(context);
          final res = await deps.syncTriggerManager.triggerSync(
            source: 'manual_ui',
          );
          if (mounted) {
            setState(() => _lastResult = res);
            await _refreshState();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final IconData icon;
    final Color color;
    final String label;

    switch (_state) {
      case SyncUiState.syncing:
        icon = Icons.sync;
        color = colorScheme.primary;
        label = AppStrings.syncStatusSyncing;
        break;
      case SyncUiState.synced:
        icon = Icons.cloud_done_outlined;
        color = Colors.green.shade700;
        label = AppStrings.syncStatusSynced;
        break;
      case SyncUiState.pending:
        icon = Icons.cloud_upload_outlined;
        color = Colors.orange.shade800;
        label = _pendingCount == 1
            ? AppStrings.syncStatusPendingSingular
            : '$_pendingCount ${AppStrings.syncStatusPendingPlural}';
        break;
      case SyncUiState.offline:
        icon = Icons.cloud_off_outlined;
        color = colorScheme.outline;
        label = AppStrings.syncStatusOffline;
        break;
      case SyncUiState.error:
        icon = Icons.sync_problem_outlined;
        color = colorScheme.error;
        label = AppStrings.syncStatusError;
        break;
      case SyncUiState.guest:
        icon = Icons.cloud_queue_outlined;
        color = colorScheme.onSurfaceVariant;
        label = AppStrings.authGuestMode;
        break;
    }

    if (widget.compact) {
      return Tooltip(
        message: label,
        child: InkWell(
          onTap: _onTapIndicator,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _state == SyncUiState.syncing
                ? RotationTransition(
                    turns: _rotationController,
                    child: Icon(icon, color: color, size: 22),
                  )
                : Icon(icon, color: color, size: 22),
          ),
        ),
      );
    }

    return Tooltip(
      message: 'Toque para detalhes e sincronização manual',
      child: ActionChip(
        avatar: _state == SyncUiState.syncing
            ? RotationTransition(
                turns: _rotationController,
                child: Icon(icon, color: color, size: 16),
              )
            : Icon(icon, color: color, size: 16),
        label: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: color.withAlpha(25),
        side: BorderSide(color: color.withAlpha(80)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: _onTapIndicator,
      ),
    );
  }
}

/// Painel modal de detalhes da sincronização e ação manual.
class SyncDetailsSheet extends StatefulWidget {
  const SyncDetailsSheet({
    super.key,
    required this.state,
    required this.pendingCount,
    required this.lastError,
    required this.lastSyncedAt,
    required this.lastResult,
    required this.isOnline,
    required this.isAuthenticated,
    required this.isSyncing,
    required this.onTriggerSync,
  });

  final SyncUiState state;
  final int pendingCount;
  final String? lastError;
  final DateTime? lastSyncedAt;
  final SyncResult? lastResult;
  final bool isOnline;
  final bool isAuthenticated;
  final bool isSyncing;
  final Future<void> Function() onTriggerSync;

  @override
  State<SyncDetailsSheet> createState() => _SyncDetailsSheetState();
}

class _SyncDetailsSheetState extends State<SyncDetailsSheet> {
  bool _isManualSyncInProgress = false;

  Future<void> _handleManualSync() async {
    setState(() => _isManualSyncInProgress = true);
    try {
      await widget.onTriggerSync();
    } finally {
      if (mounted) {
        setState(() => _isManualSyncInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final deps = AppDependencyScope.of(context);
    final user = deps.authRepository.currentSession?.user;

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    final formattedLastSync = widget.lastSyncedAt != null
        ? dateFormat.format(widget.lastSyncedAt!.toLocal())
        : AppStrings.syncNever;

    final conflicts = widget.lastResult?.conflictDetails ?? const [];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de arrasto visual
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Cabeçalho do painel
              Row(
                children: [
                  Icon(
                    Icons.cloud_sync_outlined,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.syncDetailsTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          AppStrings.syncDetailsSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Seção da Conta / Modo Convidado
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withAlpha(90),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        widget.isAuthenticated
                            ? Icons.account_circle_outlined
                            : Icons.person_off_outlined,
                        color: colorScheme.primary,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isAuthenticated
                                  ? AppStrings.authLoggedAs
                                  : AppStrings.authGuestMode,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              widget.isAuthenticated
                                  ? (user?.email ?? 'Usuário autenticado')
                                  : AppStrings.authSignInPrompt,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!widget.isAuthenticated)
                        FilledButton.tonal(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const AuthScreen(),
                              ),
                            );
                          },
                          child: const Text('Entrar'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Status de Conectividade
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  widget.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: widget.isOnline
                      ? Colors.green.shade700
                      : colorScheme.error,
                ),
                title: Text(
                  widget.isOnline
                      ? AppStrings.syncConnectivityOnline
                      : AppStrings.syncConnectivityOffline,
                  style: theme.textTheme.bodyMedium,
                ),
              ),

              // Pendências na Outbox
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  widget.pendingCount > 0
                      ? Icons.outbox
                      : Icons.check_circle_outline,
                  color: widget.pendingCount > 0
                      ? Colors.orange.shade800
                      : Colors.green.shade700,
                ),
                title: Text(
                  '${AppStrings.syncPendingSummary} ${widget.pendingCount}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: widget.pendingCount > 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),

              // Última sincronização
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text(AppStrings.syncLastSuccess),
                subtitle: Text(formattedLastSync),
              ),

              // Erro da última sincronização, se houver
              if (widget.lastError != null && widget.lastError!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withAlpha(90),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.error.withAlpha(120)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.syncErrorNotice,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.lastError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Alerta de conflito, se houver no último resultado
              if (conflicts.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withAlpha(60),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.error),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.syncConflictNoticeTitle,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.syncConflictNoticeDesc,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text(AppStrings.syncConflictDetailsButton),
                        onPressed: () {
                          SyncConflictDialog.show(
                            context,
                            conflicts: conflicts,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Botão de Sincronização Manual
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: _isManualSyncInProgress || widget.isSyncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync),
                  label: Text(
                    _isManualSyncInProgress || widget.isSyncing
                        ? AppStrings.syncStatusSyncing
                        : AppStrings.syncActionNow,
                  ),
                  onPressed:
                      (!widget.isAuthenticated ||
                          !widget.isOnline ||
                          widget.isSyncing ||
                          _isManualSyncInProgress)
                      ? null
                      : _handleManualSync,
                ),
              ),

              if (!widget.isAuthenticated) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Faça login para habilitar a sincronização na nuvem.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ] else if (!widget.isOnline) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Conecte-se à internet para realizar a sincronização.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
