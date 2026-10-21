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
  - `push` de tags que sigam o padrão semântico `v*` (ex: `v0.9.0`, `v1.0.0`).
- **Permissões Mínimas de Segurança**:
  ```yaml
  permissions:
    contents: write
  ```
- **Estrutura dos Jobs e Orquestração**:
  1. `validate-tag`: Validação do formato semântico via regex e extração da versão (`version_name`) e número de build incremental (`build_number` derivado de `GITHUB_RUN_NUMBER`).
  2. `validate-backend`: Execução da validação completa do servidor NestJS em container Ubuntu com serviço PostgreSQL 16 Alpine (Prettier, ESLint, compilação, testes unitários e testes de integração).
  3. `validate-flutter`: Execução da validação do cliente Flutter (Drift `build_runner`, formatação `dart format`, análise estática `flutter analyze`, teste de migração de banco v6 e suíte geral de `flutter test`).
  4. `build-and-release` (executado somente se os 3 jobs anteriores forem aprovados com sucesso):
     - **Verificação Mandatória de Segredos**: Aborta imediatamente se qualquer um dos 4 segredos oficiais de assinatura estiver ausente. **Nunca publica APK assinado com chave debug.**
     - **Decodificação Efêmera**: Decodifica a keystore em diretório temporário isolado fora do repositório (`${RUNNER_TEMP}/keystore`) com permissões `0600`.
     - **Compilação de Release**: Compila o APK universal e o AAB com `--build-name` e `--build-number` sincronizados com a versão.
     - **Verificação Criptográfica do APK**: Inspeciona o APK compilado via `keytool -printcert -jarfile` e valida se o fingerprint SHA-256 coincide com a identidade oficial registrada. Em caso de divergência, o job falha e o artefato é rejeitado.
     - **Geração de Checksums SHA-256**: Calcula o hash SHA-256 dos artefatos para permitir verificação de integridade pós-download.
     - **Limpeza Garantida**: Remove a keystore temporária incondicionalmente no bloco `if: always()`.
     - **Publicação de Release**: Publica a release no GitHub Releases com changelog automático, dados de compilação, hash do commit e artefatos anexados (`.apk`, `.aab`, `.sha256`).

---

## 3. Política de Assinatura de Artefatos Android

### 3.1 Estado Atual e Política de Assinatura
- **Situação Atual**: O repositório **não** possui e **não deve possuir** keystores ou certificados privados de produção versionados.
- **Configuração no Gradle (`build.gradle.kts`)**:
  - Quando a variável `OFFICIAL_RELEASE=true` (ou a propriedade `-PofficialRelease=true`) estiver ativa, o Gradle **exige estritamente** as 4 variáveis de ambiente de assinatura (`ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`). Se qualquer uma faltar ou se o arquivo não existir, o build **falha imediatamente com erro explícito**, impedindo qualquer fallback silencioso para chaves de debug em builds oficiais.
  - Para compilações locais normais de desenvolvimento (sem `OFFICIAL_RELEASE`), o Gradle exibe um aviso de log e utiliza a chave de debug para conveniência do desenvolvedor.
- **Identidade Permanente**: O aplicativo utiliza chave privada RSA de 3072 bits com validade de 10.000 dias (~27 anos). Esta chave deve ser preservada permanentemente, pois futuras atualizações do APK dependem da mesma assinatura.
- **Registro Público do Certificado Oficial**:
  - **Alias**: `guia_release`
  - **Algoritmo da Chave**: RSA 3072 bits (Assinatura `SHA384withRSA`)
  - **Período de Validade**: 21 de Outubro de 2026 até 08 de Março de 2054
  - **Número de Série**: `786014f4f8190006`
  - **Fingerprint SHA-256**: `B6:C3:2F:6D:6F:81:A5:4A:4B:D5:89:48:C9:86:D5:D4:84:CA:08:C3:7F:66:06:0E:A2:62:1C:E8:CD:03:68:0D`
  - **Fingerprint SHA-1**: `37:A1:1C:7F:73:FE:E0:DB:08:D6:E0:60:9D:4A:92:52:0A:D9:2B:F6`

### 3.2 Geração Segura da Keystore no Termux e Backups
Para garantir que as senhas **nunca** sejam expostas em chats, histórico de shell ou logs de CI, a keystore é gerada localmente no Termux via prompt interativo protegido:

1. **Executar o script interativo de geração**:
   ```bash
   bash /data/data/com.termux/files/home/keystores/gerar_keystore_producao.sh
   ```
   * O script invocará o `keytool` solicitando as senhas de forma oculta diretamente no terminal.
   * Parâmetros aplicados: algoritmo `RSA`, tamanho `3072 bits`, validade `10000 dias`, formato `JKS`, alias `guia_release`.
   * Permissões restritas (`0600`) são aplicadas automaticamente ao arquivo gerado (`/data/data/com.termux/files/home/keystores/guia-de-ensino-release.jks`).
2. **Política de Backups Protegidos Obrigatórios**:
   * **Backup 1 (Cofre Digital Criptografado)**: Armazenar uma cópia da keystore (`.jks`) e de sua senha em um gerenciador de senhas ou cofre criptografado (ex: Bitwarden, KeePassXC).
   * **Backup 2 (Mídia Física Offline Isolada)**: Armazenar uma cópia em pendrive/mídia externa desconectada da internet, em local físico seguro.
   * **Aviso**: Se a chave de produção for perdida, **não é possível recuperar a identidade de assinatura** e os usuários existentes seriam forçados a desinstalar o aplicativo para receber novas atualizações.

### 3.3 Configuração dos GitHub Secrets para o Workflow de Release
Após a geração segura no Termux, configure os 4 segredos no repositório GitHub (`Settings > Secrets and variables > Actions > New repository secret`):

1. `ANDROID_KEYSTORE_BASE64`: Conteúdo do arquivo `/data/data/com.termux/files/home/keystores/keystore_base64.txt`.
2. `ANDROID_KEYSTORE_PASSWORD`: A senha definida interativamente para a keystore.
3. `ANDROID_KEY_ALIAS`: `guia_release`.
4. `ANDROID_KEY_PASSWORD`: A senha da chave privada (idêntica à da keystore).

O workflow de release lerá esses segredos, montará o arquivo temporário de forma efêmera no runner durante a compilação oficial e o removerá com garantia no bloco `always()`.

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
