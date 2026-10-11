-- =============================================================================
-- SwimLessonPlanner: create tables, indexes and seed data
-- Run as: SWIMLESSONPLANNER
-- Usage:  @db/01_create_objects.sql
-- Re-run: run db/90_drop_objects.sql first.
-- Compatible with Oracle 19c and 23ai (no 23ai-only syntax used).
-- =============================================================================
whenever sqlerror exit failure rollback

-- -----------------------------------------------------------------------------
-- Reference data
-- -----------------------------------------------------------------------------
create table stages (
  stage_number  number(2)          constraint stages_pk primary key,
  title         varchar2(100 char) not null,
  summary       varchar2(1000 char),
  constraint stages_number_ck check (stage_number > 0)
);

create table teachers (
  teacher_id    number generated always as identity constraint teachers_pk primary key,
  email         varchar2(320 char) not null,
  display_name  varchar2(100 char) not null,
  auth_subject  varchar2(255 char),
  is_active     char(1) default 'Y' not null,
  created_at    timestamp with time zone default systimestamp not null,
  updated_at    timestamp with time zone default systimestamp not null,
  constraint teachers_email_uk        unique (email),
  constraint teachers_auth_subject_uk unique (auth_subject),
  constraint teachers_is_active_ck    check (is_active in ('Y', 'N'))
);

-- Outcome wording is the app's own (aligned with, not copied from, the scheme).
create table outcomes (
  outcome_id    number generated always as identity constraint outcomes_pk primary key,
  stage_number  number(2) not null constraint outcomes_stage_fk references stages,
  outcome_code  varchar2(20 char)   not null,
  description   varchar2(1000 char) not null,
  skill_area    varchar2(50 char),
  display_order number(4),
  is_active     char(1) default 'Y' not null,
  created_by    number constraint outcomes_created_by_fk references teachers,
  created_at    timestamp with time zone default systimestamp not null,
  constraint outcomes_code_uk      unique (stage_number, outcome_code),
  constraint outcomes_is_active_ck check (is_active in ('Y', 'N'))
);

-- -----------------------------------------------------------------------------
-- AI generation audit (what Claude was asked and returned)
-- -----------------------------------------------------------------------------
create table ai_generations (
  generation_id number generated always as identity constraint ai_generations_pk primary key,
  teacher_id    number not null constraint ai_generations_teacher_fk references teachers,
  request_type  varchar2(20 char)  not null,
  model_id      varchar2(100 char) not null,
  prompt        clob not null,
  response      clob,
  status        varchar2(20 char) default 'SUCCEEDED' not null,
  input_tokens  number(10),
  output_tokens number(10),
  created_at    timestamp with time zone default systimestamp not null,
  constraint ai_generations_type_ck   check (request_type in ('LESSON_PLAN', 'ACTIVITY')),
  constraint ai_generations_status_ck check (status in ('SUCCEEDED', 'FAILED'))
);

-- -----------------------------------------------------------------------------
-- Activity library
-- -----------------------------------------------------------------------------
create table activities (
  activity_id     number generated always as identity constraint activities_pk primary key,
  section_type    varchar2(20 char)  not null,
  title           varchar2(200 char) not null,
  description     varchar2(4000 char) not null,
  equipment       varchar2(1000 char),
  teaching_points varchar2(4000 char),
  differentiation varchar2(4000 char),
  safety_notes    varchar2(2000 char),
  source          varchar2(20 char) default 'TEACHER' not null,
  status          varchar2(20 char) default 'DRAFT'   not null,
  created_by      number not null constraint activities_created_by_fk references teachers,
  generation_id   number constraint activities_generation_fk references ai_generations,
  created_at      timestamp with time zone default systimestamp not null,
  updated_at      timestamp with time zone default systimestamp not null,
  constraint activities_section_ck check (section_type in ('WARM_UP', 'MAIN_SET', 'CONTRASTING', 'GAME', 'COOL_DOWN')),
  constraint activities_source_ck  check (source in ('TEACHER', 'AI_CLAUDE', 'AI_EDITED')),
  constraint activities_status_ck  check (status in ('DRAFT', 'PUBLISHED', 'RETIRED'))
);

create table activity_stages (
  activity_id  number    not null constraint activity_stages_activity_fk references activities on delete cascade,
  stage_number number(2) not null constraint activity_stages_stage_fk references stages,
  constraint activity_stages_pk primary key (activity_id, stage_number)
);

create table activity_outcomes (
  activity_id number not null constraint activity_outcomes_activity_fk references activities on delete cascade,
  outcome_id  number not null constraint activity_outcomes_outcome_fk  references outcomes,
  constraint activity_outcomes_pk primary key (activity_id, outcome_id)
);

-- -----------------------------------------------------------------------------
-- Lesson plans
-- -----------------------------------------------------------------------------
create table lesson_plans (
  plan_id              number generated always as identity constraint lesson_plans_pk primary key,
  teacher_id           number    not null constraint lesson_plans_teacher_fk references teachers,
  stage_number         number(2) not null constraint lesson_plans_stage_fk   references stages,
  title                varchar2(200 char) not null,
  duration_minutes     number(3),
  -- Safety gate: every plan must carry a pre-water-entry question and talking point.
  safety_question      varchar2(1000 char) not null,
  safety_talking_point varchar2(2000 char) not null,
  equipment            varchar2(1000 char),
  teaching_points      varchar2(4000 char),
  differentiation      varchar2(4000 char),
  safety_notes         varchar2(2000 char),
  source               varchar2(20 char) default 'TEACHER' not null,
  visibility           varchar2(10 char) default 'PRIVATE' not null,
  status               varchar2(20 char) default 'DRAFT'   not null,
  based_on_plan_id     number constraint lesson_plans_based_on_fk   references lesson_plans,
  generation_id        number constraint lesson_plans_generation_fk references ai_generations,
  created_at           timestamp with time zone default systimestamp not null,
  updated_at           timestamp with time zone default systimestamp not null,
  constraint lesson_plans_safety_q_ck   check (trim(safety_question) is not null),
  constraint lesson_plans_safety_tp_ck  check (trim(safety_talking_point) is not null),
  constraint lesson_plans_duration_ck   check (duration_minutes between 5 and 120),
  constraint lesson_plans_source_ck     check (source in ('TEACHER', 'AI_CLAUDE', 'AI_EDITED')),
  constraint lesson_plans_visibility_ck check (visibility in ('PRIVATE', 'SHARED')),
  constraint lesson_plans_status_ck     check (status in ('DRAFT', 'READY', 'ARCHIVED'))
);

create table lesson_plan_outcomes (
  plan_id    number not null constraint lp_outcomes_plan_fk    references lesson_plans on delete cascade,
  outcome_id number not null constraint lp_outcomes_outcome_fk references outcomes,
  constraint lesson_plan_outcomes_pk primary key (plan_id, outcome_id)
);

-- One row per activity slot. A plan can have several MAIN_SET rows, ordered by sequence_no.
create table lesson_plan_sections (
  section_id       number generated always as identity constraint lesson_plan_sections_pk primary key,
  plan_id          number not null constraint lp_sections_plan_fk     references lesson_plans on delete cascade,
  section_type     varchar2(20 char) not null,
  sequence_no      number(3) default 1 not null,
  activity_id      number constraint lp_sections_activity_fk references activities,
  title            varchar2(200 char),
  instructions     varchar2(4000 char),
  duration_minutes number(3),
  constraint lp_sections_uk         unique (plan_id, section_type, sequence_no),
  constraint lp_sections_type_ck    check (section_type in ('WARM_UP', 'MAIN_SET', 'CONTRASTING', 'GAME', 'COOL_DOWN')),
  constraint lp_sections_content_ck check (activity_id is not null or instructions is not null)
);

-- -----------------------------------------------------------------------------
-- Term blocks and delivery log
-- -----------------------------------------------------------------------------
create table term_blocks (
  block_id      number generated always as identity constraint term_blocks_pk primary key,
  teacher_id    number    not null constraint term_blocks_teacher_fk references teachers,
  stage_number  number(2) not null constraint term_blocks_stage_fk   references stages,
  name          varchar2(200 char) not null,
  group_label   varchar2(100 char),
  start_date    date,
  end_date      date,
  planned_lessons number(3),
  notes         varchar2(4000 char),
  status        varchar2(20 char) default 'PLANNING' not null,
  created_at    timestamp with time zone default systimestamp not null,
  updated_at    timestamp with time zone default systimestamp not null,
  constraint term_blocks_dates_ck  check (end_date is null or start_date is null or end_date >= start_date),
  constraint term_blocks_status_ck check (status in ('PLANNING', 'ACTIVE', 'COMPLETE'))
);

create table term_block_lessons (
  block_id      number    not null constraint tb_lessons_block_fk references term_blocks on delete cascade,
  lesson_number number(3) not null,
  plan_id       number    not null constraint tb_lessons_plan_fk  references lesson_plans,
  constraint term_block_lessons_pk primary key (block_id, lesson_number)
);

-- No swimmer-level data is stored. group_label and notes are free text; the app
-- must tell teachers not to enter children's names.
create table lesson_deliveries (
  delivery_id   number generated always as identity constraint lesson_deliveries_pk primary key,
  plan_id       number not null constraint deliveries_plan_fk    references lesson_plans,
  teacher_id    number not null constraint deliveries_teacher_fk references teachers,
  block_id      number constraint deliveries_block_fk references term_blocks on delete set null,
  delivered_on  date not null,
  group_label   varchar2(100 char),
  swimmer_count number(3),
  rating        number(1),
  notes         varchar2(4000 char),
  notes_shared  char(1) default 'N' not null,
  shared_at     timestamp with time zone,
  created_at    timestamp with time zone default systimestamp not null,
  updated_at    timestamp with time zone default systimestamp not null,
  constraint deliveries_rating_ck       check (rating between 1 and 5),
  constraint deliveries_swimmers_ck     check (swimmer_count >= 0),
  constraint deliveries_shared_flag_ck  check (notes_shared in ('Y', 'N')),
  constraint deliveries_shared_notes_ck check (notes_shared = 'N' or notes is not null)
);

-- -----------------------------------------------------------------------------
-- Indexes on foreign keys and common lookups
-- (columns already leading a PK/unique constraint are not repeated)
-- -----------------------------------------------------------------------------
create index outcomes_created_by_ix      on outcomes (created_by);
create index ai_generations_teacher_ix   on ai_generations (teacher_id);
create index activities_created_by_ix    on activities (created_by);
create index activities_generation_ix    on activities (generation_id);
create index activities_lookup_ix        on activities (section_type, status);
create index activity_stages_stage_ix    on activity_stages (stage_number);
create index activity_outcomes_out_ix    on activity_outcomes (outcome_id);
create index lesson_plans_teacher_ix     on lesson_plans (teacher_id);
create index lesson_plans_library_ix     on lesson_plans (stage_number, visibility, status);
create index lesson_plans_based_on_ix    on lesson_plans (based_on_plan_id);
create index lesson_plans_generation_ix  on lesson_plans (generation_id);
create index lp_outcomes_outcome_ix      on lesson_plan_outcomes (outcome_id);
create index lp_sections_activity_ix     on lesson_plan_sections (activity_id);
create index term_blocks_teacher_ix      on term_blocks (teacher_id);
create index term_blocks_stage_ix        on term_blocks (stage_number);
create index tb_lessons_plan_ix          on term_block_lessons (plan_id);
create index deliveries_plan_ix          on lesson_deliveries (plan_id);
create index deliveries_teacher_ix       on lesson_deliveries (teacher_id, delivered_on);
create index deliveries_block_ix         on lesson_deliveries (block_id);

-- -----------------------------------------------------------------------------
-- Seed data
-- -----------------------------------------------------------------------------
insert into stages (stage_number, title) values (1, 'Stage 1');
insert into stages (stage_number, title) values (2, 'Stage 2');
insert into stages (stage_number, title) values (3, 'Stage 3');
insert into stages (stage_number, title) values (4, 'Stage 4');
insert into stages (stage_number, title) values (5, 'Stage 5');
insert into stages (stage_number, title) values (6, 'Stage 6');
insert into stages (stage_number, title) values (7, 'Stage 7');
commit;

prompt SwimLessonPlanner objects created.
