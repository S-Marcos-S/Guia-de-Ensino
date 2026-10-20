# ROADMAP — Guia de Ensino

Este documento registra o planejamento incremental, o progresso das fases e os critérios de aceitação de cada etapa do **Guia de Ensino**.

O desenvolvimento segue estritamente as regras permanentes descritas em `GEMINI.md`.

---

## 1. Visão Geral das Etapas

| Etapa | Nome | Status | Dependências |
|---|---|---|---|
| **Etapa 0** | Inspeção, Governança e Planejamento | **Concluída** | Nenhuma |
| **Etapa 1** | Fundação do Projeto Multiplataforma | **Concluída** | Etapa 0 |
| **Etapa 2** | Modelos de Domínio e Persistência Local | **Concluída** | Etapa 1 |
| **Etapa 3** | Cadastro e Configuração Pedagógica | **Concluída** | Etapa 2 |
| **Etapa 3.1** | Automação de Git, CI/CD e Releases | **Concluída** | Etapa 3 |
| **Etapa 4** | Conteúdos Programáticos e Base Curricular | **Concluída** | Etapa 3.1 |
| **Etapa 5** | Motor Determinístico de Planejamento | **Concluída** | Etapa 4 |
| **Etapa 6** | Acompanhamento e Registro de Aulas | **Concluída** | Etapa 5 |
| **Etapa 7** | Replanejamento Automático Determinístico e Viabilidade Curricular | **Concluída** | Etapa 6 |
| **Etapa 8** | Integração com Inteligência Artificial | Planejada | Etapa 7 |
| **Etapa 9** | Sincronização e Gestão de Contas | Em Andamento (9.1 pronta) | Etapa 8 |
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
- **Status**: **Concluída**
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
  4. [x] Aceitação da licença `android-sdk-license` revisada e aprovada pelo usuário.
  5. [x] Verificação de ferramentas de compilação (Android SDK funcional; toolchain C++ Windows mantida suspensa sob orientação).

---

### Etapa 2 — Modelos de Domínio e Persistência Local
- **Status**: **Concluída**
- **Objetivos**:
  - Implementar entidades de domínio em Dart puro com imutabilidade e tipagem forte.
  - Configurar banco local SQLite com biblioteca fortemente tipada (Drift) e suporte a migrações versionadas.
  - Ativar e validar explicitamente a integridade referencial do SQLite (`PRAGMA foreign_keys = ON;`).
  - Estabelecer convenção canônica para datas letivas (`YYYY-MM-DD`) evitando deslocamentos por fuso horário.
  - Implementar repositórios locais para persistência de anos letivos, turmas, disciplinas e horários com chaves primárias UUID e índices.
  - Proteger histórico de aulas executadas contra exclusão acidental (`LessonExecutionProtectedException`).
  - Validar persistência após reinicialização e reabertura do arquivo no disco.
- **Critérios de Aceitação**:
  1. [x] Modelos 100% desacoplados de bibliotecas de UI e Drift isolado na camada de infraestrutura.
  2. [x] Esquema e migrações de banco versionadas (`schemaVersion: 1`).
  3. [x] Integridade referencial do SQLite garantida e verificada via testes automatizados.
  4. [x] Testes de persistência em disco validando sobrevivência dos dados após fechamento e reabertura da conexão.
  5. [x] Repositórios concretos com proteção de histórico de aulas e testes cobrindo casos de sucesso e bloqueio (23 testes passando no total).

---

### Etapa 3 — Cadastro e Configuração Pedagógica
- **Status**: **Concluída**
- **Objetivos**:
  - Fluxo guiado para criação de ano letivo e calendário escolar (início, término, recessos, feriados).
  - Cadastro de turmas e vínculo com disciplinas com cargas horárias individualizadas.
  - Configuração de grade semanal por turma e disciplina (`ScheduleSlot`).
  - Validação determinística de consistência do calendário e cálculo exato de dias letivos e aulas previstas.
  - Migração versionada do banco SQLite de `schemaVersion: 1` para `schemaVersion: 2` com novas tabelas (`school_calendar_events_table` e `schedule_slots_table`) sem perda de dados.
- **Critérios de Aceitação**:
  1. [x] Cálculo determinístico da quantidade real de aulas no período letivo com base na grade semanal e dias letivos efetivos (`CalendarCalculationService`).
  2. [x] Desconto de feriados e recessos (inclusive múltiplos eventos sobrepostos/coincidentes sem dupla dedução).
  3. [x] Bloqueio e validação de cadastros inconsistentes com feedback acessível em português brasileiro.
  4. [x] Diálogos de confirmação (`AppConfirmDialog`) para operações destrutivas de exclusão.
  5. [x] Migração versionada do SQLite testada preservando dados pré-existentes.
  6. [x] Persistência em disco validada após fechar e reabrir o banco.
  7. [x] Testes automatizados unitários de domínio, infraestrutura e interface (41 testes passando com 0 avisos em `flutter analyze`).

---

### Etapa 3.1 — Automação de Git, CI/CD e Releases
- **Status**: **Concluída**
- **Objetivos**:
  - Formalizar a política de Git com Conventional Commits e validações pré-commit no `GEMINI.md` e em `docs/CI_CD.md`.
  - Criar workflow de Integração Contínua (`.github/workflows/ci.yml`) para pull requests e pushes na branch `main`.
  - Criar workflow de Releases (`.github/workflows/release.yml`) acionado por tags `v*`.
  - Definir arquitetura de compilação de artefatos Android (APK e AAB).
  - Tratar de forma transparente e segura o estado da assinatura de release (limitação de keystore documentada, geração de builds de teste no CI sem vazar segredos).
- **Critérios de Aceitação**:
  1. [x] Regras de Git formalizadas na Seção 16 do `GEMINI.md` e detalhadas em `docs/CI_CD.md`.
  2. [x] Workflow de CI implementado com permissões mínimas (`contents: read`), cache e validação estrita (`dart format`, `flutter analyze`, `flutter test`, `flutter build apk --release`).
  3. [x] Workflow de Release implementado para tags `v*` com validação de formato de versão, geração de APK/AAB e publicação de release com changelog.
  4. [x] Limitação de assinatura documentada com guia para inclusão segura de segredos via GitHub Secrets.
  5. [x] Formatação, análise e testes executados localmente com 100% de aprovação.

---

### Etapa 4 — Conteúdos Programáticos e Base Curricular
- **Status**: **Concluída**
- **Objetivos**:
  - Cadastro manual e estruturado de conteúdos programáticos e unidades de conhecimento.
  - Configuração de duração estimada (em número de aulas), ordem pedagógica e dependências/pré-requisitos.
  - Módulo de consulta e importação de referência oficial verificável da BNCC (Ensino Fundamental e Médio, Resoluções CNE/CP 2/2017 e 4/2018).
  - Detecção e prevenção determinística de dependências circulares entre conteúdos (`CurriculumIntegrityService`).
  - Persistência e integridade referencial com migração segura do SQLite para o Schema v3 via Drift.
  - Interface responsiva Material 3 para gerenciamento, busca, reordenação e filtragem de conteúdos (`ContentsScreen`).
- **Critérios de Aceitação**:
  1. [x] Base curricular oficial verificada da BNCC (MEC) empacotada em asset JSON idempotente e sem códigos inventados.
  2. [x] Criação de conteúdos 100% personalizados ou associados opcionalmente à BNCC.
  3. [x] Grafo de pré-requisitos com validação determinística e detecção de ciclos diretos e transitivos (`CircularDependencyException`).
  4. [x] Migração de banco SQLite v2 para v3 mantendo dados existentes sem corrupção.
  5. [x] 56 testes automatizados executados e 100% aprovados (domínio, integridade, migração e apresentação).

---

### Etapa 5 — Motor Determinístico de Planejamento
- **Status**: **Concluída**
- **Objetivos**:
  - Motor em Dart puro que gera o cronograma distribuindo conteúdos nos dias letivos disponíveis (`PlanningEngineService`).
  - Respeito a restrições fixas (avaliações, feriados, recessos, ordem pedagógica e dependências).
  - Detecção e apresentação explícita de insuficiência de carga horária sem descarte silencioso (`lessonDeficit`).
  - Visualização prévia do cronograma gerado para revisão e homologação pelo professor (`PlanningPreviewDialog`).
  - Migração segura do banco SQLite para o Schema v4 com tabela associativa `LessonContentAllocationsTable` preservando integridade referencial.
- **Critérios de Aceitação**:
  1. [x] Mesmo conjunto de entradas gera rigorosamente a mesma saída (determinismo estrito comprovado por testes automatizados).
  2. [x] Conteúdos nunca são descartados silenciosamente por falta de capacidade (déficit de aulas e conteúdos afetados explicitados).
  3. [x] Preservação integral de aulas com registros históricos (`hasExecutionRecord`) e aulas bloqueadas (`isLocked`).
  4. [x] Migração de banco SQLite v3 para v4 com chave estrangeira e cascade em `PlannedLesson` e restrict em `CourseContent`.
  5. [x] Visualização prévia interativa e explicável (`PlanningPreviewDialog`) integrada às telas de `ContentsScreen` e `ReplanningScreen`.
  6. [x] Suíte completa de 76 testes automatizados executada e 100% aprovada (domínio, casos de uso, migração, integridade e apresentação).

---

### Etapa 6 — Acompanhamento e Registro de Aulas
- **Status**: **Concluída**
- **Incrementos**:
  - **6.1 — Modelo de Domínio e Contratos**: **Concluído**
    - Entidade `LessonExecutionRecord` com validação de status, regras estritas de cancelamento e integridade de conteúdos ministrados.
    - Enum `LessonCancellationReason` com categorias semânticas e rótulos/descrições em português.
    - Value Object `ClassroomSubjectProgress` com métricas determinísticas e invariantes de contagem de aulas.
    - Contrato `LessonExecutionRepository` puro de domínio sem operações de exclusão física arbitrária.
    - 24 testes unitários de domínio implementados e 100% aprovados (totalizando 100 testes na suíte).
  - **6.2 — Persistência Drift e Migração v5**: **Concluído**
    - Tabelas `LessonExecutionRecordsTable` e `ExecutionContentAllocationsTable` criadas com chaves estrangeiras protetivas (`KeyAction.restrict`) e unicidade de 1 registro por aula planejada.
    - Elevação do `schemaVersion` para 5 com estratégia de migração incremental de v1, v2, v3 e v4 para v5.
    - Implementação de `DriftLessonExecutionRepository` com validação transacional e atômica de correspondência de vínculos (aula planejada, disciplina da turma e conteúdos).
    - 9 testes automatizados de migração, integridade referencial, unicidade e persistência aprovados (totalizando 109 testes na suíte geral).
  - **6.3 — Casos de Uso e Cálculo de Progresso**: **Concluído**
    - `RecordLessonExecutionUseCase`: Apontamento fático e retificação pedagógica com preservação estrita de `recordedAt`, atualização controlada de `updatedAt` e proteção das notas originais de planejamento.
    - `GetClassroomSubjectProgressUseCase`: Cálculo determinístico de indicadores com classificação mutuamente exclusiva e exaustiva de aulas, taxas percentuais documentadas e regra de conclusão de conteúdo por duração estimada.
  - **6.4 — Interface de Acompanhamento e Diário de Aula**: **Concluído**
    - **6.4.1 — Consulta Cronológica de Aulas**: **Concluído**
      - `GetClassroomSubjectLessonsUseCase`: Agregação determinística com ordenação estrita em 3 níveis (data letiva, `orderInDay`, `id`), categorização temporal civil sem distorções de fuso e separação entre conteúdos planejados e ministrados.
      - `LessonsScreen`: Tela de acompanhamento com proteção assíncrona contra resultados obsoletos (`_activeLoadRequestId`), filtros temporais (Todas, Passadas, Hoje, Futuras), badges de status e destaque para pendências de apontamento.
      - Acessos contextuais integrados na `HomeScreen` (cartão de acesso rápido) e na `ClassroomsScreen` (botão de aulas no cartão da turma e no diálogo de disciplinas).
      - Testes automatizados unitários de domínio e de apresentação (9 novos testes cobrindo ordenação, fronteiras temporais, separação de conteúdos, concorrência assíncrona e fluxo de interface).
    - **6.4.2 — Apontamento e Diário de Aula (Gravação e Edição)**: **Concluído**
      - `RecordLessonDialog`: Diálogo modal para diário de classe com seleção de status (`completed`, `partiallyCompleted`, `notHeld`), sugestão editável de conteúdos planejados, seleção de outros conteúdos da turma/disciplina, ações rápidas de marcação, justificativa de cancelamento padronizada com detalhes opcionais, anotações pedagógicas e sinalização de continuidade pedagógica.
      - Ações contextuais integradas na `LessonsScreen` ("Apontar Aula" e "Retificar Apontamento") com recarregamento reativo, feedback visual (`SnackBar`) e preservação do filtro temporal ativo.
      - Preservação estrita de integridade histórica e retificação pedagógica com garantia de monotonicidade temporal (`effectiveUpdatedAt >= recordedAt`).
      - Testes automatizados abrangentes cobrindo invariantes de status, falha de persistência, prevenção de duplo envio, persistência Drift real e atualização de indicadores de progresso.
- **Critérios de Aceitação Gerais**:
  1. [x] Modelo de domínio puro separando a aula planejada (`PlannedLesson`) do fato registrado (`LessonExecutionRecord`).
  2. [x] Registros históricos persistidos com data/hora e nunca apagados por alterações futuras (Schema v5 com `KeyAction.restrict`).
  3. [x] Indicadores de progresso atualizados em tempo real por turma e disciplina (`GetClassroomSubjectProgressUseCase`).
  4. [x] Visualização cronológica de aulas planejadas e executadas com identificação de pendências (`LessonsScreen`).
  5. [x] Testes cobrindo registros com falha, cancelamento, aula parcial e continuidade pedagógica.

---

### Etapa 7 — Replanejamento Automático Determinístico e Viabilidade Curricular
- **Status**: **Concluída**
- **Incrementos**:
  - **7.1 — Modelos de Domínio e Contratos**: **Concluído**
    - Value Objects e Modelos: `ReplanningProposal`, `LessonReplanningShift`, `LessonReplanningShiftType`, `ScheduleDelayDetectionResult`, `CurricularCapacityAnalysis`, `CurricularViabilityStatus`, `ContentViabilityRisk`, `TeachingPaceAnalysis`, `RecoveryScenario`, `RecoveryScenarioType`.
    - Critérios determinísticos de viabilidade: vagas livres calculadas sobre a grade horária semanal, demanda curricular restante descontando conteúdos concluídos e pendências, margem de segurança de vagas e projeção de transbordo do término do ano letivo.
    - Análise de ritmo real de ensino docente baseada no histórico de aulas ministradas versus estimativas pedagógicas originais.
    - 4 cenários comparáveis de recuperação curricular (Cenário A — Planejamento Vigente, Cenário B — Capacidade Adicional, Cenário C — Priorização de Obrigatórios, Cenário D — Revisão das Estimativas Pedagógicas).
  - **7.2 — Motor Determinístico e Projeção de Viabilidade**: **Concluído**
    - `ReplanningEngineService`: Implementação pura e determinística com preservação sagrada de registros históricos factuais (`completed`, `partiallyCompleted`, `notHeld`) e compromissos fixos (`isLocked`).
    - Detecção antecipada de divergências fáticas, atrasos e déficits de carga horária (`detectDelay`).
    - Análise de capacidade curricular e ritmo de ensino (`analyzeCurricularCapacity` e `analyzeTeachingPace`).
    - Geração determinística de proposta de replanejamento (`generateProposal`) e cenários comparáveis de recuperação (`generateRecoveryScenarios`).
    - Prevenção de dupla contagem de demanda curricular e respeito irrestrito a pré-requisitos pedagógicos.
  - **7.3 — Casos de Uso e Aplicação Transacional**: **Concluído**
    - `DetectScheduleDelayUseCase`: Identificação automática e manual de atrasos, cancelamentos e déficits de capacidade.
    - `GenerateReplanningProposalUseCase`: Orquestração da proposta de replanejamento com análise de viabilidade e cenários.
    - `ApplyReplanningProposalUseCase`: Aplicação transacional, atômica e segura no banco de dados SQLite Drift, garantindo que o plano só é gravado após aprovação explícita do professor.
  - **7.4 — Interface de Usuário e Diálogo Comparativo ("Antes" vs. "Depois")**: **Concluído**
    - `ReplanningScreen`: Visão geral das turmas e disciplinas com alertas em tempo real de viabilidade (Viável, Viável com Ajustes, Risco Crítico), métricas de progresso e botões de replanejamento.
    - `ReplanningPreviewDialog`: Modal de visualização prévia adaptável com resumo de viabilidade curricular, métricas de capacidade e ritmo, seletor de cenários de recuperação, explicações pedagógicas estruturadas e comparativo detalhado de aulas ("Antes" vs. "Depois") com rolagem fluida e botões de ação explícita ("Rejeitar e Descartar" vs. "Homologar e Aplicar").
    - Acesso contextual na `LessonsScreen` com badge e botão de atalho para replanejamento quando atraso for detectado.
- **Critérios de Aceitação Gerais**:
  1. [x] Aprovação obrigatória do professor antes de gravar a nova versão (nenhuma alteração é persistida antes da homologação explícita).
  2. [x] Execução de todos os cenários de teste obrigatórios (15 cenários de replanejamento + 18 testes de viabilidade curricular + 5 testes de casos de uso + 4 testes de interface).
  3. [x] Preservação total do histórico factual de aulas já executadas (`completed`, `partiallyCompleted`, `notHeld`) e de aulas bloqueadas (`isLocked`).
  4. [x] Prevenção de dupla contagem de demanda curricular e de conteúdos de continuidade.
  5. [x] Suíte completa de 194 testes automatizados 100% aprovada no CI sem nenhuma advertência ou falha.

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
- **Status**: **Em Andamento**
- **Subetapas**:
  - **9.1 — Schema Local v6 (Colunas updatedAt e Tabelas de Sincronização)**: **Concluído**
    - [x] Adição da coluna `updatedAt` anulável nas 8 tabelas de entidades (`AcademicYearsTable`, `ClassroomsTable`, `SubjectsTable`, `ClassroomSubjectsTable`, `PlannedLessonsTable`, `SchoolCalendarEventsTable`, `ScheduleSlotsTable`, `CourseContentsTable`).
    - [x] Criação de `SyncStateTable`, `SyncTombstonesTable` e `SyncOutboxTable` com constraints de unicidade e integridade no Drift.
    - [x] Implementação da migração incremental v5 $\to$ v6 em `AppDatabase.onUpgrade`, preservando dados legados e adicionando índices para outbox e tombstones.
    - [x] Criação da suíte de testes de migração `database_migration_v6_test.dart` (validação de schema limpo, preservação de dados legados v5, migrações encadeadas v1-v6, constraints de unicidade e integridade referencial com foreign keys).
  - **9.2 — Backend NestJS e Persistência PostgreSQL**: **Concluído**
    - Backend modular em `server/` com TypeScript estrito, NestJS 10 e TypeORM (`synchronize: false` obrigatório em todos os ambientes).
    - Persistência PostgreSQL estruturada com migrações versionadas (`1710000001000-CreateUsersAndSyncTables.ts` e `1710000002000-CreatePedagogicalEntities.ts`).
    - Isolamento multi-tenant físico em nível de banco garantido por chaves estrangeiras compostas contendo `user_id` em todas as relações entre entidades pedagógicas.
    - Controle de concorrência com advisory lock transacional (`pg_advisory_xact_lock`) e `SELECT ... FOR UPDATE` sobre `user_sync_version`.
    - Garantia de monotonia estrita de sequência (`current_seq`), precisão nativa de 64 bits (`BIGINT` com `bigintTransformer`) e verificação idempotente de mutações (`client_op_id` + hash SHA-256 do payload).
    - Autenticação JWT com HS256, hash de senha via bcrypt com fator de custo 12, validação de variáveis de ambiente com `class-validator` e sanitização de erros HTTP contra vazamento de detalhes internos do banco.
    - Testes unitários (AuthService, SyncStorageService, transformers) e testes de integração com PostgreSQL 16 no GitHub Actions CI.
  - **9.3 — Protocolo de Sincronização e Endpoints**: **Concluído**
    - Endpoints `/api/sync/push` (recebimento em lote de 1 a 100 operações, atomicidade estrita, idempotência por hash de payload, ACKs `APPLIED`, `SKIPPED`, `CONFLICT`), `/api/sync/pull` (cursor composto determinístico `(server_seq, id)`, detecção de época e descarte de eco) e `/api/sync/snapshot` (snapshot consistente das 13 coleções sob `REPEATABLE READ` com token HMAC-SHA256 derivado via HKDF).
    - Proteção explícita de registros históricos fáticos de aula (`lesson_execution_records`) e regras de integridade curricular.
    - Suíte de 28 testes de integração contra PostgreSQL 16 real e 36 testes unitários aprovados no CI.
  - **9.4 — Integração Flutter/Drift com o Protocolo de Sincronização**: **Em Andamento**
    - Preparação segura da branch de trabalho `feature/etapa-9-cliente-sync` e unificação com Drift Schema v6.
    - Orquestrador de sincronização local-first, processamento de outbox, reconciliação de tombstones, paginação de deltas e staging atômico de snapshot.
- **Critérios de Aceitação Gerais**:
  1. [x] Schema local v6 validado com integridade e sem perda de dados legados.
  2. [x] Backend NestJS estruturado com TypeScript estrito, TypeORM e migrações versionadas.
  3. [x] Isolamento multi-tenant estrito via chaves estrangeiras compostas com `user_id`.
  4. [x] Concorrência e integridade serializadas via advisory lock e `SELECT ... FOR UPDATE`.
  5. [x] Preservação de 64 bits em `BIGINT` e rejeição a conflitos de idempotência.
  6. [x] Testes unitários do backend aprovados e integração com PostgreSQL real configurada no CI (28 testes de integração + 36 testes unitários).
  7. Dados locais sincronizados sem duplicação ou sobrescrita silenciosa.
  8. Funcionamento local-first ininterrupto em caso de queda de rede ou offline prolongado.

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
