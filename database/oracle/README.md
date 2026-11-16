# Banco Oracle da ELORA

O Oracle Autonomous AI Database armazena os dados funcionais da primeira versão. O aplicativo Flutter nunca se conecta diretamente ao banco: a API valida o token Firebase, obtém o `uid` autenticado e só então chama as rotinas PL/SQL.

## Estado atual

- Banco: `ELORA`, criado no Oracle Autonomous AI Database.
- Schema da aplicação: `ELORA_APP`.
- Oito tabelas e o pacote `ELORA_API` foram criados.
- A validação transacional foi executada com sucesso no ambiente remoto.
- O wallet deve permanecer fora do repositório e nunca ser enviado ao GitHub.

## Ordem de execução

Conectado como `ELORA_APP`, execute:

```sql
@01_schema.sql
@02_routines.sql
@03_validation.sql
```

O último script cria dados temporários, testa perfil, registro de saúde, meta, tarefa e resumo diário e executa `ROLLBACK`. Nenhum dado de validação permanece no banco.

Depois, conectado como `ADMIN` por SQLcl ou SQL*Plus, execute `04_runtime_security.sql`. Ele solicita uma senha sem gravá-la no arquivo e cria `ELORA_RUNTIME` apenas com sessão e execução do pacote. A API não deve usar `ADMIN` nem o proprietário `ELORA_APP`.

Para a parte 4, execute conectado como `ELORA_APP`, nesta ordem:

```sql
@05_connected_care.sql
@06_connected_care_routines.sql
@07_connected_care_validation.sql
```

`05_connected_care.sql` acrescenta o perfil opcional de cuidado, observações importadas, refeições/insulina, agenda de medicamentos e ciclo menstrual. Ele não deve ser executado novamente após criar as tabelas. O pacote `ELORA_CARE_API` não executa `COMMIT`; a transação pertence ao backend. A validação usa dados sintéticos, verifica idempotência e isolamento entre dois usuários e termina em `ROLLBACK`.

Por último, conectado como `ADMIN`, execute `08_connected_care_runtime_grant.sql` para permitir que `ELORA_RUNTIME` execute somente o novo pacote. O workflow não armazena credenciais administrativas.

`09_runtime_validation.sql`, conectado como `ELORA_RUNTIME`, comprova que o backend consegue chamar os pacotes e que uma consulta direta às tabelas é bloqueada. O teste também termina em `ROLLBACK`.

## Conexão da API

Descompacte o wallet em uma pasta privada da máquina e informe à API por variáveis de ambiente. Não coloque arquivos `.sso`, `.p12`, `.pem`, `.jks`, senhas ou credenciais Firebase dentro deste projeto.

O endereço JDBC segue este formato:

```text
jdbc:oracle:thin:@<servico_tns>?TNS_ADMIN=<pasta_do_wallet>
```

Os nomes exatos dos serviços ficam em `tnsnames.ora`. Para desenvolvimento, prefira o serviço `_low` ou `_medium`; `_high` não é necessário para o MVP.
