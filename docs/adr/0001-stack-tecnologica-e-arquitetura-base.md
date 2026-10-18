# ADR 0001: Stack Tecnológica e Arquitetura Base

## Status
Aprovado

## Contexto
O **Guia de Ensino** precisa ser um aplicativo multiplataforma capaz de operar em dispositivos móveis (Android e iOS) e em desktops (Windows, Linux e macOS), permitindo que professores planejem suas aulas tanto em smartphones quanto em seus computadores de trabalho. O sistema requer confiabilidade, excelente desempenho offline, interface moderna e acessível em português brasileiro e capacidade de sincronização opcional com a nuvem e integração com serviços de IA.

## Decisão
1. **Frontend e Domínio Multiplataforma**: Adotar **Flutter** e linguagem **Dart**. O código de domínio de regras de calendário e planejamento será escrito em Dart puro, garantindo total portabilidade e facilidade de testes unitários sem dependência do framework de UI.
2. **Interface**: Utilizar **Material 3** com sistema de temas próprio e componentes responsivos adaptados para telas pequenas (mobile) e telas amplas (desktop).
3. **Persistência Local**: Adotar **SQLite** como banco de dados embutido no dispositivo, garantindo execução local-first, integridade relacional, consultas rápidas e suporte a migrações versionadas.
4. **Backend e Sincronização**: Para a camada remota de sincronização e orquestração de IA, adotar **TypeScript com NestJS** e banco de dados **PostgreSQL**, mantendo tipagem estrita, modularidade e facilidade de manutenção.
5. **Integração com IA**: Isolar o provedor de IA (com uso inicial da **Google Gemini API**) atrás de uma interface agnóstica (`AiServiceProvider`), com execução das chamadas orquestradas pelo backend e respostas estruturadas em JSON Schema validadas antes de qualquer persistência.

## Consequências
- **Positivas**:
  - Compartilhamento de mais de 90% do código entre mobile e desktop.
  - O motor de cálculo pedagógico pode ser testado com velocidade milissegunda em testes unitários puros de Dart.
  - Garantia de funcionamento offline pleno para o professor.
  - Segurança aprimorada, mantendo chaves de API restritas ao backend.
- **Riscos e Mitigações**:
  - *Diferenças de comportamento entre plataformas desktop e mobile*: Mitigado por testes automatizados em ambiente CI e arquitetura com adaptadores isolados.
  - *Complexidade da sincronização local-first*: Mitigado pelo uso de UUIDs, timestamps imutáveis e controle de revisões com resolução explícita de conflitos.
