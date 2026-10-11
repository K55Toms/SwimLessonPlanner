# Database schema

SwimLessonPlanner stores its data in a dedicated schema, **`SWIMLESSONPLANNER`**, on an Oracle Autonomous Database (ADB) in OCI.

## Design principles

- **The safety gate is enforced in the database.** Every lesson plan must have a pre-water-entry safety question and talking point. `NOT NULL` and `CHECK` constraints reject plans where either is missing or blank.
- **No swimmer data.** The schema stores lesson plans, how they were delivered, and teachers' notes. It never stores individual swimmers or their achievements; those stay in the pool's tracking software.
- **Outcomes in our own words.** `OUTCOMES` holds outcome descriptions written for this app. They are aligned with the Swim England Learn to Swim stages, not copied from them.
- **The library grows from use.** AI-generated and teacher-written activities and plans are stored together. `SOURCE` records where each one came from, and `AI_GENERATIONS` keeps an audit of what Claude was asked and what it returned.
- **Sharing is opt-in.** Plans are `PRIVATE` until a teacher shares them. Delivery notes are only shared when the teacher sets `NOTES_SHARED = 'Y'`.
- **Least privilege.** The web app connects as `SLP_APP`, which can read and write rows but can't create, change or drop tables. Only the schema owner can change structure.
- **Target version: ADB 23ai / 26ai.** `02_create_app_user.sql` uses schema-level privileges (`GRANT ... ANY TABLE ON SCHEMA`), which need 23ai or later.

## Entity relationship diagram

```mermaid
erDiagram
    TEACHERS ||--o{ LESSON_PLANS : writes
    TEACHERS ||--o{ ACTIVITIES : writes
    TEACHERS ||--o{ AI_GENERATIONS : requests
    TEACHERS ||--o{ TERM_BLOCKS : owns
    TEACHERS ||--o{ LESSON_DELIVERIES : records

    STAGES ||--o{ OUTCOMES : has
    STAGES ||--o{ LESSON_PLANS : "planned for"
    STAGES ||--o{ ACTIVITY_STAGES : ""
    STAGES ||--o{ TERM_BLOCKS : ""

    ACTIVITIES ||--o{ ACTIVITY_STAGES : "suits"
    ACTIVITIES ||--o{ ACTIVITY_OUTCOMES : "develops"
    OUTCOMES ||--o{ ACTIVITY_OUTCOMES : ""

    LESSON_PLANS ||--o{ LESSON_PLAN_OUTCOMES : targets
    OUTCOMES ||--o{ LESSON_PLAN_OUTCOMES : ""
    LESSON_PLANS ||--o{ LESSON_PLAN_SECTIONS : contains
    ACTIVITIES |o--o{ LESSON_PLAN_SECTIONS : "used in"
    LESSON_PLANS |o--o{ LESSON_PLANS : "based on"

    AI_GENERATIONS |o--o{ LESSON_PLANS : produced
    AI_GENERATIONS |o--o{ ACTIVITIES : produced

    TERM_BLOCKS ||--o{ TERM_BLOCK_LESSONS : sequences
    LESSON_PLANS ||--o{ TERM_BLOCK_LESSONS : ""
    LESSON_PLANS ||--o{ LESSON_DELIVERIES : "delivered as"
    TERM_BLOCKS |o--o{ LESSON_DELIVERIES : ""
```

## Tables

### Reference data

| Table | Purpose | Key columns |
|---|---|---|
| `STAGES` | Learn to Swim stages. Stages 1–7 are seeded. | `STAGE_NUMBER` (PK), `TITLE`, `SUMMARY` |
| `TEACHERS` | Qualified teacher accounts | `TEACHER_ID`, `EMAIL` (unique), `DISPLAY_NAME`, `AUTH_SUBJECT` (ID from the auth provider) |
| `OUTCOMES` | Outcomes per stage, in the app's own words | `OUTCOME_ID`, `STAGE_NUMBER`, `OUTCOME_CODE` (unique within a stage), `DESCRIPTION`, `SKILL_AREA` |

### Activity library

| Table | Purpose | Key columns |
|---|---|---|
| `ACTIVITIES` | Reusable activities for one lesson section | `SECTION_TYPE`, `TITLE`, `DESCRIPTION`, `EQUIPMENT`, `TEACHING_POINTS`, `DIFFERENTIATION`, `SAFETY_NOTES`, `SOURCE`, `STATUS` |
| `ACTIVITY_STAGES` | Stages an activity suits (many-to-many) | `ACTIVITY_ID`, `STAGE_NUMBER` |
| `ACTIVITY_OUTCOMES` | Outcomes an activity develops (many-to-many) | `ACTIVITY_ID`, `OUTCOME_ID` |

### Lesson plans

| Table | Purpose | Key columns |
|---|---|---|
| `LESSON_PLANS` | Plan header and the plan-level fields | `STAGE_NUMBER`, `TITLE`, `SAFETY_QUESTION`*, `SAFETY_TALKING_POINT`*, `EQUIPMENT`, `TEACHING_POINTS`, `DIFFERENTIATION`, `SAFETY_NOTES`, `VISIBILITY`, `STATUS`, `BASED_ON_PLAN_ID` |
| `LESSON_PLAN_OUTCOMES` | Outcomes the plan targets | `PLAN_ID`, `OUTCOME_ID` |
| `LESSON_PLAN_SECTIONS` | Ordered activity slots: warm-up, main set, contrasting activity, game, cool-down | `SECTION_TYPE`, `SEQUENCE_NO`, `ACTIVITY_ID` (optional), `INSTRUCTIONS`, `DURATION_MINUTES` |

\* Required, and cannot be blank.

A section either points at a library activity (`ACTIVITY_ID`) or holds its own `INSTRUCTIONS`. At least one of the two is required. A plan can have several `MAIN_SET` rows, ordered by `SEQUENCE_NO`.

### AI audit

| Table | Purpose | Key columns |
|---|---|---|
| `AI_GENERATIONS` | One row per Claude request | `TEACHER_ID`, `REQUEST_TYPE`, `MODEL_ID`, `PROMPT`, `RESPONSE`, `STATUS`, token counts |

### Term blocks and delivery log

| Table | Purpose | Key columns |
|---|---|---|
| `TERM_BLOCKS` | A teacher's term for one group and stage | `NAME`, `GROUP_LABEL`, `START_DATE`, `END_DATE`, `PLANNED_LESSONS`, `STATUS` |
| `TERM_BLOCK_LESSONS` | Planned lesson order within a block | `BLOCK_ID`, `LESSON_NUMBER`, `PLAN_ID` |
| `LESSON_DELIVERIES` | A plan was used on a given date, with optional notes | `PLAN_ID`, `BLOCK_ID` (optional), `DELIVERED_ON`, `RATING` (1–5), `NOTES`, `NOTES_SHARED` |

## Allowed values

| Column | Values |
|---|---|
| `SECTION_TYPE` | `WARM_UP`, `MAIN_SET`, `CONTRASTING`, `GAME`, `COOL_DOWN` |
| `SOURCE` | `TEACHER`, `AI_CLAUDE`, `AI_EDITED` (AI output that a teacher has changed) |
| `ACTIVITIES.STATUS` | `DRAFT`, `PUBLISHED`, `RETIRED` |
| `LESSON_PLANS.STATUS` | `DRAFT`, `READY`, `ARCHIVED` |
| `LESSON_PLANS.VISIBILITY` | `PRIVATE`, `SHARED` |
| `TERM_BLOCKS.STATUS` | `PLANNING`, `ACTIVE`, `COMPLETE` |
| `AI_GENERATIONS.REQUEST_TYPE` | `LESSON_PLAN`, `ACTIVITY` |
| Y/N flags | `Y`, `N` |

## Conventions

- Primary keys are `NUMBER GENERATED ALWAYS AS IDENTITY`. Junction tables use composite keys.
- Timestamps are `TIMESTAMP WITH TIME ZONE` and default to `SYSTIMESTAMP`. The application sets `UPDATED_AT` on every update; there are no triggers.
- Constraint names follow the pattern `<table>_<column>_<pk|fk|uk|ck>`.
- Every foreign key column has an index, unless it already leads a primary key or unique constraint.
- Deleting a plan cascades to its sections and outcome links. A plan that has been delivered can't be deleted, so archive it instead (`STATUS = 'ARCHIVED'`).

## Database users

| Account | Type | Used by | Can do |
|---|---|---|---|
| `SWIMLESSONPLANNER` | Schema owner | You, when deploying or migrating the schema | Create, alter and drop objects in its own schema |
| `SLP_APP` | Application login | The Next.js app | `SELECT`, `INSERT`, `UPDATE` and `DELETE` on every table in `SWIMLESSONPLANNER`, through the role `SLP_APP_ROLE`. No DDL. |

`SLP_APP_ROLE` is granted with schema-level privileges, so tables added later are covered automatically.

The app has to point its sessions at the schema, because `SLP_APP` owns no tables. It can either:
- run `alter session set current_schema = swimlessonplanner` when it opens a connection, or
- qualify every table name, for example `swimlessonplanner.lesson_plans`.

**Recommended:** lock the owner account between deployments, and unlock it only when you need to change the schema:

```sql
alter user swimlessonplanner account lock;    -- after deploying
alter user swimlessonplanner account unlock;  -- before a migration
```

## Scripts

All scripts are in [`db/`](../db). Run them with SQLcl or SQL*Plus using the ADB wallet. They use `ACCEPT` prompts, which may not work in the Database Actions web SQL worksheet.

| Script | Run as | What it does |
|---|---|---|
| `00_create_schema_user.sql` | `ADMIN` | Prompts for a password, then creates the `SWIMLESSONPLANNER` user with quota on `DATA` and object-creation privileges |
| `01_create_objects.sql` | `SWIMLESSONPLANNER` | Creates all tables and indexes, and seeds Stages 1–7 |
| `02_create_app_user.sql` | `ADMIN` | Prompts for a password, then creates the role `SLP_APP_ROLE` and the login `SLP_APP` |
| `90_drop_objects.sql` | `SWIMLESSONPLANNER` | Drops all tables and data but keeps the user. Asks you to type `DROP`. Safe to re-run. |
| `99_drop_schema_user.sql` | `ADMIN` | Drops `SLP_APP`, `SLP_APP_ROLE` and `SWIMLESSONPLANNER` with everything it owns. Asks you to type `DROP SWIMLESSONPLANNER`. Irreversible. Safe to re-run. |

### Example (SQLcl)

```sh
sql -cloudconfig Wallet_<db>.zip admin@<db>_high
SQL> @db/00_create_schema_user.sql

sql -cloudconfig Wallet_<db>.zip swimlessonplanner@<db>_high
SQL> @db/01_create_objects.sql

sql -cloudconfig Wallet_<db>.zip admin@<db>_high
SQL> @db/02_create_app_user.sql
```

### Reset during development

```sh
SQL> @db/90_drop_objects.sql
SQL> @db/01_create_objects.sql

sql -cloudconfig Wallet_<db>.zip admin@<db>_high
SQL> @db/02_create_app_user.sql
```

## Open questions

- **Authentication provider.** This decides what goes in `TEACHERS.AUTH_SUBJECT`.
- **Outcome content.** Who writes the outcome descriptions for each stage, and when do they get loaded?
