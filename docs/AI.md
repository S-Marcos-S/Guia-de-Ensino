# Diretrizes de Inteligência Artificial — Guia de Ensino

A inteligência artificial no **Guia de Ensino** é projetada como um recurso auxiliar consultivo, seguro, auditável e estritamente subordinado à revisão pedagógica do professor.

---

## 1. Princípios Arquiteturais da IA

1. **Agnóstica de Fornecedor**: A aplicação consome uma interface abstrata (`AiServiceProvider`), permitindo trocar o provedor (Google Gemini, OpenAI, Anthropic ou modelos locais) sem afetar a lógica de negócios.
2. **Segurança de Segredos**: Nenhuma chave de API reside no aplicativo cliente ou no repositório. O cliente envia requisições estruturadas para o backend do Guia de Ensino, onde as credenciais são mantidas isoladas.
3. **Saídas Estruturadas (Structured Outputs)**: Todas as respostas da IA devem obrigatoriamente validar esquemas JSON estritos (JSON Schema versionado). Textos livres sem validação não são aceitos para alterações de cronograma.
4. **Proteção contra Falhas de Rede**: Se a IA estiver indisponível ou ocorrer erro de requisição, o sistema continua operando normalmente com seu motor determinístico e heurísticas locais.
5. **Sem Alucinações em Cálculos**: A IA **não calcula datas de calendário, não soma carga horária letiva e não exclui conteúdos**. Apenas sugere sequências didáticas, títulos e agrupamentos.

---

## 2. Casos de Uso Aprovados para IA

| Caso de Uso | Entrada | Saída Esperada | Validação Humana |
|---|---|---|---|
| **Interpretação de Planos de Curso** | Texto extraído de PDF/DOCX do professor | Lista de tópicos com estimativa de aulas sugeridas em JSON | Obrigatória na tela de revisão antes de salvar |
| **Mapeamento de Habilidades** | Título e descrição do conteúdo do professor | Sugestão de código oficial da BNCC mais aderente | O professor confirma se a habilidade se aplica |
| **Sugestão de Reorganização** | Conteúdos pendentes e déficit de aulas | Proposta pedagógica de tópicos que podem ser integrados | Motor determinístico valida capacidade + aprovação do professor |
| **Justificativa Pedagógica** | Diferenças entre versão anterior e nova | Texto claro explicando a razão das alterações no cronograma | Exibido no modal de revisão |

---

## 3. Esquemas de Saída e Versionamento de Prompts

Os prompts são versionados em arquivos no backend (ex: `prompts/v1/course_plan_extraction.txt`) acompanhados de seu respectivo esquema JSON.

### Exemplo de Esquema para Extração de Conteúdos (`ExtractionResponseSchema.v1.json`):
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "CoursePlanExtractionResult",
  "type": "object",
  "properties": {
    "extracted_topics": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "title": { "type": "string" },
          "description": { "type": "string" },
          "suggested_lessons": { "type": "integer", "minimum": 1 },
          "suggested_bncc_code": { "type": "string" },
          "prerequisite_titles": {
            "type": "array",
            "items": { "type": "string" }
          }
        },
        "required": ["title", "suggested_lessons"]
      }
    },
    "pedagogical_summary": { "type": "string" }
  },
  "required": ["extracted_topics"]
}
```

---

## 4. Gestão de Custos, Cotas e Cache

- **Cache de Extração**: Documentos idênticos (verificados via hash SHA-256) reutilizam resultados em cache no backend para evitar chamadas redundantes.
- **Limite por Usuário**: Aplicação de *rate-limiting* (ex: máximo de 10 requisições de análise curricular por minuto e 50 por dia por docente) para sustentabilidade operacional.
- **Modelo Leve por Padrão**: Uso preferencial de modelos eficientes de alta velocidade (como `gemini-1.5-flash`), reservando modelos maiores apenas para documentos de alta complexidade.

---

## 5. Mitigação de Injeção de Instruções (Prompt Injection)

Documentos enviados por usuários podem conter textos maliciosos tentando redirecionar o comportamento do modelo.
- O prompt do sistema encapsula o texto do usuário em delimitadores estritos (`<untrusted_document_content>`).
- O modelo recebe instrução explícita no System Prompt para tratar qualquer comando imperativo dentro do documento exclusivamente como texto a ser ementado, nunca como instrução de controle.
