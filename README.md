# Guia de Ensino

O **Guia de Ensino** é um aplicativo multiplataforma de planejamento pedagógico voltado para professores do Ensino Fundamental e do Ensino Médio das redes pública e privada brasileiras.

O objetivo do sistema é auxiliar o professor a organizar o planejamento anual de suas turmas, transformar conteúdos programáticos e habilidades curriculares em uma trilha de aulas distribuída no calendário letivo real, acompanhar a execução diária e realizar replanejamentos automáticos e auditáveis quando ocorrerem imprevistos (faltas, recessos, atrasos ou conteúdos que demandarem mais tempo).

---

## 1. Princípios Fundamentais

1. **Determinismo**: Os cálculos de datas, horários, capacidade do calendário e alocação de aulas são matematicamente determinísticos. A inteligência artificial não faz aritmética crítica nem altera cronogramas diretamente.
2. **Local-First (Offline por padrão)**: Todas as operações essenciais do professor (consultar turmas, visualizar planejamentos, registrar aulas realizadas e verificar pendências) funcionam sem conexão à internet com SQLite local.
3. **Preservação Histórica**: Aulas já realizadas e seus registros de execução nunca são apagados ou alterados durante replanejamentos automáticos.
4. **IA como Assistente Pedagógica**: A IA atua na interpretação de documentos, sugestão de sequências didáticas e propostas de reorganização, sempre intermediada por esquemas tipados, validação do motor do sistema e aprovação final do professor.
5. **Privacidade e LGPD**: Minimização de dados de alunos, proteção rigorosa de credenciais e isolamento multiusuário.

---

## 2. Visão Geral da Arquitetura

- **Frontend Multiplataforma**: Flutter & Dart (suporte a Android, iOS, Windows, Linux, macOS e Web).
- **Domínio e Motor Pedagógico**: Dart puro, isolado de bibliotecas de interface gráfica e de persistência.
- **Armazenamento Local**: SQLite via driver nativo e biblioteca fortemente tipada com suporte a migrações versionadas.
- **Sincronização & Backend**: API RESTful em TypeScript com NestJS e banco de dados PostgreSQL (fase de sincronização multi-dispositivo).
- **Integração de IA**: Interface desacoplada de provedor (`AiServiceProvider`), com suporte inicial à Google Gemini API no backend com validação de esquema JSON.

Consulte os detalhes na pasta de documentação:
- [Arquitetura do Sistema](docs/ARCHITECTURE.md)
- [Roadmap de Implementação](docs/ROADMAP.md)
- [Modelo de Domínio](docs/DOMAIN_MODEL.md)
- [Regras do Replanejamento](docs/REPLANNING.md)
- [Fontes de Dados Curriculares](docs/DATA_SOURCES.md)
- [Estratégia de Testes](docs/TESTING.md)
- [Integração de IA](docs/AI.md)
- [Decisões Arquiteturais (ADRs)](docs/adr/)

---

## 3. Estrutura do Repositório

```text
guia-de-ensino/
├── .env.example              # Modelo de variáveis de ambiente
├── .gitignore                # Regras de exclusão de arquivos no Git
├── GEMINI.md                 # Regras permanentes de governança e desenvolvimento
├── README.md                 # Documento principal de apresentação
├── docs/                     # Documentação de arquitetura, domínio e planejamento
│   ├── ARCHITECTURE.md       # Arquitetura global, camadas e tecnologias
│   ├── ROADMAP.md            # Fases de desenvolvimento, status e critérios
│   ├── DOMAIN_MODEL.md       # Entidades, agregados e regras de negócio
│   ├── REPLANNING.md         # Motor e ciclo de replanejamento automático
│   ├── DATA_SOURCES.md       # BNCC e fontes curriculares
│   ├── TESTING.md            # Plano e suíte de testes obrigatórios
│   ├── AI.md                 # Arquitetura da IA, prompts e segurança
│   └── adr/                  # Architectural Decision Records
│       ├── 0001-stack-tecnologica-e-arquitetura-base.md
│       ├── 0002-estrategia-local-first-e-persistencia.md
│       ├── 0003-motor-deterministico-e-replanejamento.md
│       └── 0004-padroes-de-seguranca-privacidade-lgpd.md
├── app/                      # Código do aplicativo cliente (Flutter) [Etapa 1]
└── server/                   # Código do backend de sincronização (NestJS) [Etapa 9]
```

---

## 4. Estado Atual e Próximos Passos

O projeto encontra-se na **Etapa 0 (Inspeção, Governança e Planejamento)** concluída.
Consulte o arquivo [docs/ROADMAP.md](docs/ROADMAP.md) para verificar o progresso das etapas e os critérios de aceitação.

---

## 5. Licença e Termos

Projeto educacional e pedagógico. Direitos reservados aos mantenedores.
