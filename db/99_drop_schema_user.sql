-- =============================================================================
-- SwimLessonPlanner: drop the app user, its role, the schema owner and
-- EVERYTHING the schema owns
-- Run as: ADMIN
-- Usage:  @db/99_drop_schema_user.sql
-- Irreversible. Disconnect any SLP_APP / SWIMLESSONPLANNER sessions first
-- (ORA-01940). Safe to re-run: missing users and roles are skipped.
-- =============================================================================
whenever sqlerror exit failure rollback
set verify off

accept confirm char prompt 'Type DROP SWIMLESSONPLANNER to permanently drop the users and all data: '

declare
  procedure run_ignoring (p_sql in varchar2, p_ignore in pls_integer) is
  begin
    execute immediate p_sql;
    dbms_output.put_line('Done: ' || p_sql);
  exception
    when others then
      if sqlcode != p_ignore then
        raise;
      end if;
  end;
begin
  if '&confirm' != 'DROP SWIMLESSONPLANNER' then
    raise_application_error(-20000, 'Aborted: confirmation not given.');
  end if;

  run_ignoring('drop user slp_app cascade',           -1918);  -- ORA-01918: user does not exist
  run_ignoring('drop role slp_app_role',               -1919);  -- ORA-01919: role does not exist
  run_ignoring('drop user swimlessonplanner cascade', -1918);
end;
/

undefine confirm
prompt SwimLessonPlanner users and role dropped.
