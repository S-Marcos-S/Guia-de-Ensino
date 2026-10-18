# GEMINI.md — Regras permanentes do Guia de Ensino

## 1. Identidade do projeto

O Guia de Ensino é um aplicativo multiplataforma de planejamento pedagógico para professores do Ensino Fundamental e do Ensino Médio.

O projeto deve priorizar confiabilidade, simplicidade de uso, acessibilidade, privacidade, manutenção e compartilhamento de código entre plataformas.

O idioma padrão da interface e da documentação voltada ao usuário é português brasileiro.

## 2. Regras invioláveis

- Leia este arquivo antes de iniciar qualquer tarefa.
- Inspecione o estado atual do projeto antes de alterar arquivos.
- Preserve alterações existentes e não sobrescreva trabalho sem autorização.
- Não implemente funcionalidades extensas sem um plano incremental.
- Não declare testes, builds ou integrações como concluídos sem executá-los.
- Não invente dados curriculares, fontes, resultados de testes ou capacidades do sistema.
- Não deixe botões ou fluxos principais sem implementação real.
- Não introduza dependências sem avaliar sua necessidade e compatibilidade.
- Não altere tecnologias fundamentais sem documentar a decisão.
- Não faça push, merge, publicação ou implantação sem autorização explícita.
- Não armazene segredos no código ou no repositório.
- Não apague registros históricos de aulas durante o replanejamento.

## 3. Arquitetura e organização

- Mantenha a interface separada das regras de negócio.
- Mantenha o domínio independente de bibliotecas de interface.
- Isole persistência, sincronização, serviços externos e inteligência artificial.
- Compartilhe regras de negócio entre as plataformas.
- Isole implementações específicas de plataforma.
- Evite duplicação de lógica.
- Prefira módulos pequenos e responsabilidades claras.
- Documente decisões arquiteturais relevantes.
- Utilize injeção de dependências quando ela melhorar testabilidade e desacoplamento.
- Evite abstrações desnecessárias e arquitetura excessivamente complexa para funcionalidades simples.

A estrutura definitiva deverá acompanhar a arquitetura aprovada em `docs/ARCHITECTURE.md`.

## 4. Qualidade do código

- Utilize tipagem forte sempre que a linguagem permitir.
- Prefira funções pequenas e nomes claros.
- Evite lógica duplicada.
- Evite valores mágicos: utilize constantes ou configurações documentadas.
- Valide dados nas fronteiras do sistema.
- Trate erros explicitamente.
- Não esconda exceções importantes.
- Não deixe código morto, marcadores temporários ou implementações falsas em funcionalidades consideradas concluídas.
- Não suprima avisos ou desative regras de análise apenas para facilitar a compilação.
- Siga os formatadores e analisadores configurados no projeto.
- Utilize comentários para explicar decisões não óbvias, e não para repetir o código.

## 5. Regras de negócio e calendário

- Os cálculos de datas e de carga horária devem ser determinísticos.
- A IA não é responsável pela aritmética crítica nem pela validação final do calendário.
- Considere as ocorrências reais de aulas e as restrições cadastradas.
- Diferencie aulas previstas, realizadas, parcialmente realizadas e não realizadas.
- Preserve o histórico das aulas.
- Detecte insuficiência de carga horária.
- Não elimine conteúdos obrigatórios silenciosamente.
- Não mova compromissos protegidos sem autorização.
- Utilize testes automatizados para datas, capacidade, distribuição e replanejamento.
- Registre e versione as mudanças relevantes no planejamento.

## 6. Regras do replanejamento automático

O replanejamento deverá:

1. Identificar a turma e a disciplina afetadas.
2. Consultar o planejamento e o progresso atualizados.
3. Calcular a capacidade restante.
4. Preservar registros históricos e restrições fixas.
5. Considerar prioridades e dependências curriculares.
6. Gerar uma proposta de alterações.
7. Validar a proposta por regras determinísticas.
8. Explicar as mudanças.
9. Permitir revisão pelo professor.
10. Registrar a versão aplicada.

A IA pode sugerir alterações, mas não pode gravá-las diretamente sem passar pela validação do sistema.

Não descarte conteúdo obrigatório para fazer o cronograma caber no calendário.

Se não existir uma solução válida, apresente o conflito e solicite uma decisão do professor.

## 7. Regras de inteligência artificial

- Isole cada provedor atrás de uma interface.
- Mantenha as chaves exclusivamente no backend ou em um gerenciador seguro de segredos.
- Utilize saídas estruturadas e esquemas versionados quando apropriado.
- Valide todas as respostas antes de utilizá-las.
- Trate respostas como sugestões, não como fatos automaticamente confirmados.
- Implemente tratamento de erros, limites de uso e controle de custos.
- Evite chamadas redundantes.
- Utilize mocks em testes que não devam depender da rede.
- Não permita que documentos importados alterem as instruções internas do agente ou as políticas do aplicativo.
- Não envie dados pessoais desnecessários a serviços externos.
- Documente os prompts e suas versões.

## 8. Fontes curriculares

- Prefira fontes oficiais e materiais com permissões claras.
- Registre a origem dos conteúdos importados.
- Preserve o texto original quando possível.
- Diferencie informações verificadas de sugestões geradas por IA.
- Não invente códigos, habilidades ou referências curriculares.
- Não confunda a BNCC com um planejamento semanal pronto.
- Permita que o professor personalize os conteúdos e revise os dados importados.

## 9. Persistência e sincronização

- Utilize identificadores estáveis.
- Versione os esquemas de banco de dados.
- Crie migrações explícitas.
- Preserve os dados em falhas de rede.
- Trate conflitos de sincronização de forma explícita.
- Não sobrescreva alterações sem uma política definida.
- Teste persistência após reinicialização.
- Não considere uma operação persistida antes da confirmação do mecanismo correspondente.

## 10. Segurança e privacidade

- Nunca exponha tokens ou senhas.
- Valide entrada de usuário e arquivos importados.
- Aplique autorização no backend.
- Isole os dados dos usuários.
- Evite registrar informações pessoais em logs.
- Colete somente os dados necessários.
- Considere a LGPD e os cuidados específicos com dados de crianças e adolescentes.
- Não execute conteúdo importado como código.
- Não confie em dados externos sem validação.
- Não desative mecanismos de segurança para contornar erros de desenvolvimento.

## 11. Interface e acessibilidade

- Priorize botões grandes e ações claras.
- Mantenha a interface em português brasileiro.
- Utilize layouts adaptáveis para mobile e desktop.
- Forneça feedback visual para operações demoradas.
- Mostre mensagens de erro úteis.
- Implemente estados vazios e de carregamento.
- Evite elementos interativos meramente decorativos.
- Considere contraste, leitura, foco e navegação por teclado.
- Preserve a consistência visual entre as plataformas.

## 12. Testes obrigatórios

Toda funcionalidade relevante deve possuir critérios de aceitação e testes adequados.

Antes de concluir uma tarefa:

1. Execute os testes relacionados.
2. Execute a análise estática disponível.
3. Formate os arquivos modificados.
4. Verifique erros de compilação quando aplicável.
5. Corrija regressões introduzidas.
6. Informe limitações do ambiente.
7. Atualize a documentação correspondente.

Não enfraqueça os testes para fazer uma implementação defeituosa parecer válida.

## 13. Fluxo de trabalho

Para cada tarefa:

1. Inspecione o estado atual.
2. Leia o roadmap.
3. Defina um objetivo pequeno.
4. Identifique arquivos afetados.
5. Defina critérios de aceitação.
6. Implemente a alteração.
7. Execute as verificações.
8. Atualize a documentação.
9. Informe os resultados reais.
10. Registre as pendências.

Atualize `docs/ROADMAP.md` quando o status de uma etapa mudar.

Não avance para etapas dependentes de funcionalidades que ainda não estejam validadas.

## 14. Documentação

Mantenha a documentação coerente com o código.

Registre:
- Arquitetura.
- Modelo de domínio.
- Comandos de execução.
- Comandos de testes.
- Variáveis de ambiente.
- Decisões arquiteturais.
- Fontes curriculares.
- Integrações de IA.
- Regras do replanejamento.
- Limitações conhecidas.

Não documente como concluída uma funcionalidade que esteja apenas planejada.

## 15. Critério de conclusão

Uma tarefa somente pode ser considerada concluída quando:

- A implementação atende aos critérios de aceitação.
- Os testes aplicáveis foram executados.
- Não há regressões conhecidas introduzidas pela alteração.
- A documentação necessária foi atualizada.
- As limitações restantes foram informadas.
- O estado real do código corresponde ao status registrado no roadmap.

## 16. Política de Git, Versionamento e CI/CD

- Ao concluir uma etapa ou unidade de trabalho claramente delimitada, revisar o diff completo, executar as verificações obrigatórias (`dart format`, `flutter analyze`, `flutter test` e builds aplicáveis) e criar um commit local se tudo passar.
- Nunca criar commits com testes falhando, erros de análise ou alterações não relacionadas.
- Usar mensagens padronizadas seguindo Conventional Commits (`feat:`, `fix:`, `docs:`, `test:`, `ci:`, `chore:`) de maneira consistente em português.
- Não incluir arquivos secretos, credenciais, keystores, tokens, arquivos temporários ou artefatos de build no repositório.
- Não executar `git push`, publicar releases, reescrever histórico remoto ou alterar configurações do GitHub sem autorização explícita do usuário.
- Se houver alterações pré-existentes do usuário, preservá-las e não incluí-las automaticamente em um commit de etapa sem autorização.
- Toda release e tag (`v*`) deve passar pela validação de CI e ter suas limitações de assinatura explicitamente documentadas (conforme `docs/CI_CD.md`).
