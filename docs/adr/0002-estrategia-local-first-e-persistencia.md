# ADR 0002: Estratégia Local-First e Persistência de Dados

## Status
Aprovado

## Contexto
Professores frequentemente trabalham em escolas ou ambientes com conexão de internet instável, lenta ou inexistente (como salas de aula, quadras ou transporte). O planejamento pedagógico e o registro de aulas não podem depender de conectividade de rede para serem consultados ou alterados. Além disso, quando houver múltiplos dispositivos ou sincronização remota, o sistema precisa garantir a integridade dos dados sem perda de registros.

## Decisão
1. **Abordagem Local-First**: O banco de dados primário de operação do aplicativo é o banco de dados SQLite local no dispositivo do professor. Toda leitura e gravação é concluída localmente de forma síncrona/imediata.
2. **Identificadores Imutáveis**: Todas as tabelas e entidades de domínio utilizam identificadores universais únicos (UUID v4) gerados no momento da criação da entidade, eliminando conflitos de autoincremento entre dispositivos.
3. **Versionamento e Rastreamento**: Cada registro possui campos `created_at`, `updated_at`, `sync_status` (`synced`, `pending_upload`, `pending_conflict`) e um número de revisão incremental (`revision`).
4. **Política de Conflitos**:
   - As alterações de planejamento concorrentes mantêm o histórico e nunca sobrescrevem silenciosamente o trabalho do professor.
   - Os registros de aulas realizadas possuem precedência sobre propostas de planejamento não confirmadas.
   - Em caso de divergência inconciliável entre versões de planejamento remoto e local, o sistema apresenta um comparativo visual e solicita a decisão explícita do professor.

## Consequências
- **Positivas**:
  - Resposta instantânea da interface sem travamento de rede ("zero latency").
  - Funcionamento garantido em 100% das funcionalidades essenciais sem acesso à internet.
  - Robustez contra falhas de rede e facilidade de backup/restauração local de arquivos SQLite.
- **Riscos e Mitigações**:
  - *Sincronização bidirecional complexa*: Mitigada pelo design formalizado de revisões e pela posterior implementação no backend com testes específicos de concorrência.
