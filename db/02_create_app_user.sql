-- =============================================================================
-- SwimLessonPlanner: create the least-privilege application user
-- Run as: ADMIN, after 01_create_objects.sql
-- Usage:  @db/02_create_app_user.sql
--
-- SLP_APP is the account the web app connects as. It can read and write rows
-- in the SWIMLESSONPLANNER schema but cannot create, alter or drop objects.
-- Uses 23ai schema-level privileges, so new tables are covered automatically.
-- The app must qualify table names or run:
--   alter session set current_schema = swimlessonplanner
-- =============================================================================
whenever sqlerror exit failure rollback
set verify off

accept app_password char prompt 'Password for SLP_APP: ' hide

create role slp_app_role;

grant select any table,
      insert any table,
      update any table,
      delete any table
   on schema swimlessonplanner
   to slp_app_role;

create user slp_app identified by "&app_password";

grant create session to slp_app;
grant slp_app_role   to slp_app;
alter user slp_app default role all;

undefine app_password
prompt User SLP_APP created with role SLP_APP_ROLE.
