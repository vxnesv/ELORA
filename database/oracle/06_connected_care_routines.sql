-- Automacoes PL/SQL da parte 4 da ELORA.
-- Execute como ELORA_APP depois de 05_connected_care.sql.
-- O pacote nao executa COMMIT: a API controla a transacao.

CREATE OR REPLACE PACKAGE elora_care_api AS
    PROCEDURE upsert_care_profile (
        p_firebase_uid IN VARCHAR2,
        p_diabetes_enabled IN CHAR,
        p_hypertension_enabled IN CHAR,
        p_cycle_enabled IN CHAR,
        p_meal_reminder_hours IN NUMBER
    );

    PROCEDURE add_health_observation (
        p_firebase_uid IN VARCHAR2,
        p_metric_code IN VARCHAR2,
        p_value_number IN NUMBER,
        p_unit_code IN VARCHAR2,
        p_source_code IN VARCHAR2,
        p_external_id IN VARCHAR2,
        p_source_name IN VARCHAR2,
        p_recorded_at IN TIMESTAMP WITH TIME ZONE,
        p_observation_id OUT NUMBER
    );

    PROCEDURE add_routine_event (
        p_firebase_uid IN VARCHAR2,
        p_event_code IN VARCHAR2,
        p_value_number IN NUMBER,
        p_recorded_at IN TIMESTAMP WITH TIME ZONE,
        p_event_id OUT NUMBER
    );

    PROCEDURE add_medication (
        p_firebase_uid IN VARCHAR2,
        p_encrypted_name IN CLOB,
        p_schedule_minutes IN NUMBER,
        p_medication_id OUT NUMBER
    );

    PROCEDURE confirm_medication (
        p_firebase_uid IN VARCHAR2,
        p_medication_id IN NUMBER,
        p_confirmed_at IN TIMESTAMP WITH TIME ZONE
    );

    PROCEDURE set_medication_active (
        p_firebase_uid IN VARCHAR2,
        p_medication_id IN NUMBER,
        p_active IN CHAR
    );

    PROCEDURE add_cycle_event (
        p_firebase_uid IN VARCHAR2,
        p_event_code IN VARCHAR2,
        p_encrypted_description IN CLOB,
        p_recorded_at IN TIMESTAMP WITH TIME ZONE,
        p_cycle_event_id OUT NUMBER
    );

    PROCEDURE care_summary (
        p_firebase_uid IN VARCHAR2,
        p_day IN DATE,
        p_observation_count OUT NUMBER,
        p_routine_event_count OUT NUMBER,
        p_medication_confirmation_count OUT NUMBER,
        p_cycle_event_count OUT NUMBER
    );

    PROCEDURE open_care_snapshot (
        p_firebase_uid IN VARCHAR2,
        p_profile OUT SYS_REFCURSOR,
        p_observations OUT SYS_REFCURSOR,
        p_routine_events OUT SYS_REFCURSOR,
        p_medications OUT SYS_REFCURSOR,
        p_cycle_events OUT SYS_REFCURSOR
    );
END elora_care_api;
/

CREATE OR REPLACE PACKAGE BODY elora_care_api AS
    FUNCTION get_profile_id (
        p_firebase_uid IN VARCHAR2
    ) RETURN NUMBER IS
        v_profile_id NUMBER;
    BEGIN
        IF TRIM(p_firebase_uid) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20101, 'Firebase UID obrigatorio');
        END IF;

        SELECT profile_id
          INTO v_profile_id
          FROM elora_profile
         WHERE firebase_uid = TRIM(p_firebase_uid);
        RETURN v_profile_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20102, 'Perfil Firebase nao encontrado');
    END get_profile_id;

    FUNCTION normalized_flag (
        p_value IN CHAR,
        p_field_name IN VARCHAR2
    ) RETURN CHAR IS
        v_value CHAR(1 CHAR);
    BEGIN
        v_value := UPPER(TRIM(p_value));
        IF v_value IS NULL OR v_value NOT IN ('Y', 'N') THEN
            RAISE_APPLICATION_ERROR(-20103, p_field_name || ' deve ser Y ou N');
        END IF;
        RETURN v_value;
    END normalized_flag;

    PROCEDURE assert_medication_owner (
        p_profile_id IN NUMBER,
        p_medication_id IN NUMBER
    ) IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_count
          FROM elora_medication_schedule
         WHERE medication_id = p_medication_id
           AND profile_id = p_profile_id;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20104, 'Medicamento nao encontrado para o usuario');
        END IF;
    END assert_medication_owner;

    PROCEDURE upsert_care_profile (
        p_firebase_uid IN VARCHAR2,
        p_diabetes_enabled IN CHAR,
        p_hypertension_enabled IN CHAR,
        p_cycle_enabled IN CHAR,
        p_meal_reminder_hours IN NUMBER
    ) IS
        v_profile_id NUMBER;
        v_diabetes CHAR(1 CHAR);
        v_hypertension CHAR(1 CHAR);
        v_cycle CHAR(1 CHAR);
    BEGIN
        v_profile_id := get_profile_id(p_firebase_uid);
        v_diabetes := normalized_flag(p_diabetes_enabled, 'Diabetes');
        v_hypertension := normalized_flag(p_hypertension_enabled, 'Hipertensao');
        v_cycle := normalized_flag(p_cycle_enabled, 'Ciclo');

        IF p_meal_reminder_hours IS NULL
           OR p_meal_reminder_hours < 2
           OR p_meal_reminder_hours > 8
           OR p_meal_reminder_hours <> TRUNC(p_meal_reminder_hours) THEN
            RAISE_APPLICATION_ERROR(-20105, 'Intervalo de refeicao deve ser inteiro entre 2 e 8');
        END IF;

        MERGE INTO elora_care_profile target
        USING (
            SELECT v_profile_id profile_id FROM dual
        ) source
        ON (target.profile_id = source.profile_id)
        WHEN MATCHED THEN UPDATE SET
            diabetes_enabled = v_diabetes,
            hypertension_enabled = v_hypertension,
            cycle_enabled = v_cycle,
            meal_reminder_hours = p_meal_reminder_hours,
            updated_at = SYSTIMESTAMP
        WHEN NOT MATCHED THEN INSERT (
            profile_id,
            diabetes_enabled,
            hypertension_enabled,
            cycle_enabled,
            meal_reminder_hours
        ) VALUES (
            v_profile_id,
            v_diabetes,
            v_hypertension,
            v_cycle,
            p_meal_reminder_hours
        );
    END upsert_care_profile;

    PROCEDURE add_health_observation (
        p_firebase_uid IN VARCHAR2,
        p_metric_code IN VARCHAR2,
        p_value_number IN NUMBER,
        p_unit_code IN VARCHAR2,
        p_source_code IN VARCHAR2,
        p_external_id IN VARCHAR2,
        p_source_name IN VARCHAR2,
        p_recorded_at IN TIMESTAMP WITH TIME ZONE,
        p_observation_id OUT NUMBER
    ) IS
        v_profile_id NUMBER;
        v_metric VARCHAR2(30 CHAR);
        v_unit VARCHAR2(20 CHAR);
        v_source VARCHAR2(20 CHAR);
        v_external_id VARCHAR2(200 CHAR);
        v_source_name VARCHAR2(120 CHAR);
    BEGIN
        v_profile_id := get_profile_id(p_firebase_uid);
        v_metric := UPPER(TRIM(p_metric_code));
        v_unit := UPPER(TRIM(p_unit_code));
        v_source := UPPER(TRIM(p_source_code));
        v_external_id := TRIM(p_external_id);
        v_source_name := TRIM(p_source_name);

        IF v_metric IS NULL OR v_metric NOT IN (
            'HEART_RATE', 'RESTING_HEART_RATE', 'BLOOD_GLUCOSE',
            'BLOOD_PRESSURE_SYSTOLIC', 'BLOOD_PRESSURE_DIASTOLIC'
        ) THEN
            RAISE_APPLICATION_ERROR(-20106, 'Metrica desconhecida');
        END IF;
        IF p_value_number IS NULL OR p_value_number <= 0 OR p_value_number > 10000 THEN
            RAISE_APPLICATION_ERROR(-20107, 'Valor da metrica invalido');
        END IF;
        IF (v_metric IN ('HEART_RATE', 'RESTING_HEART_RATE') AND v_unit <> 'BPM')
           OR (v_metric = 'BLOOD_GLUCOSE' AND v_unit <> 'MG/DL')
           OR (v_metric IN ('BLOOD_PRESSURE_SYSTOLIC', 'BLOOD_PRESSURE_DIASTOLIC')
               AND v_unit <> 'MMHG') THEN
            RAISE_APPLICATION_ERROR(-20108, 'Unidade incompativel com a metrica');
        END IF;
        IF v_source IS NULL
           OR v_source NOT IN ('MANUAL', 'HEALTH_CONNECT', 'HEALTH_KIT') THEN
            RAISE_APPLICATION_ERROR(-20109, 'Origem desconhecida');
        END IF;
        IF v_external_id IS NOT NULL AND LENGTH(v_external_id) > 200 THEN
            RAISE_APPLICATION_ERROR(-20110, 'Identificador externo excede o limite');
        END IF;
        IF v_source_name IS NOT NULL AND LENGTH(v_source_name) > 120 THEN
            RAISE_APPLICATION_ERROR(-20111, 'Nome da origem excede o limite');
        END IF;

        IF v_external_id IS NOT NULL THEN
            BEGIN
                SELECT observation_id
                  INTO p_observation_id
                  FROM elora_health_observation
                 WHERE profile_id = v_profile_id
                   AND source_code = v_source
                   AND external_id = v_external_id;
                RETURN;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN NULL;
            END;
        END IF;

        BEGIN
            INSERT INTO elora_health_observation (
                profile_id, metric_code, value_number, unit_code, source_code,
                external_id, source_name, recorded_at
            ) VALUES (
                v_profile_id, v_metric, p_value_number, v_unit, v_source,
                v_external_id, v_source_name, NVL(p_recorded_at, SYSTIMESTAMP)
            ) RETURNING observation_id INTO p_observation_id;
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                SELECT observation_id
                  INTO p_observation_id
                  FROM elora_health_observation
                 WHERE profile_id = v_profile_id
                   AND source_code = v_source
                   AND external_id = v_external_id;
        END;
    END add_health_observation;

    PROCEDURE add_routine_event (
        p_firebase_uid IN VARCHAR2,
        p_event_code IN VARCHAR2,
        p_value_number IN NUMBER,
        p_recorded_at IN TIMESTAMP WITH TIME ZONE,
        p_event_id OUT NUMBER
    ) IS
        v_profile_id NUMBER;
        v_event VARCHAR2(20 CHAR);
        v_unit VARCHAR2(20 CHAR);
    BEGIN
        v_profile_id := get_profile_id(p_firebase_uid);
        v_event := UPPER(TRIM(p_event_code));

        IF v_event = 'MEAL' THEN
            IF p_value_number IS NOT NULL THEN
                RAISE_APPLICATION_ERROR(-20112, 'Refeicao nao recebe quantidade');
            END IF;
            v_unit := NULL;
        ELSIF v_event = 'INSULIN' THEN
            IF p_value_number IS NULL OR p_value_number <= 0 OR p_value_number > 1000 THEN
                RAISE_APPLICATION_ERROR(-20113, 'Quantidade de insulina invalida');
            END IF;
            v_unit := 'IU';
        ELSE
            RAISE_APPLICATION_ERROR(-20114, 'Evento de rotina desconhecido');
        END IF;

        INSERT INTO elora_routine_event (
            profile_id, event_code, value_number, unit_code, recorded_at
        ) VALUES (
            v_profile_id, v_event, p_value_number, v_unit,
            NVL(p_recorded_at, SYSTIMESTAMP)
        ) RETURNING event_id INTO p_event_id;
    END add_routine_event;

    PROCEDURE add_medication (
        p_firebase_uid IN VARCHAR2,
        p_encrypted_name IN CLOB,
        p_schedule_minutes IN NUMBER,
        p_medication_id OUT NUMBER
    ) IS
        v_profile_id NUMBER;
    BEGIN
        v_profile_id := get_profile_id(p_firebase_uid);
        IF p_encrypted_name IS NULL OR DBMS_LOB.GETLENGTH(p_encrypted_name) = 0 THEN
            RAISE_APPLICATION_ERROR(-20115, 'Nome cifrado obrigatorio');
        END IF;
        IF DBMS_LOB.GETLENGTH(p_encrypted_name) > 4000 THEN
            RAISE_APPLICATION_ERROR(-20116, 'Nome cifrado excede o limite');
        END IF;
        IF p_schedule_minutes IS NULL
           OR p_schedule_minutes < 0
           OR p_schedule_minutes > 1439
           OR p_schedule_minutes <> TRUNC(p_schedule_minutes) THEN
            RAISE_APPLICATION_ERROR(-20117, 'Horario deve estar entre 0 e 1439 minutos');
        END IF;

        INSERT INTO elora_medication_schedule (
            profile_id, encrypted_name, schedule_minutes
        ) VALUES (
            v_profile_id, p_encrypted_name, p_schedule_minutes
        ) RETURNING medication_id INTO p_medication_id;
    END add_medication;

    PROCEDURE confirm_medication (
        p_firebase_uid IN VARCHAR2,
        p_medication_id IN NUMBER,
        p_confirmed_at IN TIMESTAMP WITH TIME ZONE
    ) IS
        v_profile_id NUMBER;
    BEGIN
        v_profile_id := get_profile_id(p_firebase_uid);
        assert_medication_owner(v_profile_id, p_medication_id);

        UPDATE elora_medication_schedule
           SET last_confirmation = NVL(p_confirmed_at, SYSTIMESTAMP),
               updated_at = SYSTIMESTAMP
         WHERE medication_id = p_medication_id
           AND profile_id = v_profile_id;
    END confirm_medication;

    PROCEDURE set_medication_active (
        p_firebase_uid IN VARCHAR2,
        p_medication_id IN NUMBER,
        p_active IN CHAR
    ) IS
        v_profile_id NUMBER;
        v_active CHAR(1 CHAR);
    BEGIN
        v_profile_id := get_profile_id(p_firebase_uid);
        v_active := normalized_flag(p_active, 'Ativo');
        assert_medication_owner(v_profile_id, p_medication_id);

        UPDATE elora_medication_schedule
           SET active = v_active,
               updated_at = SYSTIMESTAMP
         WHERE medication_id = p_medication_id
           AND profile_id = v_profile_id;
    END set_medication_active;

    PROCEDURE add_cycle_event (
        p_firebase_uid IN VARCHAR2,
        p_event_code IN VARCHAR2,
        p_encrypted_description IN CLOB,
        p_recorded_at IN TIMESTAMP WITH TIME ZONE,
        p_cycle_event_id OUT NUMBER
    ) IS
        v_profile_id NUMBER;
        v_event VARCHAR2(20 CHAR);
    BEGIN
        v_profile_id := get_profile_id(p_firebase_uid);
        v_event := UPPER(TRIM(p_event_code));
        IF v_event IS NULL
           OR v_event NOT IN ('PERIOD_START', 'PERIOD_END', 'SYMPTOM') THEN
            RAISE_APPLICATION_ERROR(-20118, 'Evento de ciclo desconhecido');
        END IF;
        IF p_encrypted_description IS NOT NULL
           AND DBMS_LOB.GETLENGTH(p_encrypted_description) > 8000 THEN
            RAISE_APPLICATION_ERROR(-20119, 'Descricao cifrada excede o limite');
        END IF;

        INSERT INTO elora_cycle_event (
            profile_id, event_code, encrypted_description, recorded_at
        ) VALUES (
            v_profile_id, v_event, p_encrypted_description,
            NVL(p_recorded_at, SYSTIMESTAMP)
        ) RETURNING cycle_event_id INTO p_cycle_event_id;
    END add_cycle_event;

    PROCEDURE care_summary (
        p_firebase_uid IN VARCHAR2,
        p_day IN DATE,
        p_observation_count OUT NUMBER,
        p_routine_event_count OUT NUMBER,
        p_medication_confirmation_count OUT NUMBER,
        p_cycle_event_count OUT NUMBER
    ) IS
        v_profile_id NUMBER;
        v_day DATE;
    BEGIN
        IF p_day IS NULL THEN
            RAISE_APPLICATION_ERROR(-20120, 'Data obrigatoria');
        END IF;
        v_profile_id := get_profile_id(p_firebase_uid);
        v_day := TRUNC(p_day);

        SELECT COUNT(*) INTO p_observation_count
          FROM elora_health_observation
         WHERE profile_id = v_profile_id
           AND TRUNC(CAST(recorded_at AS DATE)) = v_day;

        SELECT COUNT(*) INTO p_routine_event_count
          FROM elora_routine_event
         WHERE profile_id = v_profile_id
           AND TRUNC(CAST(recorded_at AS DATE)) = v_day;

        SELECT COUNT(*) INTO p_medication_confirmation_count
          FROM elora_medication_schedule
         WHERE profile_id = v_profile_id
           AND last_confirmation IS NOT NULL
           AND TRUNC(CAST(last_confirmation AS DATE)) = v_day;

        SELECT COUNT(*) INTO p_cycle_event_count
          FROM elora_cycle_event
         WHERE profile_id = v_profile_id
           AND TRUNC(CAST(recorded_at AS DATE)) = v_day;
    END care_summary;

    PROCEDURE open_care_snapshot (
        p_firebase_uid IN VARCHAR2,
        p_profile OUT SYS_REFCURSOR,
        p_observations OUT SYS_REFCURSOR,
        p_routine_events OUT SYS_REFCURSOR,
        p_medications OUT SYS_REFCURSOR,
        p_cycle_events OUT SYS_REFCURSOR
    ) IS
        v_profile_id NUMBER;
    BEGIN
        v_profile_id := get_profile_id(p_firebase_uid);

        OPEN p_profile FOR
            SELECT diabetes_enabled, hypertension_enabled, cycle_enabled,
                   meal_reminder_hours, updated_at
              FROM elora_care_profile
             WHERE profile_id = v_profile_id;

        OPEN p_observations FOR
            SELECT observation_id, metric_code, value_number, unit_code,
                   source_code, external_id, source_name, recorded_at
              FROM elora_health_observation
             WHERE profile_id = v_profile_id
             ORDER BY recorded_at DESC
             FETCH FIRST 500 ROWS ONLY;

        OPEN p_routine_events FOR
            SELECT event_id, event_code, value_number, unit_code, recorded_at
              FROM elora_routine_event
             WHERE profile_id = v_profile_id
             ORDER BY recorded_at DESC
             FETCH FIRST 500 ROWS ONLY;

        OPEN p_medications FOR
            SELECT medication_id, encrypted_name, schedule_minutes, active,
                   last_confirmation, created_at, updated_at
              FROM elora_medication_schedule
             WHERE profile_id = v_profile_id
             ORDER BY active DESC, schedule_minutes, medication_id;

        OPEN p_cycle_events FOR
            SELECT cycle_event_id, event_code, encrypted_description, recorded_at
              FROM elora_cycle_event
             WHERE profile_id = v_profile_id
             ORDER BY recorded_at DESC
             FETCH FIRST 500 ROWS ONLY;
    END open_care_snapshot;
END elora_care_api;
/

SHOW ERRORS PACKAGE elora_care_api;
SHOW ERRORS PACKAGE BODY elora_care_api;
