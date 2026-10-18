# Estratégia de Testes e Qualidade — Guia de Ensino

Este documento estabelece as diretrizes de testes automatizados, critérios de cobertura e procedimentos de verificação de qualidade para o **Guia de Ensino**.

---

## 1. Pirâmide de Testes

```text
       / \
      / E2E \        (Fluxos ponta a ponta críticos nas plataformas)
     /───────\
    / Integração \    (Persistência SQLite, Migrações, Sync HTTP e API)
   /───────────────\
  / Testes Unitários \ (Domínio, Motor de Calendário, Replanejamento, Parsers)
 /─────────────────────\
```

- **Testes Unitários (Base)**: Foco no motor determinístico de calendário, regras de distribuição pedagógica, ordenação topológica de pré-requisitos e entidades de domínio. Executam em milissegundos sem dependências de emulador ou rede.
- **Testes de Integração**: Validam banco de dados local SQLite (migrações versionadas, consultas, transações atômicas) e adaptadores de rede com mocks.
- **Testes de Interface (Widget Tests)**: Testam interações do professor com componentes de calendário, listagem de turmas e modais de aprovação de replanejamento.
- **Testes E2E**: Testam o fluxo completo de cadastro de ano letivo até geração de planejamento.

---

## 2. Casos de Teste Obrigatórios do Replanejamento

A governança do projeto estabelece que a funcionalidade central de replanejamento deve ser validada por pelo menos 12 cenários automatizados indispensáveis:

1. **Aula perdida sem conteúdo concluído**: Uma aula é marcada como `not_held`. O motor deve empurrar o conteúdo pendente para a próxima data disponível sem apagar registros anteriores.
2. **Conteúdo que exige mais aulas do que o previsto**: Conteúdo de 2 aulas precisou de 3. O sistema deve ajustar a duração do conteúdo e deslocar os itens subsequentes respeitando as aulas restantes.
3. **Feriado inserido no meio do planejamento**: Inclusão de um novo dia sem aula. As aulas previstas para a data afetada devem ser realocadas para a próxima data disponível.
4. **Avaliação com data fixa**: Uma prova bimestral cadastrada com `is_locked = true` deve permanecer na data original, e os conteúdos ao redor devem ser remanejados sem sobrepor a avaliação.
5. **Conteúdo obrigatório com dependência pedagógica**: O conteúdo B depende de A. O motor nunca pode agendar B antes da conclusão prevista de A.
6. **Capacidade insuficiente para concluir todos os conteúdos**: Carga horária restante menor do que a soma das durações dos conteúdos. O motor deve emitir um relatório claro de déficit sem descartar silenciosamente nenhum conteúdo obrigatório.
7. **Alterações manuais protegidas**: Uma aula com `is_locked = true` ajustada manualmente pelo professor não pode ser movida pelo replanejamento automático.
8. **Replanejamento rejeitado pelo professor**: Ao rejeitar a proposta, o planejamento ativo anterior deve permanecer 100% inalterado.
9. **Restauração de versão anterior**: O professor restaura uma versão de planejamento do mês passado. O sistema restaura o cronograma futuro daquela versão sem apagar o histórico de aulas efetivamente realizadas no período intermediário.
10. **Replanejamento repetido sem alterações de entrada**: Executar o algoritmo duas vezes seguidas com as mesmas entradas deve gerar uma proposta idêntica (determinismo estrito).
11. **Falha ou indisponibilidade da IA**: O serviço de IA falha ou fica offline. O motor determinístico deve concluir o replanejamento com as heurísticas locais e exibir a proposta normalmente.
12. **Sincronização com alterações conflitantes**: Dois dispositivos alteram o planejamento da mesma turma offline. Ao sincronizar, o sistema identifica o conflito de revisão sem sobrescrever dados silenciosamente.

---

## 3. Comandos de Verificação e Análise Estática

Conforme o ambiente de desenvolvimento estiver configurado com as ferramentas da stack:

### Dart & Flutter (Frontend & Domínio)
```bash
# Análise estática do código
flutter analyze

# Execução de testes unitários e de integração
flutter test

# Verificação de formatação
dart format --set-exit-if-changed .

# Cobertura de testes
flutter test --coverage
```

### NestJS & TypeScript (Backend)
```bash
# Execução dos testes unitários
npm test

# Execução dos testes e2e
npm run test:e2e

# Análise estática
npm run lint
```

---

## 4. Critério de Aceitação para Conclusão de Tarefas

Nenhuma tarefa ou etapa será considerada concluída sem:
1. Execução real dos testes unitários pertinentes no terminal.
2. Análise estática sem erros ou avisos graves.
3. Verificação de que não foram criadas regressões em testes anteriores.
4. Atualização correspondente no arquivo `docs/ROADMAP.md`.
