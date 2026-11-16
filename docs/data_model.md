# MER e DER da ELORA

Versão pronta para apresentação: [`output/pdf/ELORA-DER-MER.pdf`](../output/pdf/ELORA-DER-MER.pdf).

Arquivos editáveis para diagrams.net/draw.io:

- [`ELORA-DER.xml`](../output/xml/ELORA-DER.xml)
- [`ELORA-MER.xml`](../output/xml/ELORA-MER.xml)

## Modelo Entidade-Relacionamento (MER)

O usuário é identificado externamente pelo Firebase Authentication. O `firebase_uid` é único em `ELORA_PROFILE` e funciona como vínculo entre a identidade autenticada e os dados relacionais. A API obtém esse valor do token validado; o aplicativo não envia nem escolhe o perfil que deseja acessar.

Entidades principais:

- **Perfil:** identidade funcional e nome de exibição.
- **Registro de saúde:** valor informado, indicador, origem e momento do registro.
- **Meta de cuidado e check-in:** objetivo do usuário e conclusão em uma data.
- **Plano e tarefa de proteção:** preparação pessoal para riscos cotidianos e climáticos.
- **Contexto de trabalho:** ambiente predominante da rotina.
- **Anotação de consulta:** texto preparado pelo usuário para conversar com um profissional.
- **Perfil de cuidado:** ativa somente os acompanhamentos escolhidos pela pessoa.
- **Observação de saúde:** métricas manuais ou importadas com origem e horário.
- **Evento de rotina:** refeição ou aplicação de insulina registrada pela pessoa.
- **Agenda de medicamento:** horário recorrente e última confirmação, com nome cifrado no backend.
- **Evento de ciclo:** início, fim ou sintoma, com descrição cifrada quando existir.

## Diagrama Entidade-Relacionamento (DER)

```mermaid
erDiagram
    ELORA_PROFILE ||--o{ ELORA_HEALTH_RECORD : registra
    ELORA_PROFILE ||--o{ ELORA_CARE_GOAL : define
    ELORA_CARE_GOAL ||--o{ ELORA_GOAL_CHECKIN : recebe
    ELORA_PROFILE ||--o{ ELORA_PROTECTION_PLAN : possui
    ELORA_PROTECTION_PLAN ||--o{ ELORA_PLAN_TASK : organiza
    ELORA_PROFILE ||--o| ELORA_WORK_CONTEXT : informa
    ELORA_PROFILE ||--o{ ELORA_CONSULTATION_NOTE : escreve
    ELORA_PROFILE ||--o| ELORA_CARE_PROFILE : configura
    ELORA_PROFILE ||--o{ ELORA_HEALTH_OBSERVATION : acompanha
    ELORA_PROFILE ||--o{ ELORA_ROUTINE_EVENT : registra
    ELORA_PROFILE ||--o{ ELORA_MEDICATION_SCHEDULE : organiza
    ELORA_PROFILE ||--o{ ELORA_CYCLE_EVENT : acompanha

    ELORA_PROFILE {
        NUMBER profile_id PK
        VARCHAR2 firebase_uid UK
        VARCHAR2 display_name
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    ELORA_HEALTH_RECORD {
        NUMBER record_id PK
        NUMBER profile_id FK
        VARCHAR2 indicator_code
        NUMBER value_number
        TIMESTAMPTZ recorded_at
        VARCHAR2 source_code
    }
    ELORA_CARE_GOAL {
        NUMBER goal_id PK
        NUMBER profile_id FK
        VARCHAR2 title
        CHAR active
    }
    ELORA_GOAL_CHECKIN {
        NUMBER checkin_id PK
        NUMBER goal_id FK_UK
        DATE completed_on UK_COMPOSITE
    }
    ELORA_PROTECTION_PLAN {
        NUMBER plan_id PK
        NUMBER profile_id FK
        VARCHAR2 risk_code
        VARCHAR2 title
    }
    ELORA_PLAN_TASK {
        NUMBER task_id PK
        NUMBER plan_id FK
        VARCHAR2 title
        NUMBER position_number
        TIMESTAMPTZ completed_at
    }
    ELORA_WORK_CONTEXT {
        NUMBER context_id PK
        NUMBER profile_id FK_UK
        VARCHAR2 context_code
    }
    ELORA_CONSULTATION_NOTE {
        NUMBER note_id PK
        NUMBER profile_id FK
        CLOB note_text
        TIMESTAMPTZ created_at
    }
    ELORA_CARE_PROFILE {
        NUMBER profile_id PK_FK
        CHAR diabetes_enabled
        CHAR hypertension_enabled
        CHAR cycle_enabled
        NUMBER meal_reminder_hours
    }
    ELORA_HEALTH_OBSERVATION {
        NUMBER observation_id PK
        NUMBER profile_id FK
        VARCHAR2 metric_code
        NUMBER value_number
        VARCHAR2 unit_code
        VARCHAR2 source_code
        TIMESTAMPTZ recorded_at
    }
    ELORA_ROUTINE_EVENT {
        NUMBER event_id PK
        NUMBER profile_id FK
        VARCHAR2 event_code
        NUMBER value_number
        VARCHAR2 unit_code
        TIMESTAMPTZ recorded_at
    }
    ELORA_MEDICATION_SCHEDULE {
        NUMBER medication_id PK
        NUMBER profile_id FK
        CLOB encrypted_name
        NUMBER schedule_minutes
        TIMESTAMPTZ last_confirmation
    }
    ELORA_CYCLE_EVENT {
        NUMBER cycle_event_id PK
        NUMBER profile_id FK
        VARCHAR2 event_code
        CLOB encrypted_description
        TIMESTAMPTZ recorded_at
    }
```

## Regras de integridade

- Cada `firebase_uid` possui no máximo um perfil.
- Um check-in é único por meta e dia.
- Um perfil possui no máximo um contexto de trabalho atual.
- Registros aceitam apenas hidratação, sono e frequência cardíaca dentro dos limites definidos.
- Planos aceitam os riscos geral, calor, enchente e deslizamento.
- Exclusões do perfil propagam para seus dados dependentes.
- Horários de medicamentos permanecem entre 00:00 e 23:59 e a confirmação não altera dose ou prescrição.
- Observações conectadas preservam fonte e momento e evitam duplicação pelo identificador externo.
- Dados de ciclo e nomes de medicamentos ficam preparados para cifragem em nível de campo na API.

## Automações PL/SQL

O pacote `ELORA_API` automatiza a criação/atualização do perfil, o plano inicial, o registro de indicadores, a conclusão idempotente de metas, a atualização de tarefas e o resumo diário. Todas as rotinas recebem o Firebase UID validado pela API para preservar o isolamento entre usuários.

O pacote `ELORA_CARE_API` automatiza as preferências opcionais de cuidado, importação idempotente de observações, eventos de refeição/insulina, agenda e confirmação de medicamentos, eventos de ciclo, resumo diário e leitura do snapshot. Ele também resolve o perfil exclusivamente pelo Firebase UID validado. Nomes de medicamentos e descrições de sintomas devem ser cifrados pela API antes de chegar ao Oracle.

