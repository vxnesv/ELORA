# ELORA API

API Spring Boot que valida a identidade Firebase antes de acessar o Oracle. O aplicativo nunca recebe a senha do banco e nunca seleciona livremente outro perfil.

## Segredos necessários

Configure no ambiente, sem gravar valores reais no repositório:

- `GOOGLE_APPLICATION_CREDENTIALS`: conta de serviço do Firebase.
- `ORACLE_JDBC_URL`: serviço do wallet Oracle.
- `ORACLE_USERNAME`: use `ELORA_RUNTIME`.
- `ORACLE_PASSWORD`: senha criada ao executar `04_runtime_security.sql`.
- `ELORA_FIELD_ENCRYPTION_KEY`: chave AES de 32 bytes em Base64.
- `CORS_ALLOWED_ORIGINS`: origens exatas permitidas em produção.

Para gerar uma chave temporária de desenvolvimento no PowerShell:

```powershell
$eloraKey = New-Object byte[] 32
[Security.Cryptography.RandomNumberGenerator]::Fill($eloraKey)
$env:ELORA_FIELD_ENCRYPTION_KEY = [Convert]::ToBase64String($eloraKey)
```

Em produção, injete a chave por OCI Vault ou outro gerenciador de segredos. Não reutilize a chave de desenvolvimento.

## Executar

Com Java 21 ou superior e Maven:

```powershell
mvn test
mvn spring-boot:run
```

O endpoint público `GET /api/v1/health` serve apenas para verificar a disponibilidade. Todas as demais rotas exigem `Authorization: Bearer <token Firebase>`.

## Criptografia de campos

`SensitiveDataCipher` usa AES-256-GCM, nonce aleatório e dados adicionais autenticados. O contexto deve combinar UID e campo, por exemplo `uid:consultation-note`; uma cifra não pode ser movida para outro usuário ou tipo de dado sem falhar na autenticação.

