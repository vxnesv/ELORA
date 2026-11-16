-- Validacao transacional das tabelas e automacoes da ELORA.
-- Os dados criados aqui sao revertidos ao final.

SET SERVEROUTPUT ON;

DECLARE
    v_uid VARCHAR2(128 CHAR) :=
        'validation-' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF6');
    v_profile_id NUMBER;
    v_record_id NUMBER;
    v_goal_id NUMBER;
    v_task_id NUMBER;
    v_record_count NUMBER;
    v_completed_goals NUMBER;
    v_completed_tasks NUMBER;
BEGIN
    elora_api.upsert_profile(
        p_firebase_uid => v_uid,
        p_display_name => 'Validacao ELORA',
        p_profile_id => v_profile_id
    );

    elora_api.add_health_record(
        p_firebase_uid => v_uid,
        p_indicator_code => 'HYDRATION',
        p_value_number => 1500,
        p_recorded_at => SYSTIMESTAMP,
        p_record_id => v_record_id
    );

    INSERT INTO elora_care_goal (profile_id, title)
    VALUES (v_profile_id, 'Validar meta preventiva')
    RETURNING goal_id INTO v_goal_id;

    -- A segunda chamada comprova que o check-in e idempotente.
    elora_api.set_goal_checkin(v_uid, v_goal_id, TRUNC(SYSDATE), 1);
    elora_api.set_goal_checkin(v_uid, v_goal_id, TRUNC(SYSDATE), 1);

    SELECT MIN(task.task_id)
      INTO v_task_id
      FROM elora_plan_task task
      JOIN elora_protection_plan plan ON plan.plan_id = task.plan_id
     WHERE plan.profile_id = v_profile_id;

    elora_api.set_task_done(v_uid, v_task_id, 1);

    elora_api.daily_summary(
        p_firebase_uid => v_uid,
        p_day => TRUNC(SYSDATE),
        p_record_count => v_record_count,
        p_completed_goals => v_completed_goals,
        p_completed_tasks => v_completed_tasks
    );

    IF v_record_count <> 1 THEN
        RAISE_APPLICATION_ERROR(-20991, 'Validacao falhou: total de registros');
    END IF;
    IF v_completed_goals <> 1 THEN
        RAISE_APPLICATION_ERROR(-20992, 'Validacao falhou: total de metas');
    END IF;
    IF v_completed_tasks <> 1 THEN
        RAISE_APPLICATION_ERROR(-20993, 'Validacao falhou: total de tarefas');
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'VALIDACAO OK - perfil=' || v_profile_id ||
        ', registro=' || v_record_id ||
        ', metas=' || v_completed_goals ||
        ', tarefas=' || v_completed_tasks
    );
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

