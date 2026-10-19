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

  // Botões e Ações Globais
  static const String backButton = 'Voltar';
  static const String closeButton = 'Fechar';
  static const String understandButton = 'Entendido';
  static const String actionNotImplemented =
      'Funcionalidade em desenvolvimento nas próximas etapas do projeto.';
}
