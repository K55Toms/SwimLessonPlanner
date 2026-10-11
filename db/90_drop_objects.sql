-- =============================================================================
-- SwimLessonPlanner: drop all tables (and their data), keep the user
-- Run as: SWIMLESSONPLANNER
-- Usage:  @db/90_drop_objects.sql
-- Safe to re-run: tables that do not exist are skipped.
-- =============================================================================
whenever sqlerror exit failure rollback
set verify off

accept confirm char prompt 'Type DROP to delete all SwimLessonPlanner tables and data: '

declare
  procedure drop_table (p_name in varchar2) is
  begin
    execute immediate 'drop table ' || p_name || ' cascade constraints purge';
    dbms_output.put_line('Dropped ' || p_name);
  exception
    when others then
      if sqlcode != -942 then  -- ORA-00942: table or view does not exist
        raise;
      end if;
  end;
begin
  if '&confirm' != 'DROP' then
    raise_application_error(-20000, 'Aborted: confirmation not given.');
  end if;

  -- Children first, parents last.
  drop_table('LESSON_DELIVERIES');
  drop_table('TERM_BLOCK_LESSONS');
  drop_table('TERM_BLOCKS');
  drop_table('LESSON_PLAN_SECTIONS');
  drop_table('LESSON_PLAN_OUTCOMES');
  drop_table('LESSON_PLANS');
  drop_table('ACTIVITY_OUTCOMES');
  drop_table('ACTIVITY_STAGES');
  drop_table('ACTIVITIES');
  drop_table('AI_GENERATIONS');
  drop_table('OUTCOMES');
  drop_table('TEACHERS');
  drop_table('STAGES');
end;
/

undefine confirm
prompt SwimLessonPlanner objects dropped.
