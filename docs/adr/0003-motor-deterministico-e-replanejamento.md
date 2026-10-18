# ADR 0003: Motor Determinístico de Planejamento e Replanejamento Automático

## Status
Aprovado

## Contexto
Um dos maiores riscos em aplicativos educacionais que incorporam Inteligência Artificial é confiar à IA cálculos matemáticos de calendário, distribuição de datas, verificação de carga horária e alocação de aulas. Modelos de linguagem (LLMs) são probabilísticos e suscetíveis a alucinações de datas, descarte silencioso de conteúdos e erros aritméticos em contagem de semanas e feriados.

## Decisão
1. **Separação Rígida entre Motor Aritmético e IA**:
   - Todo cálculo de datas, dias letivos válidos, feriados, recessos, eventos e alocação de conteúdos em aulas é de responsabilidade exclusiva de um **motor determinístico implementado em Dart puro**.
   - A mesma lista de conteúdos, calendário e restrições SEMPRE produzirá o mesmo resultado cronológico exato.
2. **Replanejamento como Processo Controlado e Auditável**:
   - O replanejamento automático segue um pipeline de 14 etapas bem definidas.
   - Nenhuma aula já registrada como realizada é apagada ou modificada retroativamente.
   - Restrições fixas cadastradas pelo professor (como datas de provas bimestrais ou projetos específicos) são protegidas contra deslocamentos automáticos não autorizados.
   - Caso a carga horária restante seja insuficiente para comportar todos os conteúdos obrigatórios, o sistema **NUNCA descarta conteúdos silenciosamente**; em vez disso, emite um relatório explícito de déficit de aulas e solicita a decisão do professor.
3. **Papel Restrito da IA**:
   - A IA atua fornecendo propostas sugestivas de sequenciamento pedagógico ou agrupamento de conteúdos correlatos.
   - Toda sugestão da IA é formatada em JSON com validação de esquema estrita e submetida à aprovação do motor determinístico antes de ser exibida para homologação do professor.

## Consequências
- **Positivas**:
  - Confiabilidade absoluta nos números de aulas e prazos do calendário escolar.
  - Conformidade com as normas legais de dias letivos da LDB / MEC.
  - Testabilidade automatizada determinística, permitindo validar centenas de cenários sem custo de tokens de IA.
- **Riscos e Mitigações**:
  - *Algoritmos de distribuição com dependências e restrições podem se tornar complexos*: Mitigado por ampla cobertura de testes unitários com os 12 casos de teste obrigatórios descritos na governança.
