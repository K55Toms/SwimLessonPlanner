-- =============================================================================
-- SwimLessonPlanner: drop the schema owner and EVERYTHING it owns
-- Run as: ADMIN
-- Usage:  @db/99_drop_schema_user.sql
-- Irreversible. Disconnect any SWIMLESSONPLANNER sessions first (ORA-01940).
-- =============================================================================
whenever sqlerror exit failure rollback
set verify off

accept confirm char prompt 'Type DROP SWIMLESSONPLANNER to permanently drop the user and all its data: '

begin
  if '&confirm' != 'DROP SWIMLESSONPLANNER' then
    raise_application_error(-20000, 'Aborted: confirmation not given.');
  end if;
end;
/

drop user swimlessonplanner cascade;

undefine confirm
prompt User SWIMLESSONPLANNER dropped.
