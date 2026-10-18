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

  // Botões e Ações Globais
  static const String backButton = 'Voltar';
  static const String closeButton = 'Fechar';
  static const String understandButton = 'Entendido';
  static const String actionNotImplemented =
      'Funcionalidade em desenvolvimento nas próximas etapas do projeto.';
}
