-- Automacoes PL/SQL da ELORA. O Firebase UID recebido pela API vincula todas
-- as operacoes ao principal autenticado, sem aceitar um profile_id do cliente.

CREATE OR REPLACE PACKAGE elora_api AS
    PROCEDURE upsert_profile (
        p_firebase_uid IN VARCHAR2,
        p_display_name IN VARCHAR2,
        p_profile_id OUT NUMBER
    );

    PROCEDURE add_health_record (
        p_firebase_uid IN VARCHAR2,
        p_indicator_code IN VARCHAR2,
        p_value_number IN NUMBER,
        p_recorded_at IN TIMESTAMP WITH TIME ZONE,
        p_record_id OUT NUMBER
    );

    PROCEDURE set_goal_checkin (
        p_firebase_uid IN VARCHAR2,
        p_goal_id IN NUMBER,
        p_day IN DATE,
        p_done IN NUMBER
    );

    PROCEDURE set_task_done (
        p_firebase_uid IN VARCHAR2,
        p_task_id IN NUMBER,
        p_done IN NUMBER
    );

    PROCEDURE daily_summary (
        p_firebase_uid IN VARCHAR2,
        p_day IN DATE,
        p_record_count OUT NUMBER,
        p_completed_goals OUT NUMBER,
        p_completed_tasks OUT NUMBER
    );
END elora_api;
/

CREATE OR REPLACE PACKAGE BODY elora_api AS
    FUNCTION get_profile_id (
        p_firebase_uid IN VARCHAR2
    ) RETURN NUMBER IS
        v_profile_id NUMBER;
    BEGIN
        SELECT profile_id
          INTO v_profile_id
          FROM elora_profile
         WHERE firebase_uid = TRIM(p_firebase_uid);
        RETURN v_profile_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20010, 'Perfil Firebase nao encontrado');
    END get_profile_id;

    PROCEDURE ensure_default_plan (
        p_profile_id IN NUMBER
    ) IS
        v_plan_id NUMBER;
    BEGIN
        SELECT MIN(plan_id)
          INTO v_plan_id
          FROM elora_protection_plan
         WHERE profile_id = p_profile_id
           AND risk_code = 'GENERAL';

        IF v_plan_id IS NULL THEN
            INSERT INTO elora_protection_plan (profile_id, risk_code, title)
            VALUES (p_profile_id, 'GENERAL', 'Meu plano de protecao')
            RETURNING plan_id INTO v_plan_id;

            INSERT INTO elora_plan_task (plan_id, title, position_number)
            VALUES (v_plan_id, 'Separar documentos essenciais', 1);
            INSERT INTO elora_plan_task (plan_id, title, position_number)
            VALUES (v_plan_id, 'Anotar contatos de confianca', 2);
            INSERT INTO elora_plan_task (plan_id, title, position_number)
            VALUES (v_plan_id, 'Revisar medicamentos de uso continuo', 3);
            INSERT INTO elora_plan_task (plan_id, title, position_number)
            VALUES (v_plan_id, 'Combinar um ponto de encontro seguro', 4);
        END IF;
    END ensure_default_plan;

    PROCEDURE upsert_profile (
        p_firebase_uid IN VARCHAR2,
        p_display_name IN VARCHAR2,
        p_profile_id OUT NUMBER
    ) IS
        v_uid VARCHAR2(128 CHAR);
        v_name VARCHAR2(80 CHAR);
    BEGIN
        v_uid := TRIM(p_firebase_uid);
        v_name := TRIM(p_display_name);

        IF v_uid IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'Firebase UID obrigatorio');
        END IF;
        IF LENGTH(v_uid) > 128 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Firebase UID excede o limite');
        END IF;
        IF v_name IS NULL THEN
            v_name := 'Usuario ELORA';
        END IF;
        IF LENGTH(v_name) > 80 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Nome excede o limite');
        END IF;

        BEGIN
            SELECT profile_id
              INTO p_profile_id
              FROM elora_profile
             WHERE firebase_uid = v_uid
               FOR UPDATE;

            UPDATE elora_profile
               SET display_name = v_name,
                   updated_at = SYSTIMESTAMP
             WHERE profile_id = p_profile_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                INSERT INTO elora_profile (firebase_uid, display_name)
                VALUES (v_uid, v_name)
                RETURNING profile_id INTO p_profile_id;
        END;

        ensure_default_plan(p_profile_id);
    END upsert_profile;

    PROCEDURE add_health_record (
        p_firebase_uid IN VARCHAR2,
        p_indicator_code IN VARCHAR2,
        p_value_number IN NUMBER,
        p_recorded_at IN TIMESTAMP WITH TIME ZONE,
        p_record_id OUT NUMBER
    ) IS
        v_profile_id NUMBER;
        v_indicator VARCHAR2(20 CHAR);
    BEGIN
        v_profile_id := get_profile_id(p_firebase_uid);
        v_indicator := UPPER(TRIM(p_indicator_code));

        IF v_indicator IS NULL OR v_indicator NOT IN
            ('HYDRATION', 'SLEEP', 'HEART_RATE') THEN
            RAISE_APPLICATION_ERROR(-20004, 'Indicador desconhecido');
        END IF;
        IF p_value_number IS NULL OR p_value_number <= 0 THEN
            RAISE_APPLICATION_ERROR(-20005, 'Valor deve ser positivo');
        END IF;

        INSERT INTO elora_health_record (
            profile_id, indicator_code, value_number, recorded_at, source_code
        ) VALUES (
            v_profile_id,
            v_indicator,
            p_value_number,
            NVL(p_recorded_at, SYSTIMESTAMP),
            'MANUAL'
        ) RETURNING record_id INTO p_record_id;
    END add_health_record;

    PROCEDURE set_goal_checkin (
        p_firebase_uid IN VARCHAR2,
        p_goal_id IN NUMBER,
        p_day IN DATE,
        p_done IN NUMBER
    ) IS
        v_count NUMBER;
        v_day DATE;
    BEGIN
        IF p_done IS NULL OR p_done NOT IN (0, 1) THEN
            RAISE_APPLICATION_ERROR(-20006, 'Concluido deve ser 0 ou 1');
        END IF;
        IF p_day IS NULL THEN
            RAISE_APPLICATION_ERROR(-20007, 'Data obrigatoria');
        END IF;

        SELECT COUNT(*)
          INTO v_count
          FROM elora_care_goal goal
          JOIN elora_profile profile ON profile.profile_id = goal.profile_id
         WHERE goal.goal_id = p_goal_id
           AND profile.firebase_uid = TRIM(p_firebase_uid);

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20008, 'Meta nao encontrada para o usuario');
        END IF;

        v_day := TRUNC(p_day);
        IF p_done = 1 THEN
            MERGE INTO elora_goal_checkin target
            USING (
                SELECT p_goal_id AS goal_id, v_day AS completed_on FROM dual
            ) source
            ON (
                target.goal_id = source.goal_id
                AND target.completed_on = source.completed_on
            )
            WHEN NOT MATCHED THEN
                INSERT (goal_id, completed_on)
                VALUES (source.goal_id, source.completed_on);
        ELSE
            DELETE FROM elora_goal_checkin
             WHERE goal_id = p_goal_id
               AND completed_on = v_day;
        END IF;
    END set_goal_checkin;

    PROCEDURE set_task_done (
        p_firebase_uid IN VARCHAR2,
        p_task_id IN NUMBER,
        p_done IN NUMBER
    ) IS
        v_count NUMBER;
    BEGIN
        IF p_done IS NULL OR p_done NOT IN (0, 1) THEN
            RAISE_APPLICATION_ERROR(-20006, 'Concluido deve ser 0 ou 1');
        END IF;

        SELECT COUNT(*)
          INTO v_count
          FROM elora_plan_task task
          JOIN elora_protection_plan plan ON plan.plan_id = task.plan_id
          JOIN elora_profile profile ON profile.profile_id = plan.profile_id
         WHERE task.task_id = p_task_id
           AND profile.firebase_uid = TRIM(p_firebase_uid);

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20009, 'Item nao encontrado para o usuario');
        END IF;

        UPDATE elora_plan_task
           SET completed_at = CASE
                   WHEN p_done = 1 THEN NVL(completed_at, SYSTIMESTAMP)
                   ELSE NULL
               END,
               updated_at = SYSTIMESTAMP
         WHERE task_id = p_task_id;
    END set_task_done;

    PROCEDURE daily_summary (
        p_firebase_uid IN VARCHAR2,
        p_day IN DATE,
        p_record_count OUT NUMBER,
        p_completed_goals OUT NUMBER,
        p_completed_tasks OUT NUMBER
    ) IS
        v_profile_id NUMBER;
    BEGIN
        IF p_day IS NULL THEN
            RAISE_APPLICATION_ERROR(-20007, 'Data obrigatoria');
        END IF;
        v_profile_id := get_profile_id(p_firebase_uid);

        SELECT COUNT(*)
          INTO p_record_count
          FROM elora_health_record
         WHERE profile_id = v_profile_id
           AND TRUNC(CAST(recorded_at AS DATE)) = TRUNC(p_day);

        SELECT COUNT(*)
          INTO p_completed_goals
          FROM elora_goal_checkin checkin
          JOIN elora_care_goal goal ON goal.goal_id = checkin.goal_id
         WHERE goal.profile_id = v_profile_id
           AND checkin.completed_on = TRUNC(p_day);

        SELECT COUNT(*)
          INTO p_completed_tasks
          FROM elora_plan_task task
          JOIN elora_protection_plan plan ON plan.plan_id = task.plan_id
         WHERE plan.profile_id = v_profile_id
           AND task.completed_at IS NOT NULL;
    END daily_summary;
END elora_api;
/
