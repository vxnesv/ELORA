-- Execute como ADMIN usando SQLcl ou SQL*Plus.
-- O comando ACCEPT solicita a senha sem grava-la neste arquivo.

ACCEPT elora_runtime_password CHAR PROMPT 'Senha forte para ELORA_RUNTIME: ' HIDE

CREATE USER elora_runtime
    IDENTIFIED BY "&elora_runtime_password"
    DEFAULT TABLESPACE data
    TEMPORARY TABLESPACE temp
    QUOTA 0 ON data
    ACCOUNT UNLOCK;

GRANT CREATE SESSION TO elora_runtime;
GRANT EXECUTE ON elora_app.elora_api TO elora_runtime;

-- Nenhuma permissao de CREATE, ALTER, DROP ou SELECT direto e concedida.
-- Leituras futuras devem ser expostas por views ou rotinas especificas.

UNDEFINE elora_runtime_password

