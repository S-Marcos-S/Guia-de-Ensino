# Arquitetura do Sistema — Guia de Ensino

Este documento descreve a arquitetura geral do **Guia de Ensino**, os padrões estruturais adotados, as camadas de responsabilidade e as diretrizes de integração e segurança.

---

## 1. Visão Arquitetural

O Guia de Ensino adota uma **Arquitetura em Camadas Orientada ao Domínio (Clean Architecture / Hexagonal Architecture)** com abordagem **Local-First**.

```text
┌─────────────────────────────────────────────────────────────┐
│                    Apresentação (UI)                        │
│   Flutter Material 3 (Telas Mobile e Desktop Adaptáveis)    │
│   Widgets, State Management, ViewModels / Cubits / Notifiers│
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                  Aplicação / Casos de Uso                   │
│   GerarPlanejamentoUseCase, ReplanejarAulasUseCase, etc.     │
└──────────────┬──────────────────────────────┬───────────────┘
               │                              │
┌──────────────▼──────────────┐┌──────────────▼───────────────┐
│     Domínio / Motor Puro    ││        Portas / Interfaces   │
│  Entidades, Regras, Algorit.││ Repositórios, IA Service,    │
│  Determinístico de Calendário││ Sincronização, Relógio       │
└─────────────────────────────┘└──────────────┬───────────────┘
                                              │
┌─────────────────────────────────────────────▼───────────────┐
│              Infraestrutura / Adaptadores                   │
│   SQLite Local (Drift/Sqflite)   │  HTTP Client (NestJS API)│
│   Adaptador IA (Gemini Client)   │  Importador (PDF/DOCX)   │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Camadas do Sistema

### 2.1 Camada de Domínio (`domain/`)
- **Independência Total**: Não possui dependência de Flutter, de pacotes de interface ou de banco de dados.
- **Entidades e Objetos de Valor**: Modelos fortemente tipados e imutáveis (`Classroom`, `Subject`, `AcademicYear`, `PlannedLesson`, etc.).
- **Motor Determinístico de Calendário**: Algoritmos puros de cálculo de dias letivos, feriados, distribuição de conteúdos e validação de capacidade.
- **Regras Invioláveis**: O domínio garante que uma aula já executada nunca seja apagada, que conteúdos obrigatórios não sejam descartados e que horários sejam consistentes.

### 2.2 Camada de Aplicação (`application/`)
- Orquestra fluxos de negócio através de **Casos de Uso** (Use Cases).
- Exemplos: `CriarAnoLetivo`, `DistribuirConteudos`, `RegistrarAulaExecutada`, `ExecutarReplanejamento`.
- Valida entradas nas fronteiras e expõe resultados por meio de tipos de sucesso/falha (`Result<T, Failure>`).

### 2.3 Camada de Apresentação (`presentation/`)
- Desenvolvida em **Flutter** com Material 3.
- Utiliza layouts adaptáveis (`LayoutBuilder`, breakpoints para mobile, tablet e desktop).
- Gerenciamento de estado previsível e desacoplado, sem lógica de cálculo de calendário inserida dentro de widgets.
- Interface 100% em português brasileiro, com foco em botões grandes, contraste visual, tipografia legível e feedback de carregamento/vazio.

### 2.4 Camada de Infraestrutura (`infrastructure/`)
- **Persistência Local**: Banco SQLite com migrações explícitas versionadas.
- **Sincronização**: Cliente de sincronização HTTP para comunicação com o backend NestJS quando online.
- **Serviço de IA**: Implementação da interface `AiServiceProvider`, intermediando chamadas à API Gemini com proteção de segredos, esquemas JSON validados e tratamento de falhas.

---

## 3. Diretriz Local-First e Estratégia de Sincronização

1. **Prioridade Offline**: A leitura e a escrita do planejamento ocorrem primariamente no banco SQLite local do dispositivo.
2. **Identificadores Estáveis**: Todas as entidades utilizam UUID v4 gerados localmente no momento da criação.
3. **Controle de Versão e Timestamps**: Cada registro possui `created_at`, `updated_at` e um contador de versão incremental (`revision`).
4. **Resolução de Conflitos**:
   - Conflitos de edição são tratados explicitamente com política "campo a campo" ou apresentação de conflito para escolha do professor quando houver divergência relevante de cronograma.
   - Registros de aulas realizadas possuem prioridade e nunca são sobrescritos por planejamentos desatualizados.

---

## 4. Integração com Inteligência Artificial

```text
[Usuário / Documento] 
         │
         ▼
[Interface do Cliente] 
         │ (Dados estritamente pedagógicos, sem dados pessoais de alunos)
         ▼
[Backend Guia de Ensino (NestJS)] ──> [Gerenciador de Segredos (API Key)]
         │
         ▼
[Provedor de IA (Google Gemini API)]
         │
         ▼ (Resposta Estruturada em JSON Schema)
[Validador de Esquema e Filtro de Segurança]
         │
         ▼
[Motor Determinístico (Dart Domain Engine)] ──> Validação de Limites e Capacidade
         │
         ▼
[Proposta Apresentada ao Professor para Revisão e Aprovação]
```

- A IA atua exclusivamente como **consultora/sugestora**.
- Nenhuma resposta da IA é persistida diretamente sem passar pela validação determinística do motor e aprovação humana explícita.
- As credenciais de IA residem exclusivamente no ambiente seguro do backend, nunca no cliente.

---

## 5. Estratégia Multiplataforma

O código de domínio, casos de uso e a quase totalidade da interface são compartilhados:
- **Mobile (Android & iOS)**: Navegação em abas/bottom bar, fluxo de formulários em passos simples, cartões grandes de fácil toque.
- **Desktop (Windows, macOS, Linux)**: Barra lateral (navigation rail), visualização simultânea de painel com calendário, grade de turmas e lista de conteúdos pendentes.
- **Adaptações de Plataforma**: Abstraídas por meio de interfaces (`FilePickerService`, `NotificationService`, `PlatformInfo`).

---

## 6. Segurança e Conformidade (LGPD)

- **Minimização de Dados**: O aplicativo gerencia planejamento pedagógico do professor. Não há necessidade de armazenar dados sensíveis de menores ou prontuários de estudantes.
- **Proteção de Segredos**: Ausência de segredos ou tokens no repositório. Uso de variáveis de ambiente no backend e armazenamento seguro no cliente (`flutter_secure_storage` para tokens de sessão).
- **Sanitização de Documentos**: Arquivos importados (PDF/DOCX) são analisados contra injeção de instruções maliciosas antes do processamento.
