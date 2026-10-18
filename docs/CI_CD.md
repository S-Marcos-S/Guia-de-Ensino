# CI/CD e Políticas de Entrega — Guia de Ensino

Este documento descreve a infraestrutura de Integração Contínua (CI) e Entrega Contínua (CD), as políticas de Git, o ciclo de vida de releases e a gestão de assinaturas de artefatos do **Guia de Ensino**.

---

## 1. Política de Git e Versionamento

O desenvolvimento do Guia de Ensino segue o modelo incremental rigoroso definido em `GEMINI.md`:

### 1.1 Commits Locais
- **Critério de Criação**: Um commit local só deve ser criado ao concluir uma etapa ou unidade de trabalho claramente delimitada.
- **Validação Prévia Obrigatória**: Nunca comitar código sem antes executar:
  ```powershell
  dart format --set-exit-if-changed .
  flutter analyze
  flutter test
  ```
  Se qualquer uma dessas etapas falhar ou se houver avisos de análise estática, o commit **não** deve ser gerado.
- **Formato da Mensagem**: Usar o padrão Conventional Commits em português:
  - `feat: [descrição]` para novas funcionalidades e módulos.
  - `fix: [descrição]` para correções de bugs e lints.
  - `docs: [descrição]` para documentações, ADRs e guias.
  - `test: [descrição]` para adição ou atualização de suites de testes.
  - `ci: [descrição]` para alterações de workflows e infraestrutura de automação.
  - `chore: [descrição]` para tarefas de manutenção, dependências e configurações.
- **Preservação de Trabalho**: Alterações pré-existentes do usuário nunca devem ser sobrescritas ou comitadas automaticamente.

### 1.2 Regras de Push e Histórico Remoto
- **Autorização Explícita**: Nunca executar `git push`, publicar releases, reescrever histórico (`push --force`) ou criar branches/tags remotas sem confirmação explícita do usuário.
- **Segredos e Artefatos**: É terminantemente proibido comitar arquivos sensíveis (`.env`, `.keystore`, `.jks`, credenciais de banco, tokens de API, etc.) ou artefatos de build compilados (`build/`, `.dart_tool/`, `.apk`, `.aab`).

---

## 2. Workflows do GitHub Actions

A automação remota é composta por dois workflows versionados no diretório `.github/workflows/`:

```
.github/
└── workflows/
    ├── ci.yml       # Integração contínua em PRs e pushes para main
    └── release.yml  # Geração e publicação de releases a partir de tags v*
```

### 2.1 Workflow de CI (`ci.yml`)
- **Gatilhos**:
  - `push` direcionado à branch `main`.
  - `pull_request` aberto ou atualizado com destino à branch `main`.
- **Ambiente de Execução**: Runner Ubuntu (`ubuntu-latest`).
- **Permissões Mínimas de Segurança**:
  ```yaml
  permissions:
    contents: read
  ```
- **Etapas Executadas**:
  1. `actions/checkout@v4`: Baixa o repositório.
  2. `actions/setup-java@v4`: Configura o JDK 17 (Temurin).
  3. `subosito/flutter-action@v2`: Configura o Flutter SDK na versão `3.47.7` (canal `stable`) com cache habilitado.
  4. `flutter pub get`: Instala as dependências no diretório `apps/app`.
  5. `dart format --set-exit-if-changed .`: Valida se todo o código Dart está formatado segundo o padrão oficial.
  6. `flutter analyze`: Executa a análise estática estrita.
  7. `flutter test`: Executa toda a suite de testes automatizados (unitários, domínio, persistência SQLite e widgets).
  8. `flutter build apk --release`: Compila o artefato Android em modo release para validar que a toolchain nativa conclui sem falhas.

---

### 2.2 Workflow de Releases (`release.yml`)
- **Gatilhos**:
  - `push` de tags que sigam o padrão semântico `v*` (ex: `v0.1.0`, `v1.0.0`).
- **Permissões Mínimas de Segurança**:
  ```yaml
  permissions:
    contents: write
  ```
- **Etapas Executadas**:
  1. Validação estrita do padrão da tag via regex (`^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$`).
  2. Execução completa dos testes obrigatórios (`format`, `analyze`, `test`).
  3. Verificação de assinatura Android (detalhada na seção 3).
  4. Compilação dos artefatos:
     - APK universal em release (`app-release.apk`).
     - Android App Bundle (`app-release.aab`).
  5. Publicação automática da Release no GitHub (`softprops/action-gh-release@v2`) com changelog automático, hash do commit de origem e artefatos anexados.

---

## 3. Política de Assinatura de Artefatos Android

### 3.1 Estado Atual e Limitações
- **Situação Atual**: O repositório **não** possui e **não deve possuir** keystores de produção versionadas.
- **Comportamento Atual no CI**: Quando compilado sem segredos de assinatura fornecidos, o Gradle utiliza a chave padrão de debug (`signingConfigs.getByName("debug")`) para que a compilação release conclua e os artefatos de teste possam ser inspecionados.
- **Aviso Obrigatório**: Artefatos gerados sem chave oficial de release são explicitamente identificados nas notas de versão como **"Build de Teste / Não Assinado para Produção"**. Eles **não** devem ser distribuídos como versões finais de produção para o usuário final antes da configuração segura da keystore.

### 3.2 Como Configurar a Assinatura Oficial no GitHub Secrets
Quando a equipe estiver pronta para assinar artefatos oficiais de produção:

1. Gerar localmente a keystore oficial (armazenada de forma segura fora do Git):
   ```bash
   keytool -genkey -v -keystore guia-de-ensino-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias guia_release
   ```
2. Codificar o arquivo `.jks` em Base64:
   ```bash
   # Linux/macOS
   base64 -w 0 guia-de-ensino-release.jks > keystore_base64.txt
   # Windows PowerShell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("guia-de-ensino-release.jks")) | Set-Content keystore_base64.txt
   ```
3. Configurar os seguintes segredos no GitHub (`Settings > Secrets and variables > Actions > New repository secret`):
   - `ANDROID_KEYSTORE_BASE64`: Conteúdo do arquivo `keystore_base64.txt`.
   - `ANDROID_KEYSTORE_PASSWORD`: Senha da keystore.
   - `ANDROID_KEY_ALIAS`: Alias da chave (ex: `guia_release`).
   - `ANDROID_KEY_PASSWORD`: Senha da chave.
4. O workflow de release detectará automaticamente a presença desses segredos, decodificará a keystore em tempo de execução de forma efêmera no runner, compilará o APK e AAB assinados oficialmente e removerá o arquivo temporário ao final.

---

## 4. Ciclo de Vida de uma Versão (Release)

Para publicar uma nova versão:

1. Concluir a etapa de desenvolvimento localmente, garantindo todos os testes passando.
2. Atualizar o `version` em `apps/app/pubspec.yaml` (ex: `version: 0.4.0+4`).
3. Criar commit local e obter autorização para o push:
   ```bash
   git commit -m "chore(release): preparar versao v0.4.0"
   ```
4. Criar a tag anotada:
   ```bash
   git tag -a v0.4.0 -m "Release v0.4.0 - Guia de Ensino"
   ```
5. Enviar a tag ao repositório remoto apenas com autorização explícita:
   ```bash
   git push origin main
   git push origin v0.4.0
   ```
6. O workflow `release.yml` será disparado automaticamente, executará as validações e publicará a release com os artefatos anexados.
