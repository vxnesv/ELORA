-- Execute como ELORA_APP (proprietario do pacote) depois de criar ELORA_CARE_API.
-- ELORA_RUNTIME continua sem SELECT, INSERT, UPDATE ou DELETE direto.

GRANT EXECUTE ON elora_app.elora_care_api TO elora_runtime;

