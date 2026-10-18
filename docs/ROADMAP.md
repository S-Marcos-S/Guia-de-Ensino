# ROADMAP — Guia de Ensino

Este documento registra o planejamento incremental, o progresso das fases e os critérios de aceitação de cada etapa do **Guia de Ensino**.

O desenvolvimento segue estritamente as regras permanentes descritas em `GEMINI.md`.

---

## 1. Visão Geral das Etapas

| Etapa | Nome | Status | Dependências |
|---|---|---|---|
| **Etapa 0** | Inspeção, Governança e Planejamento | **Concluída** | Nenhuma |
| **Etapa 0** | Inspeção, Governança e Planejamento | **Concluída** | Nenhuma |
| **Etapa 1** | Fundação do Projeto Multiplataforma | **Em validação** | Etapa 0 |
| **Etapa 2** | Modelos de Domínio e Persistência Local | Planejada | Etapa 1 |
| **Etapa 3** | Cadastro e Configuração Pedagógica | Planejada | Etapa 2 |
| **Etapa 4** | Conteúdos Programáticos e Base Curricular | Planejada | Etapa 3 |
| **Etapa 5** | Motor Determinístico de Planejamento | Planejada | Etapa 4 |
| **Etapa 6** | Acompanhamento e Registro de Aulas | Planejada | Etapa 5 |
| **Etapa 7** | Replanejamento Automático Determinístico | Planejada | Etapa 6 |
| **Etapa 8** | Integração com Inteligência Artificial | Planejada | Etapa 7 |
| **Etapa 9** | Sincronização e Gestão de Contas | Planejada | Etapa 8 |
| **Etapa 10** | Experiência Multiplataforma e Acessibilidade | Planejada | Etapa 9 |
| **Etapa 11** | Estabilização, Testes Finais e Distribuição | Planejada | Etapa 10 |

---

## 2. Detalhamento e Critérios de Aceitação

### Etapa 0 — Inspeção, Governança e Planejamento
- **Status**: **Concluída**
- **Objetivos**:
  - Inspecionar o repositório e o ambiente de desenvolvimento local.
  - Verificar ferramentas instaladas, versões e limitações do ambiente.
  - Consolidar as regras permanentes em `GEMINI.md`.
  - Criar `docs/ROADMAP.md` e `docs/ARCHITECTURE.md`.
  - Documentar decisões arquiteturais iniciais em `docs/adr/`.
  - Documentar modelo de domínio (`docs/DOMAIN_MODEL.md`), replanejamento (`docs/REPLANNING.md`), fontes (`docs/DATA_SOURCES.md`), IA (`docs/AI.md`) e estratégia de testes (`docs/TESTING.md`).
- **Critérios de Aceitação**:
  1. Repositório Git inicializado localmente apontando para o repositório remoto oficial `https://github.com/S-Marcos-S/Guia-de-Ensino`.
  2. Documentação inicial completa, sem arquivos fictícios e sem códigos gerados sem validação.
  3. Relatório claro do estado das ferramentas locais (Flutter, Dart, Node, Git) e limitações identificadas.

---

### Etapa 1 — Fundação do Projeto Multiplataforma
- **Status**: **Em validação** (Implementação e testes concluídos; pendente de aceitação de licenças Android e build nativo)
- **Objetivos**:
  - Estruturar o workspace do aplicativo Flutter em `apps/app`.
  - Configurar regras de análise estática (`analysis_options.yaml`) estritas.
  - Configurar sistema de design/tema com suporte a Material 3, modo claro/escuro e acessibilidade.
  - Implementar estrutura de navegação base adaptável (BottomNavigationBar para mobile, NavigationRail para desktop).
  - Implementar componentes reutilizáveis (botões grandes, cartões, cabeçalhos, estados vazios e badges).
  - Isolar entidades de domínio puras sem dependência de widgets de UI.
  - Implementar e validar testes automatizados de domínio e apresentação.
  - Validar compilação na plataforma disponível.
- **Critérios de Aceitação**:
  1. [x] Projeto compila e analisa sem avisos ou erros de linting (`flutter analyze` com 0 issues).
  2. [x] Tela inicial funcional exibindo os principais pontos de entrada (Turmas, Calendário, Conteúdos, Replanejamento).
  3. [x] Formatação e análise estática executadas com sucesso (`dart format` e `flutter test` com 14 testes passando).
  4. [ ] Aceitação das licenças do Android SDK revisadas pelo usuário.
  5. [ ] Verificação de compilação para Android/Windows conforme ferramentas disponíveis.

---

### Etapa 2 — Modelos de Domínio e Persistência Local
- **Status**: Planejada
- **Objetivos**:
  - Implementar entidades de domínio em Dart puro com imutabilidade e tipagem forte.
  - Configurar banco local SQLite com biblioteca fortemente tipada e suporte a migrações versionadas.
  - Implementar repositórios locais para persistência de anos letivos, turmas, disciplinas e horários.
  - Validar persistência após reinicialização do app.
- **Critérios de Aceitação**:
  1. Modelos 100% desacoplados de bibliotecas de UI.
  2. Migrações de banco versionadas e testadas.
  3. Testes unitários para persistência e recuperação de dados cobrindo casos de sucesso e erro.

---

### Etapa 3 — Cadastro e Configuração Pedagógica
- **Status**: Planejada
- **Objetivos**:
  - Fluxo guiado para criação de ano letivo e calendário escolar (início, término, recessos, feriados).
  - Cadastro de turmas e vínculo com disciplinas.
  - Configuração de horários semanais por turma (quantidade de aulas por dia da semana).
  - Validação de consistência do calendário (dias letivos suficientes, disciplinas sem horários).
- **Critérios de Aceitação**:
  1. Cálculo determinístico da quantidade real de aulas no período letivo (não apenas semanas × aulas).
  2. Bloqueio de cadastros inconsistentes com mensagens claras em português.
  3. Testes unitários de regras de negócio de calendário e carga horária.

---

### Etapa 4 — Conteúdos Programáticos e Base Curricular
- **Status**: Planejada
- **Objetivos**:
  - Cadastro manual e estruturado de conteúdos programáticos e unidades de conhecimento.
  - Configuração de duração estimada (em número de aulas), ordem pedagógica e dependências.
  - Módulo de consulta e importação de referência inicial verificável da BNCC (Ensino Fundamental e Médio).
  - Pipeline extensível para importação de arquivos (PDF, DOCX, planilhas).
- **Critérios de Aceitação**:
  1. Base curricular inicial com fontes e códigos oficiais verificados (sem alucinações).
  2. Suporte a conteúdos que ocupam múltiplas aulas e aulas com múltiplos conteúdos.
  3. Telas de confirmação para dados importados antes de salvamento.

---

### Etapa 5 — Motor Determinístico de Planejamento
- **Status**: Planejada
- **Objetivos**:
  - Motor em Dart puro que gera o cronograma distribuindo conteúdos nos dias letivos disponíveis.
  - Respeito a restrições fixas (avaliações, feriados, ordem pedagógica e dependências).
  - Detecção e apresentação explícita de insuficiência de carga horária.
  - Visualização prévia do cronograma gerado para revisão pelo professor.
- **Critérios de Aceitação**:
  1. Mesmo conjunto de entradas gera rigorosamente a mesma saída (determinismo).
  2. Conteúdos nunca são descartados silenciosamente por falta de capacidade.
  3. Suíte de testes unitários com múltiplos cenários de calendário e carga horária.

---

### Etapa 6 — Acompanhamento e Registro de Aulas
- **Status**: Planejada
- **Objetivos**:
  - Interface diária/semanal para o professor marcar aulas como: realizadas, parcialmente realizadas ou não realizadas.
  - Registro de observações e conteúdos efetivamente ministrados.
  - Visualização de indicadores de progresso (aulas dadas vs. previstas, conteúdos concluídos).
  - Imutabilidade do histórico de aulas registradas.
- **Critérios de Aceitação**:
  1. Registros históricos persistidos com data/hora e nunca apagados por alterações futuras.
  2. Indicadores de progresso atualizados em tempo real.
  3. Testes cobrindo registros com falha, cancelamento e atrasos parciais.

---

### Etapa 7 — Replanejamento Automático Determinístico
- **Status**: Planejada
- **Objetivos**:
  - Fluxo de replanejamento com gatilhos automáticos ou manuais (aula perdida, atraso de conteúdo).
  - Motor determinístico que calcula capacidade restante, preserva histórico e compromissos fixos e propõe reorganização.
  - Interface de comparação de versões ("Antes" vs. "Depois") com justificativas claras.
  - Fluxo de aprovação, edição ou rejeição pelo professor.
  - Controle e restauração de versões anteriores do planejamento.
- **Critérios de Aceitação**:
  1. Aprovação obrigatória do professor antes de gravar a nova versão.
  2. Execução dos 12 cenários de teste obrigatórios descritos na regra de replanejamento.
  3. Preservação total do histórico de aulas já executadas.

---

### Etapa 8 — Integração com Inteligência Artificial
- **Status**: Planejada
- **Objetivos**:
  - Interface de provedor de IA desacoplada (`AiServiceProvider`).
  - Execução de chamadas seguras pelo backend ou serviço isolado com chaves protegidas.
  - Prompts versionados com saída estritamente estruturada em JSON Schema.
  - Validação das saídas pelo motor determinístico antes de exibir ao usuário.
  - Auxílio na interpretação de documentos e sugestão de sequências didáticas.
- **Critérios de Aceitação**:
  1. Nenhuma chave de API no código cliente ou no repositório.
  2. O aplicativo continua 100% funcional caso a IA esteja offline ou indisponível.
  3. Sugestões tratadas como hipóteses sujeitas à validação das regras e aprovação do professor.

---

### Etapa 9 — Sincronização e Gestão de Contas
- **Status**: Planejada
- **Objetivos**:
  - Implementação do backend (NestJS + PostgreSQL) para sincronização multi-dispositivo opcional.
  - Autenticação e autorização seguras com JWT.
  - Modelo de sincronização com identificadores estáveis (UUID) e resolução explícita de conflitos.
  - Funcionamento local-first ininterrupto em caso de queda de conexão.
- **Critérios de Aceitação**:
  1. Dados locais sincronizados sem duplicação ou sobrescrita silenciosa.
  2. Isolamento rígido de dados por usuário e conformidade com LGPD.
  3. Testes de sincronização com alterações conflitantes e reconexão.

---

### Etapa 10 — Experiência Multiplataforma e Acessibilidade
- **Status**: Planejada
- **Objetivos**:
  - Otimização da interface para Desktop (visualização multitelas: turmas, calendário e detalhes simultâneos).
  - Otimização para Mobile (navegação rápida, botões grandes, formulários enxutos).
  - Auditoria de acessibilidade (contraste, navegação por teclado, suporte a leitores de tela).
- **Critérios de Aceitação**:
  1. Layout responsivo com transição suave entre mobile, tablet e desktop.
  2. Padrões de acessibilidade WCAG AA validados.

---

### Etapa 11 — Estabilização, Testes Finais e Distribuição
- **Status**: Planejada
- **Objetivos**:
  - Execução da suíte completa de testes unitários, de integração e de interface.
  - Auditoria de segurança de dependências.
  - Documentação final de instalação, execução e builds para cada plataforma suportada.
  - Checklist de homologação para produção.
- **Critérios de Aceitação**:
  1. 100% dos testes passando sem falhas.
  2. Documentação alinhada fielmente ao comportamento real do código.
