# Fontes de Dados Curriculares — Guia de Ensino

O **Guia de Ensino** utiliza dados curriculares oficiais para apoiar a organização dos conteúdos pedagógicos do professor.

---

## 1. Fonte Oficial de Referência: BNCC

A **Base Nacional Comum Curricular (BNCC)** é o documento normativo oficial do Ministério da Educação (MEC) que define o conjunto orgânico e progressivo de aprendizagens essenciais.

- **Portal Oficial**: [https://basenacionalcomum.mec.gov.br/](https://basenacionalcomum.mec.gov.br/)
- **Natureza dos Dados**: Documento público de referência nacional (Brasil).
- **Importante**: A BNCC não é um plano de aula pronto nem substitui os currículos das redes municipais, estaduais ou das escolas particulares. Ela serve como catálogo estruturado de competências, habilidades e objetos de conhecimento.

### Estrutura dos Códigos Alfanuméricos da BNCC
O Guia de Ensino preserva rigorosamente a nomenclatura oficial:
- Exemplo: `EF06MA01`
  - `EF`: Ensino Fundamental
  - `06`: 6º Ano
  - `MA`: Componente Curricular (Matemática)
  - `01`: Número sequencial da habilidade no ano
- Exemplo: `EM13MAT101`
  - `EM`: Ensino Médio
  - `13`: 1º ao 3º ano do Ensino Médio
  - `MAT`: Área / Componente de Matemática
  - `101`: Código específico da habilidade

> **Regra Inviolável**: Nunca invente códigos ou habilidades sintéticas que não existam no documento oficial do MEC.

---

## 2. Conjunto Curricular Inicial de Verificação

Para a homologação das Etapas 4 e 5, o Guia de Ensino incluirá um dataset estático verificado de semente (*seed data*) contendo:
1. **Ensino Fundamental - Anos Finais (Matemática - 6º Ano)**: Habilidades de `EF06MA01` a `EF06MA24`, com suas respectivas unidades temáticas (Números, Álgebra, Geometria, Grandezas e Medidas, Probabilidade e Estatística).
2. **Ensino Fundamental - Anos Finais (Língua Portuguesa - 6º Ano)**: Habilidades essenciais de leitura, escrita e análise linguística.
3. **Ensino Médio (Matemática - 1ª Série)**: Habilidades centrais da área de Matemática e suas Tecnologias.

Os dados serão versionados em formato JSON estruturado dentro do projeto (`assets/curriculum/seeds/`), permitindo testes sem dependência de internet.

---

## 3. Pipeline de Importação Extensível

Professores precisam utilizar seus próprios planos de curso, ementas de escolas e documentos de redes estaduais/municipais. O sistema fornecerá uma esteira de importação:

```text
[Documento do Professor] (PDF, DOCX, XLSX, Texto puro)
          │
          ▼
[Extrator e Sanitizador Local / Backend]
          │ (Remoção de scripts e caracteres inválidos)
          ▼
[Módulo de Estruturação Pedagógica (IA / Parser Heurístico)]
          │ (Identificação de títulos, objetivos, semanas sugeridas)
          ▼
[Cruzamento com BNCC / Base Local]
          │ (Associação de habilidades reconhecidas com alta confiança)
          ▼
[Tela de Revisão e Confirmação Humana]
          │ (O professor valida títulos, duração de aulas e dependências)
          ▼
[Gravação no Banco Local como CourseContent da Turma]
```

---

## 4. Diretrizes de Coleta e Direitos Autorais

- **Sem Scraping Indiscriminado**: Não serão realizadas raspagens automatizadas em sites de terceiros sem autorização.
- **Respeito aos Direitos Autorais**: Não serão importados ou distribuídos livros didáticos ou apostilas proprietárias de editoras privadas.
- **Proveniência Transparente**: Cada item importado registra data de importação, nome do arquivo de origem e status de revisão pelo professor.
