-- =============================================================================
-- SwimLessonPlanner: create the schema owner
-- Run as: ADMIN on the Autonomous Database (SQLcl or SQL*Plus)
-- Usage:  @db/00_create_schema_user.sql
--
-- Unquoted, the name is stored by Oracle as SWIMLESSONPLANNER.
-- ADB password rules apply (12-30 chars, upper + lower + number, must not
-- contain the username or a double quote). Verify against current OCI docs.
-- =============================================================================
whenever sqlerror exit failure rollback
set verify off

accept slp_password char prompt 'Password for SWIMLESSONPLANNER: ' hide

create user swimlessonplanner identified by "&slp_password"
  default tablespace data
  temporary tablespace temp
  quota unlimited on data;

grant create session,
      create table,
      create view,
      create sequence,
      create procedure,
      create trigger
   to swimlessonplanner;

undefine slp_password
prompt User SWIMLESSONPLANNER created. Next: connect as SWIMLESSONPLANNER and run db/01_create_objects.sql
