ASH AND AWR PERFORMANCE TUNING SCRIPTS

Posted by Gavin SoormaOn November 16, 20121 CommentsASH, awr, Performance Tuning, scripts

https://gavinsoorma.com/2012/11/ash-and-awr-performance-tuning-scripts/

Listed below are some SQL queries which I find particularly useful for performance tuning. 
These are based on the Active Session History V$ View to get a current perspective of performance
and the DBA_HIST_* AWR history tables for obtaining performance data pertaining to a period of time in the past.

I would like to add that these queries have been customised by me based on SQL scripts obtained from colleagues and peers. 
So if I am infringing any copyright material let me know and I shall remove the same.
Also If anyone has any similar useful scripts to contribute for use by the community do send it to me
and I shall include the same on this page

-------------------------- 
Top Recent Wait Events
--------------------------

col EVENT format a60 

select * from (
select active_session_history.event,
sum(active_session_history.wait_time +
active_session_history.time_waited) ttl_wait_time
from v$active_session_history active_session_history
where active_session_history.event is not null
group by active_session_history.event
order by 2 desc)
where rownum < 6
/

----------------------------------------
Top Wait Events Since Instance Startup
----------------------------------------

col event format a60

select event, total_waits, time_waited
from v$system_event e, v$event_name n
where n.event_id = e.event_id
and n.wait_class !='Idle'
and n.wait_class = (select wait_class from v$session_wait_class
 where wait_class !='Idle'
 group by wait_class having
sum(time_waited) = (select max(sum(time_waited)) from v$session_wait_class
where wait_class !='Idle'
group by (wait_class)))
order by 3;

-----------------------------------
List Of Users Currently Waiting
-----------------------------------

col username format a12
col sid format 9999
col state format a15
col event format a50
col wait_time format 99999999
set pagesize 100
set linesize 120

select s.sid, s.username, se.event, se.state, se.wait_time
from v$session s, v$session_wait se
where s.sid=se.sid
and se.event not like 'SQL*Net%'
and se.event not like '%rdbms%'
and s.username is not null
order by se.wait_time;

------------------------------------------------------------------
Find The Main Database Wait Events In A Particular Time Interval
------------------------------------------------------------------
First determine the snapshot id values for the period in question.
In this example we need to find the SNAP_ID for the period 10 PM to 11 PM on the 14th of November, 2012.

select snap_id,begin_interval_time,end_interval_time
from dba_hist_snapshot
where to_char(begin_interval_time,'DD-MON-YYYY')='14-NOV-2012'
and EXTRACT(HOUR FROM begin_interval_time) between 22 and 23;

set verify off
select * from (
select active_session_history.event,
sum(active_session_history.wait_time +
active_session_history.time_waited) ttl_wait_time
from dba_hist_active_sess_history active_session_history
where event is not null
and SNAP_ID between &ssnapid and &esnapid
group by active_session_history.event
order by 2 desc)
where rownum

---------------------------------------------------
Top CPU Consuming SQL During A Certain Time Period
---------------------------------------------------
Note – in this case we are finding the Top 5 CPU intensive SQL statements executed between 9.00 AM and 11.00 AM

select * from (
select
SQL_ID,
 sum(CPU_TIME_DELTA),
sum(DISK_READS_DELTA),
count(*)
from
DBA_HIST_SQLSTAT a, dba_hist_snapshot s
where
s.snap_id = a.snap_id
and s.begin_interval_time > sysdate -1
and EXTRACT(HOUR FROM S.END_INTERVAL_TIME) between 9 and 11
group by
SQL_ID
order by
sum(CPU_TIME_DELTA) desc)
where rownum

---------------------------------------------------------------------------------
Which Database Objects Experienced the Most Number of Waits in the Past One Hour
---------------------------------------------------------------------------------

set linesize 120
col event format a40
col object_name format a40

select * from 
(
  select dba_objects.object_name,
 dba_objects.object_type,
active_session_history.event,
 sum(active_session_history.wait_time +
  active_session_history.time_waited) ttl_wait_time
from v$active_session_history active_session_history,
    dba_objects
 where 
active_session_history.sample_time between sysdate - 1/24 and sysdate
and active_session_history.current_obj# = dba_objects.object_id
 group by dba_objects.object_name, dba_objects.object_type, active_session_history.event
 order by 4 desc)
where rownum < 6;

----------------------------------------
Top Segments ordered by Physical Reads
----------------------------------------

col segment_name format a20
col owner format a10 
select segment_name,object_type,total_physical_reads
 from ( select owner||'.'||object_name as segment_name,object_type,
value as total_physical_reads
from v$segment_statistics
 where statistic_name in ('physical reads')
 order by total_physical_reads desc)
 where rownum

-------------------------------------------
Top 5 SQL statements in the past one hour
-------------------------------------------

select * from (
select active_session_history.sql_id,
 dba_users.username,
 sqlarea.sql_text,
sum(active_session_history.wait_time +
active_session_history.time_waited) ttl_wait_time
from v$active_session_history active_session_history,
v$sqlarea sqlarea,
 dba_users
where 
active_session_history.sample_time between sysdate -  1/24  and sysdate
  and active_session_history.sql_id = sqlarea.sql_id
and active_session_history.user_id = dba_users.user_id
 group by active_session_history.sql_id,sqlarea.sql_text, dba_users.username
 order by 4 desc )
where rownum

----------------------------------------------
SQL with the highest I/O in the past one day
----------------------------------------------

select * from 
(
SELECT /*+LEADING(x h) USE_NL(h)*/ 
       h.sql_id
,      SUM(10) ash_secs
FROM   dba_hist_snapshot x
,      dba_hist_active_sess_history h
WHERE   x.begin_interval_time > sysdate -1
AND    h.SNAP_id = X.SNAP_id
AND    h.dbid = x.dbid
AND    h.instance_number = x.instance_number
AND    h.event in  ('db file sequential read','db file scattered read')
GROUP BY h.sql_id
ORDER BY ash_secs desc )
where rownum

-------------------------------------------------
Top CPU consuming queries since past one day
-------------------------------------------------

select * from (
select 
	SQL_ID, 
	sum(CPU_TIME_DELTA), 
	sum(DISK_READS_DELTA),
	count(*)
from 
	DBA_HIST_SQLSTAT a, dba_hist_snapshot s
where
 s.snap_id = a.snap_id
 and s.begin_interval_time > sysdate -1
	group by 
	SQL_ID
order by 
	sum(CPU_TIME_DELTA) desc)
where rownum

----------------------------------------------------------------
Find what the top SQL was at a particular reported time of day
----------------------------------------------------------------
First determine the snapshot id values for the period in question.

In thos example we need to find the SNAP_ID for the period 10 PM to 11 PM on the 14th of November, 2012.

select snap_id,begin_interval_time,end_interval_time
from dba_hist_snapshot
where to_char(begin_interval_time,'DD-MON-YYYY')='14-NOV-2012'
and EXTRACT(HOUR FROM begin_interval_time) between 22 and 23;
select * from
 (
select
 sql.sql_id c1,
sql.buffer_gets_delta c2,
sql.disk_reads_delta c3,
sql.iowait_delta c4
 from
dba_hist_sqlstat sql,
dba_hist_snapshot s
 where
 s.snap_id = sql.snap_id
and
 s.snap_id= &snapid
 order by
 c3 desc)
 where rownum < 6 
/

-------------------------------------------------------------------
Analyse a particular SQL ID and see the trends for the past day
-------------------------------------------------------------------
select
 s.snap_id,
 to_char(s.begin_interval_time,'HH24:MI') c1,
 sql.executions_delta c2,
 sql.buffer_gets_delta c3,
 sql.disk_reads_delta c4,
 sql.iowait_delta c5,
sql.cpu_time_delta c6,
 sql.elapsed_time_delta c7
 from
 dba_hist_sqlstat sql,
 dba_hist_snapshot s
 where
 s.snap_id = sql.snap_id
 and s.begin_interval_time > sysdate -1
 and
sql.sql_id='&sqlid'
 order by c7
 /

-------------------------------------------------------------------------------------------------------------------------- 
Do we have multiple plan hash values for the same SQL ID – in that case may be changed plan is causing bad performance
--------------------------------------------------------------------------------------------------------------------------
select 
  SQL_ID 
, PLAN_HASH_VALUE 
, sum(EXECUTIONS_DELTA) EXECUTIONS
, sum(ROWS_PROCESSED_DELTA) CROWS
, trunc(sum(CPU_TIME_DELTA)/1000000/60) CPU_MINS
, trunc(sum(ELAPSED_TIME_DELTA)/1000000/60)  ELA_MINS
from DBA_HIST_SQLSTAT 
where SQL_ID in (
'&sqlid') 
group by SQL_ID , PLAN_HASH_VALUE
order by SQL_ID, CPU_MINS;

-------------------------------------------------------------
Top 5 Queries for past week based on ADDM recommendations
-------------------------------------------------------------

/*
Top 10 SQL_ID's for the last 7 days as identified by ADDM
from DBA_ADVISOR_RECOMMENDATIONS and dba_advisor_log
*/

col SQL_ID form a16
col Benefit form 9999999999999
select * from (
select b.ATTR1 as SQL_ID, max(a.BENEFIT) as "Benefit" 
from DBA_ADVISOR_RECOMMENDATIONS a, DBA_ADVISOR_OBJECTS b 
where a.REC_ID = b.OBJECT_ID
and a.TASK_ID = b.TASK_ID
and a.TASK_ID in (select distinct b.task_id
from dba_hist_snapshot a, dba_advisor_tasks b, dba_advisor_log l
where a.begin_interval_time > sysdate - 7 
and  a.dbid = (select dbid from v$database) 
and a.INSTANCE_NUMBER = (select INSTANCE_NUMBER from v$instance) 
and to_char(a.begin_interval_time, 'yyyymmddHH24') = to_char(b.created, 'yyyymmddHH24') 
and b.advisor_name = 'ADDM' 
and b.task_id = l.task_id 
and l.status = 'COMPLETED') 
and length(b.ATTR4) > 1 group by b.ATTR1
order by max(a.BENEFIT) desc) where rownum < 6;
