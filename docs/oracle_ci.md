# Validação Oracle pelo GitHub Actions

O workflow `Oracle validation` conecta ao Autonomous AI Database com SQLcl e wallet mTLS. Ele é iniciado manualmente e usa o Environment `oracle-validation`, evitando acesso ao banco em todo push ou pull request.

## Secrets necessários

Crie o Environment `oracle-validation` no repositório e adicione:

- `ORACLE_DB_USER`: `ELORA_APP`.
- `ORACLE_DB_PASSWORD`: senha do schema `ELORA_APP`.
- `ORACLE_DB_SERVICE`: alias `_low` existente no `tnsnames.ora`, por exemplo `elora_low`.
- `ORACLE_WALLET_B64`: conteúdo Base64 do arquivo `Wallet_ELORA.zip`.

Não use `ADMIN` no workflow. Como proprietário do pacote, `ELORA_APP` executa a concessão mínima contida em `08_connected_care_runtime_grant.sql`; `ELORA_RUNTIME` não recebe acesso direto às tabelas.

## Primeira execução

Em **Actions > Oracle validation > Run workflow**, marque `apply_schema_migration`. O job executará:

1. `05_connected_care.sql` para criar as tabelas;
2. `06_connected_care_routines.sql` para criar ou atualizar `ELORA_CARE_API`;
3. `08_connected_care_runtime_grant.sql` para conceder somente execução ao usuário da API;
4. `07_connected_care_validation.sql` para testar idempotência, resumos e isolamento entre usuários.

O script de validação sempre termina em `ROLLBACK`. A criação das tabelas e do pacote é DDL e permanece no banco.

## Execuções seguintes

Deixe `apply_schema_migration` desmarcado. A migração `05` não é repetível; o pacote `06` pode ser recompilado e o teste `07` pode ser executado quantas vezes forem necessárias.

O Environment pode exigir aprovação antes de liberar os secrets. Isso evita que uma alteração no workflow acesse o banco sem revisão.
