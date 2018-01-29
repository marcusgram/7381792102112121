
à tester :

http://carlos-sierra.net/2013/04/24/monitoring-a-sql-that-executes-well-thousands-of-times-but-sometimes-it-takes-longer/#comments

-------------------------------
Real-Time SQL Monitoring Report
--------------------------------
The DBMS_SQLTUNE.REPORT_SQL_MONITOR function provides the SQL monitor report which provides information on SQL that is executing. Here is an example:


spool sqlm.out
set long 999999999
set linesize 1000
declare
     v_output   clob;
begin
     v_output:=dbms_sqltune.report_sql_monitor();
dbms_output.put_line(v_output);
end;
/
spool off



ou faire :

SELECT sql_id, status, sql_text
FROM   v$sql_monitor
WHERE  username = 'EIM_BATCH';



-- Several different parameters are available that allow you to adjust the report output to suit your needs.

set pagesize 0 echo off timing off linesize 1000 trimspool on trim on long 2000000 longchunksize 2000000 feedback off
spool sqlmon_4vbqtp97hwqk8.html
 select dbms_sqltune.report_sql_monitor(type=&gt;'EM', sql_id=&gt;'4vbqtp97hwqk8') monitor_report from dual;
spool off




set long 999999999
set lines 280
col report for a279
accept sid  prompt "Enter value for sid: "
select
DBMS_SQLTUNE.REPORT_SQL_MONITOR(
   session_id=>nvl('&&sid',sys_context('userenv','sid')),
   session_serial=>decode('&&sid',null,null,
   sys_context('userenv','sid'),(select serial# from v$session where audsid = sys_context('userenv','sessionid')),null),
   sql_id=>'&sql_id',
   sql_exec_id=>'&sql_exec_id',
   report_level=>'ALL') 
as report
from dual;
set lines 155
undef SID
/
