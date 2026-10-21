/// Textos estáticos e centralizados do Guia de Ensino em português brasileiro.
abstract final class AppStrings {
  static const String appName = 'Guia de Ensino';
  static const String appTagline =
      'Planejamento pedagógico determinístico para professores';

  // Navegação Principal
  static const String navHome = 'Início';
  static const String navClassrooms = 'Turmas';
  static const String navCalendar = 'Calendário';
  static const String navContents = 'Conteúdos';
  static const String navReplanning = 'Replanejamento';
  static const String navSettings = 'Configurações';

  // Tela Inicial
  static const String welcomeTitle = 'Olá, Professor(a)!';
  static const String welcomeSubtitle =
      'Acompanhe seu cronograma letivo e organize suas turmas com segurança e facilidade.';
  static const String quickAccessSection = 'Acesso Rápido';
  static const String currentStatusSection = 'Resumo do Planejamento';
  static const String noActivePlanning =
      'Nenhum ano letivo configurado no momento.';
  static const String startSetupButton = 'Iniciar Configuração Pedagógica';

  // Cartões da Tela Inicial
  static const String cardClassroomsTitle = 'Minhas Turmas';
  static const String cardClassroomsDesc =
      'Gerencie turmas, disciplinas e carga horária semanal.';
  static const String cardCalendarTitle = 'Calendário Escolar';
  static const String cardCalendarDesc =
      'Consulte dias letivos, feriados, recessos e eventos escolares.';
  static const String cardContentsTitle = 'Conteúdos Programáticos';
  static const String cardContentsDesc =
      'Organize unidades didáticas e consulte referências da BNCC.';
  static const String cardReplanningTitle = 'Replanejamento Automático';
  static const String cardReplanningDesc =
      'Reorganize aulas futuras após faltas ou conteúdos incompletos.';

  // Estados Vazios (Empty States)
  static const String emptyClassroomsTitle = 'Nenhuma turma cadastrada';
  static const String emptyClassroomsDesc =
      'O cadastro de turmas e disciplinas será disponibilizado nas próximas etapas de implementação.';
  static const String emptyCalendarTitle = 'Calendário escolar não configurado';
  static const String emptyCalendarDesc =
      'Cadastre o período letivo e os feriados para habilitar o cálculo automático de aulas.';
  static const String emptyContentsTitle = 'Nenhum conteúdo adicionado';
  static const String emptyContentsDesc =
      'Importe tópicos da BNCC ou crie sua grade de conteúdos personalizada.';
  static const String emptyReplanningTitle = 'Sem replanejamentos pendentes';
  static const String emptyReplanningDesc =
      'O motor de replanejamento automático é acionado quando ocorrem atrasos ou alterações no calendário.';

  // Acompanhamento e Consulta de Aulas
  static const String cardLessonsTitle = 'Acompanhamento de Aulas';
  static const String cardLessonsDesc =
      'Consulte o cronograma letivo e a situação dos registros do diário de classe.';
  static const String lessonsScreenTitle = 'Acompanhamento de Aulas';
  static const String lessonsScreenSubtitle =
      'Consulta cronológica de aulas planejadas e registros de execução pedagógica.';
  static const String classroomSelectorLabel = 'Turma';
  static const String subjectSelectorLabel = 'Disciplina';
  static const String filterAll = 'Todas';
  static const String filterPast = 'Passadas';
  static const String filterToday = 'Hoje';
  static const String filterFuture = 'Futuras';
  static const String plannedContentsSectionLabel = 'Conteúdos planejados:';
  static const String actualContentsSectionLabel = 'Conteúdos ministrados:';
  static const String noPlannedContents =
      'Nenhum conteúdo planejado associado.';
  static const String noActualContents = 'Nenhum conteúdo fático registrado.';
  static const String statusPlanned = 'Prevista';
  static const String statusCompleted = 'Realizada';
  static const String statusPartiallyCompleted = 'Parcial';
  static const String statusNotHeld = 'Não Realizada';
  static const String badgeToday = 'Hoje';
  static const String badgePastUnrecorded = 'Pendente de apontamento';
  static const String cancellationReasonPrefix = 'Motivo: ';
  static const String cancellationDetailsPrefix = 'Detalhes: ';
  static const String pedagogicalNotesPrefix = 'Observações pedagógicas: ';
  static const String followUpPrefix = 'Continuidade pedagógica: ';
  static const String plannedNotesPrefix = 'Notas do planejamento: ';
  static const String emptyLessonsTitle = 'Nenhuma aula encontrada';
  static const String emptyLessonsDesc =
      'Não há aulas registradas para o filtro selecionado.';
  static const String selectClassroomAndSubjectPrompt =
      'Selecione uma turma e uma disciplina para visualizar as aulas.';
  static const String loadingLessonsError =
      'Erro ao carregar aulas do planejamento.';
  static const String retryButton = 'Tentar novamente';

  // Apontamento e Diário de Aula (Etapa 6.4.2)
  static const String recordLessonAction = 'Apontar Aula';
  static const String rectifyLessonAction = 'Retificar Apontamento';
  static const String recordLessonDialogTitle = 'Apontamento de Aula';
  static const String rectifyLessonDialogTitle = 'Retificar Apontamento';
  static const String lessonStatusSectionLabel = 'Situação da Aula';
  static const String statusCompletedOption = 'Realizada';
  static const String statusPartiallyCompletedOption = 'Parcial';
  static const String statusNotHeldOption = 'Não Realizada';
  static const String contentsTaughtSectionLabel = 'Conteúdos ministrados';
  static const String selectPlannedContentsQuickAction = 'Marcar planejados';
  static const String clearSelectedContentsQuickAction = 'Limpar seleção';
  static const String plannedContentBadge = '(Planejado)';
  static const String noContentsForClassroomSubject =
      'Nenhum conteúdo curricular cadastrado para esta disciplina.';
  static const String loadingContentsError =
      'Erro ao carregar conteúdos curriculares da disciplina.';
  static const String notHeldNoContentsNotice =
      'Aulas não realizadas não possuem conteúdos ministrados.';
  static const String cancellationReasonLabel = 'Motivo do cancelamento';
  static const String selectCancellationReasonHint = 'Selecione o motivo';
  static const String cancellationDetailsLabel =
      'Detalhes do cancelamento (opcional)';
  static const String cancellationDetailsHint =
      'Informe detalhes adicionais sobre o cancelamento, se necessário';
  static const String pedagogicalNotesLabel =
      'Observações pedagógicas (opcional)';
  static const String pedagogicalNotesHint =
      'Descreva ocorrências pedagógicas, ritmo de aprendizagem ou observações';
  static const String needsFollowUpLabel =
      'Requer continuidade pedagógica na próxima aula';
  static const String followUpNotesLabel =
      'Orientações para continuidade (opcional)';
  static const String followUpNotesHint =
      'Descreva o ponto de retomada ou atividade complementar necessária';
  static const String saveRecordButton = 'Salvar Apontamento';
  static const String cancelButton = 'Cancelar';
  static const String savingRecordIndicator = 'Salvando apontamento...';
  static const String lessonRecordedSuccess =
      'Apontamento de aula salvo com sucesso!';
  static const String lessonRectifiedSuccess =
      'Apontamento de aula retificado com sucesso!';
  static const String validationNotHeldReasonRequired =
      'Aulas não realizadas exigem a indicação de um motivo de cancelamento.';
  static const String validationNotHeldContentsForbidden =
      'Aulas não realizadas não podem conter conteúdos ministrados.';
  static const String validationPartialLessonRequired =
      'Aulas parciais devem conter ao menos um conteúdo ministrado, observações pedagógicas ou indicação de continuidade.';

  // Botões e Ações Globais
  static const String backButton = 'Voltar';
  static const String closeButton = 'Fechar';
  static const String understandButton = 'Entendido';
  static const String actionNotImplemented =
      'Funcionalidade em desenvolvimento nas próximas etapas do projeto.';

  // Autenticação e Sessão (Etapa 9.5)
  static const String authScreenTitleLogin = 'Entrar na Conta';
  static const String authScreenTitleRegister = 'Criar Nova Conta';
  static const String authTabLogin = 'Entrar';
  static const String authTabRegister = 'Cadastrar';
  static const String authEmailLabel = 'E-mail institucional ou pessoal';
  static const String authEmailHint = 'exemplo@escola.edu.br';
  static const String authPasswordLabel = 'Senha de acesso';
  static const String authPasswordHint = 'Mínimo de 8 caracteres';
  static const String authConfirmPasswordLabel = 'Confirmação de senha';
  static const String authConfirmPasswordHint = 'Repita sua senha';
  static const String authLoginButton = 'Entrar no Guia de Ensino';
  static const String authRegisterButton = 'Concluir Cadastro';
  static const String authGuestButton = 'Continuar como Convidado';
  static const String authGuestSubtitle =
      'Utilize o aplicativo no modo offline sem sincronização na nuvem.';
  static const String authSwitchToRegister = 'Não tem conta? Cadastre-se aqui';
  static const String authSwitchToLogin = 'Já possui conta? Faça login';
  static const String authLoadingLogin = 'Autenticando credenciais...';
  static const String authLoadingRegister = 'Criando conta pedagógica...';
  static const String authValidationEmailRequired =
      'Informe seu endereço de e-mail.';
  static const String authValidationEmailInvalid =
      'Informe um formato de e-mail válido (ex.: professor@escola.edu.br).';
  static const String authValidationPasswordRequired = 'Informe sua senha.';
  static const String authValidationPasswordMinLength =
      'A senha deve conter pelo menos 8 caracteres.';
  static const String authValidationPasswordsDoNotMatch =
      'A confirmação de senha não confere com a senha digitada.';
  static const String authSuccessLogin = 'Login realizado com sucesso!';
  static const String authSuccessRegister = 'Conta criada com sucesso!';
  static const String authLogoutConfirmTitle = 'Sair da Conta';
  static const String authLogoutConfirmMessage =
      'Deseja realmente encerrar a sessão? Seus dados pedagógicos locais e registros não enviados serão preservados com segurança neste dispositivo.';
  static const String authLogoutButton = 'Sair da Conta';
  static const String authAccountMenuTitle = 'Conta Docente';
  static const String authLoggedAs = 'Conectado como:';
  static const String authGuestMode = 'Modo Local (Convidado)';
  static const String authSignInPrompt =
      'Entre com sua conta para sincronizar o planejamento em múltiplos dispositivos.';

  // Sincronização em Nuvem e Feedback (Etapa 9.5)
  static const String syncStatusSynced = 'Sincronizado';
  static const String syncStatusSyncing = 'Sincronizando...';
  static const String syncStatusOffline = 'Offline';
  static const String syncStatusPendingSingular = '1 alteração pendente';
  static const String syncStatusPendingPlural = 'alterações pendentes';
  static const String syncStatusError = 'Erro de sincronização';
  static const String syncActionNow = 'Sincronizar agora';
  static const String syncActionManualTitle = 'Sincronização em Nuvem';
  static const String syncDetailsTitle = 'Status da Sincronização';
  static const String syncDetailsSubtitle =
      'Acompanhamento do envio e recebimento de dados do planejamento.';
  static const String syncLastSuccess = 'Última sincronização bem-sucedida:';
  static const String syncNever = 'Nenhuma sincronização realizada ainda.';
  static const String syncConnectivityOnline = 'Conexão com a rede ativa';
  static const String syncConnectivityOffline =
      'Sem conexão com a internet. O aplicativo continua funcionando normalmente em modo local.';
  static const String syncPendingSummary =
      'Alterações locais aguardando envio para o servidor:';
  static const String syncErrorNotice = 'Detalhes da última falha:';
  static const String syncConflictNoticeTitle =
      'Conflitos detectados na sincronização';
  static const String syncConflictNoticeDesc =
      'Foram identificadas alterações simultâneas no servidor. Nenhuma alteração local foi sobrescrita automaticamente.';
  static const String syncConflictDetailsButton = 'Ver detalhes do conflito';
  static const String syncConflictDialogTitle = 'Conflito de Sincronização';
  static const String syncConflictReasonLabel = 'Motivo identificado:';
  static const String syncConflictServerVersionLabel = 'Versão no servidor:';
  static const String syncConflictClientVersionLabel = 'Versão local:';
  static const String syncConflictPreservationNotice =
      'Seus dados locais permanecem intactos. As operações conflitantes foram retidas para revisão.';
}
