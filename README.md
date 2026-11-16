# ELORA

[![Flutter CI](https://github.com/vxnesv/ELORA/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/vxnesv/ELORA/actions/workflows/flutter-ci.yml)
[![Oracle validation](https://github.com/vxnesv/ELORA/actions/workflows/oracle-ci.yml/badge.svg)](https://github.com/vxnesv/ELORA/actions/workflows/oracle-ci.yml)

Aplicativo Flutter de inteligência preventiva que ajuda pessoas a compreender informações do cotidiano, organizar ações de cuidado e encontrar orientações oficiais para situações de risco.

## Funcionalidades principais

- Cuidado preventivo: indicadores informados pelo usuário, metas e anotações para consulta.
- Orientação contextual: rotina de trabalho, ambiente e conteúdos preventivos.
- Proteção e preparação: checklist pessoal, guias e acesso rápido a serviços oficiais.
- Assistente educativa com atalhos para as funcionalidades correspondentes.
- Histórico e resumo descritivo para apoiar uma conversa com profissionais de saúde.
- Cuidado conectado opcional: importação autorizada de batimentos, glicemia e pressão, além de registros manuais.
- Rotinas inclusivas para diabetes, hipertensão, ciclo menstrual e medicamentos de uso contínuo.
- Alertas diários de medicamentos no celular, com conteúdo discreto na tela bloqueada.

A ELORA não realiza diagnóstico, não substitui profissionais de saúde e não funciona como serviço de emergência.

## Autenticação

O acesso utiliza Firebase Authentication com e-mail e senha. O projeto Firebase é `elora-85c35` e os identificadores Android e iOS são `br.com.elora.app`.

O Firebase é responsável pela identidade e pela sessão. Os dados funcionais serão acessados por uma API Spring Boot que validará o token Firebase e utilizará Oracle/PL-SQL. O aplicativo não acessará o banco Oracle diretamente.

## Executar

O projeto utiliza Flutter 3.50.0. No PowerShell:

```powershell
$env:Path = 'C:\tools\flutter\bin;' + $env:Path
flutter pub get
flutter run -d chrome
```

Para Android:

```powershell
flutter devices
flutter run -d <id-do-dispositivo>
```

A integração com Health Connect exige Android 8.0 (API 26) ou superior. Alertas de medicamentos pedem permissão somente quando a pessoa escolhe ativá-los; a versão Web mantém os lembretes dentro do app, pois navegadores não oferecem agendamento diário equivalente.

Validação:

```powershell
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

## Organização

```text
lib/
  core/                  modelos, estado e componentes compartilhados
  features/
    auth/                login, cadastro, sessão e recuperação de senha
    assistente/          orientação educativa
    cuidado/             indicadores, metas e consulta
    trabalho/            contexto ocupacional
    ambiente/            contexto ambiental
    protecao/            planos, guias e ajuda
    profile/             conta e preferências
    relatorios/          histórico e resumo
database/oracle/         modelo e automações PL-SQL
docs/                    arquitetura e escopo acadêmico
```

O [MER e DER descritivo](docs/data_model.md) documenta as entidades, relacionamentos e regras de integridade. A [versão diagramada em PDF](output/pdf/ELORA-DER-MER.pdf) segue o modelo acadêmico de duas páginas; os arquivos [DER em XML](output/xml/ELORA-DER.xml) e [MER em XML](output/xml/ELORA-MER.xml) podem ser editados no diagrams.net/draw.io. Os scripts Oracle foram reproduzidos e validados no Autonomous AI Database do projeto.

As decisões sobre armazenamento seguro, autenticação, criptografia e separação de privilégios estão em [Segurança e privacidade](docs/security.md).

## Fontes de orientação

- [Ministério da Saúde: ondas de calor](https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/o/ondas-de-calor)
- [Ministério da Saúde: SAMU 192](https://www.gov.br/saude/pt-br/composicao/saes/samu-192/samu-192)
- [Ministério da Saúde: enchentes e inundações](https://miniapps.saude.gov.br/guia-clima/como-podemos-contribuir/populacao-em-geral/enchentes-e-inundacoes)
- [Defesa Civil Nacional: alertas de desastres](https://www.gov.br/mdr/pt-br/assuntos/protecao-e-defesa-civil/alertas-de-desastres-1)

Os conteúdos devem ser revisados antes de cada publicação.
