--DBMS_SQLTUNE


--This is a simple introduction on how to use the package DBMS_SQLTUNE and get some tuning recommendations.
--With the following query or some other inputs (ADDM, AWR, etc) you can try to identify SQL statements with tuning potential.

set lines 160
set pages 2000
select sql_id, 
       substr(sql_text, 1, 40) sql_text, 
       executions, 
       trunc(cpu_time/executions) cpu_time, 
       trunc(elapsed_time/executions) elapsed_time, 
       avg_hard_parse_time, 
       user_io_wait_time
from v$sqlstats
where executions > 0
order by elapsed_time desc;



--From the output generated you can take the SQL_ID of the SQL statement you want and run PL/SQL block below:

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

select task_name, status from dba_advisor_log where task_name = :task_name;

select dbms_sqltune.report_tuning_task(:task_name) as recommendations from dual;