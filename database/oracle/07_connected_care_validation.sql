-- Validacao transacional da parte 4.
-- Cria dados sinteticos, testa isolamento entre usuarios e executa ROLLBACK.

SET SERVEROUTPUT ON;

DECLARE
    v_uid_a VARCHAR2(128 CHAR) :=
        'care-validation-a-' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF6');
    v_uid_b VARCHAR2(128 CHAR) :=
        'care-validation-b-' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF6');
    v_profile_a NUMBER;
    v_profile_b NUMBER;
    v_observation_id NUMBER;
    v_duplicate_id NUMBER;
    v_meal_id NUMBER;
    v_insulin_id NUMBER;
    v_medication_id NUMBER;
    v_cycle_start_id NUMBER;
    v_cycle_symptom_id NUMBER;
    v_observations NUMBER;
    v_routine_events NUMBER;
    v_medication_confirmations NUMBER;
    v_cycle_events NUMBER;
    v_isolation_ok NUMBER := 0;
BEGIN
    elora_api.upsert_profile(v_uid_a, 'Validacao Cuidado A', v_profile_a);
    elora_api.upsert_profile(v_uid_b, 'Validacao Cuidado B', v_profile_b);

    elora_care_api.upsert_care_profile(v_uid_a, 'Y', 'Y', 'Y', 4);

    elora_care_api.add_health_observation(
        v_uid_a, 'BLOOD_GLUCOSE', 110, 'MG/DL', 'HEALTH_CONNECT',
        'synthetic-observation-1', 'Fonte sintetica', SYSTIMESTAMP,
        v_observation_id
    );

    -- A repeticao do mesmo identificador comprova a importacao idempotente.
    elora_care_api.add_health_observation(
        v_uid_a, 'BLOOD_GLUCOSE', 110, 'MG/DL', 'HEALTH_CONNECT',
        'synthetic-observation-1', 'Fonte sintetica', SYSTIMESTAMP,
        v_duplicate_id
    );

    IF v_observation_id <> v_duplicate_id THEN
        RAISE_APPLICATION_ERROR(-20981, 'Validacao falhou: observacao duplicada');
    END IF;

    elora_care_api.add_routine_event(
        v_uid_a, 'MEAL', NULL, SYSTIMESTAMP, v_meal_id
    );
    elora_care_api.add_routine_event(
        v_uid_a, 'INSULIN', 8, SYSTIMESTAMP, v_insulin_id
    );

    -- Texto sintetico que representa um valor ja cifrado pela API.
    elora_care_api.add_medication(
        v_uid_a, TO_CLOB('enc:v1:synthetic-medication'), 570, v_medication_id
    );
    elora_care_api.confirm_medication(
        v_uid_a, v_medication_id, SYSTIMESTAMP
    );

    elora_care_api.add_cycle_event(
        v_uid_a, 'PERIOD_START', NULL, SYSTIMESTAMP, v_cycle_start_id
    );
    elora_care_api.add_cycle_event(
        v_uid_a, 'SYMPTOM', TO_CLOB('enc:v1:synthetic-symptom'),
        SYSTIMESTAMP, v_cycle_symptom_id
    );

    -- O segundo usuario nao pode alterar o medicamento do primeiro.
    BEGIN
        elora_care_api.confirm_medication(
            v_uid_b, v_medication_id, SYSTIMESTAMP
        );
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20104 THEN
                v_isolation_ok := 1;
            ELSE
                RAISE;
            END IF;
    END;

    IF v_isolation_ok <> 1 THEN
        RAISE_APPLICATION_ERROR(-20982, 'Validacao falhou: isolamento por usuario');
    END IF;

    elora_care_api.care_summary(
        v_uid_a,
        TRUNC(SYSDATE),
        v_observations,
        v_routine_events,
        v_medication_confirmations,
        v_cycle_events
    );

    IF v_observations <> 1 THEN
        RAISE_APPLICATION_ERROR(-20983, 'Validacao falhou: observacoes');
    END IF;
    IF v_routine_events <> 2 THEN
        RAISE_APPLICATION_ERROR(-20984, 'Validacao falhou: rotina');
    END IF;
    IF v_medication_confirmations <> 1 THEN
        RAISE_APPLICATION_ERROR(-20985, 'Validacao falhou: medicamentos');
    END IF;
    IF v_cycle_events <> 2 THEN
        RAISE_APPLICATION_ERROR(-20986, 'Validacao falhou: ciclo');
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'VALIDACAO CUIDADO OK - observacoes=' || v_observations ||
        ', rotina=' || v_routine_events ||
        ', medicamentos=' || v_medication_confirmations ||
        ', ciclo=' || v_cycle_events ||
        ', isolamento=OK'
    );
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

