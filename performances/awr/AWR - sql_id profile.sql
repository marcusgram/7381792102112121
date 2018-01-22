set echo off feedback off
set term off verify off head on
set linesize 200 pagesize 9999
set long 4000000

rem AWR - sql_id profile.sql
rem generate an HTML formatted report of the SQL information for a given sql_id 
rem Provide documentation that can be used to help tune the SQL statement 
-- updated RDCornejo 14 Jun 2013 for DBA_HIST_SQLSTAT
-- updated RDCornejo 10 Sep 2013 correcting table cardinality calculation
-- updated RDCornejo 19 Sep 2013 correcting waits to subset on snap_id ranges

alter session set nls_date_format='DD-MON-YYYY  HH24:Mi:SS';

set term on
accept SQLID CHAR PROMPT 'Enter the sql_id to profile? '
accept start_snap_id number PROMPT 'Enter the start_snap_id to profile? '
accept end_snap_id number PROMPT 'Enter the end_snap_id to profile? '


-- Make sure value is lowercase for all subsequent usage.
column SQLID_COL new_val SQLID noprint
column start_snap_id_COL new_val start_snap_id noprint
column end_snap_id_COL new_val end_snap_id noprint

-- get instance name in file name
column INST_SQLID new_val FILE_NAME noprint
 
Select lower('&SQLID') SQLID_COL
, to_char(&start_snap_id) start_snap_id_COL 
, to_char(&end_snap_id) end_snap_id_COL 
, instance_name||'_'||lower('&SQLID')|| '_snaps_'||to_char(&start_snap_id)||'_'||to_char(&end_snap_id) INST_SQLID 
from 
(select upper(substr(global_name, 1, instr(global_name,'.' )-1)) instance_name from global_name);

-- Check the sql_id exists. turn spooling on to capture any error.
whenever sqlerror EXIT 
set serveroutput on
spool \temp\sql_id_profile_HIST_&FILE_NAME..html


declare
 lSQLID varchar2(32);
begin
 select max(sa.sql_id)  into lSQLID
 from DBA_HIST_SQL_PLAN sa
 where sa.sql_id = '&SQLID'
 ;
exception
 when NO_DATA_FOUND then
  raise_application_error(-20001,'sql_id=&SQLID does not exist.');
end;
/


--accept ENTER CHAR PROMPT 'SQL_ID:&SQLID exists.  Enter to continue profile? '

-- If there's no error, will get to here. 
-- Stop spooling to overwrite file below when start it again.
spool off
set serverout off


-- Start spooling the report as HTML 
whenever sqlerror CONTINUE
set markup HTML ON entmap off
timing start 'Report Execution'
spool \temp\sql_id_profile_HIST_&FILE_NAME..html

prompt <font face="Arial"</font>

select 'sql_id = &SQLID Instance = '    ||instance_name||
       ' snaps: &start_snap_id - &end_snap_id' ||
       ' generated on ' ||sysdate ||
       ' by User = '    || USER "SQL_ID PROFILE"
from gv$instance;
set feedback on

prompt Quick Links:
prompt <a href="#SqlSess"> Session Info</a>
prompt <a href="#SqlExec"> Execution Info</a>
prompt <a href="#SqlTabs"> Table Info</a>
prompt <a href="#SqlIndx"> Index Info</a>
prompt <a href="#SqlWait"> Aggregate Wait Events Info</a>


prompt <hr align="left" width="800">
prompt <h2><u><a name="SqlSess">&SQLID SESSION INFO</a></u></h2>
prompt <h3>SESSION ATTRIBUTES FOR &SQLID</h3>
prompt <i>NOTE: if SQL not running there will be now rows.</i>
with sess as
(
select sid, serial#, inst_id
     , sess.username
     , osuser
     , sess.status
     , sess.sql_id
     , sess.machine 
     , sess.logon_time
     , sess.terminal
     , sess.program
     , sess.last_call_et
     , event
from gv$session   sess
where sess.sql_id = '&SQLID'
)
select username
     , CASE WHEN ((sysdate - logon_time)* 24*60*60) > 86399
                 THEN to_char(logon_time, 'DD-MON-YYYY HH24:MI:SS') 
            WHEN ((sysdate - logon_time)* 24*60*60) <= 86399
                 THEN to_char(to_date((trunc((sysdate - sess.logon_time) * 24*60*60)),'sssss'),'hh24:mi:ss')  
       END as logon_hms
     , (select CASE WHEN trunc(value/100) > 86399
                         THEN to_char(trunc(value/100)) || ' sec' 
                    WHEN trunc(value/100) <= 86399
                         THEN to_char(to_date(trunc(value/100),'sssss'),'hh24:mi:ss')
               END 
        from v$sesstat a where a.sid = sess.sid
         and statistic# = (select statistic# from v$statname
                           where name =  'CPU used by this session' ) ) cpu_tm
     , event
     , CASE WHEN last_call_et > 86399
                 THEN to_char(last_call_et) || ' sec'
            WHEN last_call_et <= 86399
                 THEN to_char(to_date(last_call_et,'sssss'),'hh24:mi:ss')
       END last_call_tm
     , (select CASE WHEN trunc(sum(time_waited_micro)/1000000) > 86399
                         THEN to_char(trunc(sum(time_waited_micro)/1000000)) || ' sec'
                    WHEN trunc(sum(time_waited_micro)/1000000) <= 86399
                         THEN to_char(to_date(trunc(sum(time_waited_micro)/1000000),'sssss'),'hh24:mi:ss')
                END 
        from v$session_event a where a.sid = sess.sid) wait_hms
     , inst_id
     , sid
     , serial#
     , osuser
     , machine 
--     , to_char(logon_time,'DD-MON HH24:MI:SS') logon_time
     , terminal
     , program
from sess
;


prompt <hr align="left" width="800">


prompt <hr align="left" width="800">

prompt <h2><u><a name="SqlExec">&SQLID EXECUTION INFO</a></u></h2>
prompt <h3>EXECUTION ATTRIBUTES FOR &SQLID</h3>
prompt <i>NOTE: review stats.</i>
select inst_id, sql_id, sorts
     , CASE WHEN trunc(cpu_time/1000000) >  86399
                 THEN to_char(trunc(cpu_time/1000000)) || ' sec'
            WHEN trunc(cpu_time/1000000) <= 86399
                 THEN to_char(to_date(trunc(cpu_time/1000000),'sssss'),'hh24:mi:ss')
       END  cpu_hms
     , CASE WHEN elapsed_time > 1*86399*1000000
                 then to_char(trunc(elapsed_time/1000000)) || ' sec'
            WHEN elapsed_time <= 86399*1000000
                 THEN to_char(to_date(trunc(elapsed_time/1000000),'sssss'),'hh24:mi:ss') 
       END as elapsed_hms
     , executions
, CASE when executions <> 0 THEN
      CASE 
      WHEN elapsed_time > 86399*1000000
      THEN to_char(round(elapsed_time/executions/1000000)) || ' sec'
      WHEN elapsed_time <= 86399*1000000
      THEN to_char(to_date(round(elapsed_time/executions/1000000) ,'SSSSS'), 'HH24:MI:SS') 
      END 
  END  as time_per_execution
, disk_reads
, round(disk_reads/decode(executions, 0, decode(disk_reads,0,1,disk_reads), executions)) reads_per_execution
, buffer_gets
from gv$sqlarea
where sql_id = '&SQLID'
order by inst_id
;

select
     schema  
   , sub.sql_id
   , CASE WHEN elapsed_sec > 86399
          THEN elapsed_sec || ' sec'  
          WHEN elapsed_sec <= 86399
          THEN to_char(to_date(round(elapsed_sec) ,'SSSSS'), 'HH24:MI:SS') 
     END as clock_time
   , sub.executions
   , CASE when executions <> 0 THEN
          CASE WHEN elapsed_sec/executions > 86399
          THEN round(elapsed_sec/executions) || ' sec per exec'  
          WHEN elapsed_sec/executions <= 86399
          THEN to_char(to_date(round(elapsed_sec/executions) ,'SSSSS'), 'HH24:MI:SS') 
          END 
     END as time_per_exec
   , sub.elapsed_sec
   , sub.cpu_sec
   , sub.plsql_sec
   , sub.buffer_gets
   , sub.invalidations
   , sub.parse_calls
   , sub.rows_processed
from
   ( 
     select
        sql_id
        , round(sum(elapsed_time_delta)/1000000) as elapsed_sec
        , round(sum(cpu_time_delta)    /1000000) as cpu_sec 
        , round(sum(plsexec_time_delta)/1000000) as plsql_sec 
        , sum(executions_delta) as executions
        , sum(buffer_gets_delta) as buffer_gets
        , max(parsing_schema_name) as schema
        , sum(invalidations_delta) as invalidations
        , sum(parse_calls_delta) as parse_calls
        , sum(rows_processed_delta) as rows_processed
     from
        dba_hist_snapshot natural join dba_hist_sqlstat
     where 1=1
          and sql_id = '&SQLID' 
          and snap_id between &start_snap_id and &end_snap_id 
     group by
        sql_id
   ) sub
;

prompt <hr align="left" width="800">

prompt
prompt <h3>SQL and SQL_PLAN</h3>
prompt <font face="Courier New">

/* This version gives just the SQL statement and the Plan 
[useful for output and easily conveying this to others] 
*/
SELECT case when substr(plan_table_output, 1,1) = '|'
then replace(PLAN_TABLE_OUTPUT, ' ', '_')
else plan_Table_output
end plan_table_output
FROM table(dbms_xplan.display_awr('&SQLID'))
;

select sql_text from
(
select 1 ord, max(DBMS_LOB.SUBSTR(sql_text,4000,1)) sql_text
from dba_hist_sqltext where sql_id = '&SQLID'
union
select 2 ord, max(DBMS_LOB.SUBSTR(sql_text,4000,4001)) sql_text
from dba_hist_sqltext where sql_id = '&SQLID'
union
select 3 ord, max(DBMS_LOB.SUBSTR(sql_text,4000,8001)) sql_text
from dba_hist_sqltext where sql_id = '&SQLID'
union
select 4 ord, max(DBMS_LOB.SUBSTR(sql_text,4000,12001)) sql_text
from dba_hist_sqltext where sql_id = '&SQLID'
union
select 6 ord, max(DBMS_LOB.SUBSTR(sql_text,4000,16001)) sql_text
from dba_hist_sqltext where sql_id = '&SQLID'
)
order by ord
;

prompt <font face="Arial"</font>

prompt <hr align="left" width="800">

prompt
prompt <hr align="left" width="800">

prompt
prompt <hr align="left" width="800">
prompt
prompt <h2><u><a name="SqlTabs">&SQLID TABLE INFO</a></u></h2>
prompt <h3>TABLE CARDINALITY for &SQLID </h3>
select owner, table_name, num_rows
, round(blocks * 8192 / (1024*1024)) size_meg
, last_analyzed
from DBA_tables a
where 1=1
and (owner, table_name) in 
    (   select object_owner owner, object_name table_name
        from DBA_HIST_SQL_PLAN sp
        where object_type = 'TABLE'
          and sql_id = '&SQLID'
        union
        select object_owner owner, object_name table_name
        from DBA_HIST_SQL_PLAN sp
        where object_type like 'MAT%VIEW'
          and sql_id = '&SQLID'
        union
        select owner, table_name 
        from dba_indexes
        where (owner, index_name) in 
            (select object_owner owner, object_name index_name
            from DBA_HIST_SQL_PLAN sp
            where object_type like 'INDEX%'
            and sql_id = '&SQLID'
            )
    )
;

prompt <hr align="left" width="800">

prompt <hr align="left" width="800">
prompt
prompt <h2><u><a name="SqlIndx">&SQLID INDEX INFO</a></u></h2>
prompt <h3>INDEXES for  &SQLID </h3>
select index_owner, table_name, index_name, column_name 
from dba_ind_columns ic
where 1=1
and (table_owner, table_name) in 
    (   select object_owner owner, object_name table_name
        from DBA_HIST_SQL_PLAN  sp
        where object_type = 'TABLE'
          and sql_id = '&SQLID'
        union
        select object_owner owner, object_name table_name
        from DBA_HIST_SQL_PLAN sp
        where object_type like 'MAT%VIEW'
          and sql_id = '&SQLID'
        union
        select owner, table_name 
        from dba_indexes
        where (owner, index_name) in 
            (select object_owner owner, object_name index_name
            from DBA_HIST_SQL_PLAN  sp
            where object_type like 'INDEX%'
            and sql_id = '&SQLID'
            )
    )
order by 1,2,3, column_position
;

prompt <hr align="left" width="800">
prompt
prompt <hr align="left" width="800">

prompt
prompt <h2><u><a name="SqlWait">&SQLID AGGREGATE WAIT EVENTS INFO</a></u></h2>
prompt <h3>AGGREGATE WAIT EVENTS for  &SQLID </h3>

-- all waits for a sql_id group by object_id_name, sql_id, event, session_state 
-- =============================================================================
with sess_event as
(
select instance_number inst_id, SQL_ID, session_state, event, wait_class
, decode(session_state, 'ON CPU', wait_time, 'WAITING', time_waited) duration_sec
, decode(wait_class
, 'User I/O', current_obj#
, 'Configuration', current_obj#
, 'Application', decode(p2text, 'object #', p2, null) , null ) obj_no
from DBA_HIST_ACTIVE_SESS_HISTORY 
where sql_id  = '&SQLID' 
  and snap_id between &start_snap_id and &end_snap_id 
order by sql_id, 6 desc
)
, all_events as 
(
select sess_event.*
, (select obj_no ||' '|| owner ||'.' || object_name from all_objects 
where object_id = obj_no)  object_id_name
from sess_event
order by duration_sec desc
)
select inst_id, event, object_id_name, session_state
, sum(duration_sec) tot_duration
, count(*) event_cnt
from all_events
group by inst_id, object_id_name, event, session_state
order by 1, 5 desc 
;

prompt <hr align="left" width="800">
prompt



set term off
set term on


prompt <hr align="left" width="800">
prompt
prompt &SQLID SQL Profile Report complete.
timing stop
spool off
set markup HTML off

PROMPT @"C:\Documents and Settings\rdc0208\My Documents\MYFILES\DBA\Bag-of-Tricks\AWR\AWR - sql_id profile.sql"
accept ent char
set sqlprompt ""
prompt 
set sqlprompt ">"

