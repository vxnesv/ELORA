-- Valida o usuario restrito usado pelo backend.
-- Execute conectado como ELORA_RUNTIME. Todos os dados sao revertidos.

SET SERVEROUTPUT ON;

DECLARE
    v_uid VARCHAR2(128 CHAR) :=
        'runtime-validation-' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF6');
    v_profile_id NUMBER;
    v_observation_id NUMBER;
    v_observations NUMBER;
    v_routine_events NUMBER;
    v_medication_confirmations NUMBER;
    v_cycle_events NUMBER;
    v_direct_access_blocked NUMBER := 0;
    v_count NUMBER;
BEGIN
    -- O runtime nao pode consultar diretamente uma tabela do proprietario.
    BEGIN
        EXECUTE IMMEDIATE
            'SELECT COUNT(*) FROM elora_app.elora_profile'
            INTO v_count;
        RAISE_APPLICATION_ERROR(-20971, 'Acesso direto indevido a tabela');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -942 THEN
                v_direct_access_blocked := 1;
            ELSE
                RAISE;
            END IF;
    END;

    elora_app.elora_api.upsert_profile(
        v_uid, 'Validacao Runtime', v_profile_id
    );

    elora_app.elora_care_api.upsert_care_profile(
        v_uid, 'N', 'Y', 'N', 4
    );

    elora_app.elora_care_api.add_health_observation(
        v_uid, 'BLOOD_PRESSURE_SYSTOLIC', 120, 'MMHG', 'MANUAL',
        NULL, 'Validacao sintetica', SYSTIMESTAMP, v_observation_id
    );

    elora_app.elora_care_api.care_summary(
        v_uid, TRUNC(SYSDATE), v_observations, v_routine_events,
        v_medication_confirmations, v_cycle_events
    );

    IF v_direct_access_blocked <> 1 THEN
        RAISE_APPLICATION_ERROR(-20972, 'Acesso direto nao foi bloqueado');
    END IF;
    IF v_observations <> 1 THEN
        RAISE_APPLICATION_ERROR(-20973, 'Pacote nao registrou a observacao');
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'VALIDACAO RUNTIME OK - pacotes=OK, acesso_direto=BLOQUEADO'
    );
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

