
set serveroutput on
set linesize 200
set pages 2000
set long 1000000 longchunksize 1000;
variable task_name varchar2(30);
begin
    :task_name := dbms_sqltune.create_tuning_task(sql_id => '&SQL_ID');
    dbms_sqltune.execute_tuning_task(task_name => :task_name);
end;
/

select task_name, status 
from dba_advisor_log 
where task_name = :task_name;

select dbms_sqltune.report_tuning_task(:task_name) as recommendations 
from dual;