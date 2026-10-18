# ADR 0004: Padrões de Segurança, Privacidade e LGPD

## Status
Aprovado

## Contexto
O **Guia de Ensino** lida com a rotina pedagógica escolar. A Lei Geral de Proteção de Dados Pessoais (LGPD - Lei nº 13.709/2018) estabelece regras rigorosas sobre a coleta e o tratamento de dados pessoais, com salvaguardas adicionais no que tange a crianças e adolescentes. O aplicativo deve ser concebido desde o princípio segundo a abordagem de *Privacy by Design* e *Security by Default*.

## Decisão
1. **Minimização de Dados (LGPD)**:
   - O aplicativo foca estritamente na gestão do planejamento docente (turmas, disciplinas, conteúdos, datas e aulas).
   - Não serão coletados nem transmitidos nomes completos de estudantes, notas individuais de alunos, dados médicos, biométricos ou comportamentais.
   - Qualquer referência a alunos no diário de bordo/observações de aula deve alertar o professor para evitar a inclusão de dados identificáveis de menores.
2. **Isolamento e Segurança de Segredos**:
   - Nenhuma chave de API de IA, segredo de JWT ou credencial de banco de dados reside no código-fonte cliente, no aplicativo compilado ou no repositório.
   - As variáveis sensíveis existem unicamente no ambiente de execução do backend via variáveis de ambiente seguras (`.env` não commitado / Secret Manager).
3. **Segurança no Tratamento de Arquivos Importados**:
   - Arquivos enviados pelo professor (PDF, DOCX, XLSX contendo planos de curso) passam por rotinas de sanitização no backend/cliente antes do processamento para mitigar riscos de injeção de prompts maliciosos (*Prompt Injection*) e vulnerabilidades de analisadores de documentos.
4. **Armazenamento Seguro Local**:
   - Dados de sessão e tokens de autenticação no dispositivo móvel ou desktop são armazenados utilizando mecanismos nativos com criptografia (Keystore no Android, Keychain no iOS/macOS, DPAPI no Windows).

## Consequências
- **Positivas**:
  - Risco jurídico e de vazamento de dados de menores reduzido ao mínimo técnico possível.
  - Conformidade arquitetural com a LGPD e boas práticas de segurança da informação.
  - Confiança dos docentes e instituições de ensino no uso da ferramenta.
- **Riscos e Mitigações**:
  - *Tentativas de injeção em textos curriculares importados*: Mitigado por sanitização textual e uso de esquemas de saída estruturados (JSON Schema) que impedem o modelo de alterar comandos do sistema.
