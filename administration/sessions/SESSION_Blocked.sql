



--------------------------------------------------------
-- ASH - Blocked Sessions.sql
-- updated 25-Oct-2013 RDCornejo
-- optional subset values: sql_id, Module name, username
---------------------------------------------------------
select * from 
(
SELECT  distinct a.snap_id "Snap Id"
, a.sample_time "Sample Time"
, (select username from dba_users du where du.user_id  = a.user_id) "Blocked User"
, a.session_id "Blocked Session" 
, a.session_serial# "Blocked Session Serial#"
, a.event "Blocked User Event"
, round(decode(a.session_state, 'ON CPU', a.wait_time, 'WAITING', a.time_waited)/1000000, 3) "Duration sec"
, a.sql_id 
, DBMS_LOB.SUBSTR(s.sql_text,4000) "sql_text of Blocked User"
--, a.inst_id
, (select username from dba_users du 
    where du.user_id = (select user_id from DBA_HIST_ACTIVE_SESS_HISTORY b 
                        where b.instance_number = a.instance_number 
                          and b.dbid = a.dbid
                          and b.snap_id = a.snap_id
                          and b.sample_id = a.sample_id
                          and b.session_id = a.blocking_session 
                          and b.session_serial#=a.blocking_session_serial# ) 
   ) "Blocking User"
, a.blocking_session "Blocking Session"
, a.blocking_session_serial# "Blocking Session Serial#"
, (select event from DBA_HIST_ACTIVE_SESS_HISTORY b 
    where b.instance_number = a.instance_number
      and b.dbid = a.dbid
      and b.snap_id = a.snap_id
      and b.sample_id = a.sample_id
      and b.session_id = a.blocking_session 
      and b.session_serial#=a.blocking_session_serial# ) "Blocking User Event"
, (select sql_id from DBA_HIST_ACTIVE_SESS_HISTORY b 
    where b.instance_number = a.instance_number 
      and b.dbid = a.dbid
      and b.snap_id = a.snap_id
      and b.sample_id = a.sample_id
      and b.session_id = a.blocking_session 
      and b.session_serial# = a.blocking_session_serial# 
   ) "sql_id blocking" 
, (select DBMS_LOB.SUBSTR(txt.sql_text,4000)
     from dba_hist_sqltext txt
    where 1=1
      and txt.dbid = a.dbid
      and txt.sql_id = (select sql_id from DBA_HIST_ACTIVE_SESS_HISTORY b 
                        where b.instance_number = a.instance_number 
                          and b.dbid = a.dbid
                          and b.snap_id = a.snap_id
                          and b.sample_id = a.sample_id
                          and b.session_id = a.blocking_session 
                          and b.session_serial#=a.blocking_session_serial# )
   ) "sql_text of Blocking User" 
--, a.blocking_session_status
--, a.module
from  DBA_HIST_ACTIVE_SESS_HISTORY a  
, dba_hist_sqltext s
where a.sql_id=s.sql_id and a.dbid = s.dbid
  and blocking_session is not null
  and snap_id between :start_snap_id and :end_snap_id
  and a.sql_id = nvl(:sql_id, a.sql_id)
  and Module = nvl(:module, module) 
order by a.sample_time 
)
where "Blocked User" = nvl(:username, "Blocked User")
;


---------------------
-- different grouping:
---------------------
select "Blocked User"
,"Blocked Session"
,"Blocked Session Serial#"
,"Blocked User Event"
, count("Blocked User Event") "Event Count"
,"SQL_ID"
,sum("Duration sec") "Duration sec"
,to_char(min("Sample Time"), 'YYYY-MM-DD HH24:MI') "Min Sample Time"
,to_char(max("Sample Time"), 'YYYY-MM-DD HH24:MI')  "Max Sample Time"
, to_char(trunc(sysdate)+(cast(max("Sample Time") as date) 
                        - cast(min("Sample Time") as date)),'HH24:MI:SS')  as "Lock Time Range"
,max("sql_text of Blocked User") "sql_text of Blocked User"
,count(distinct "Blocking User"||':'||"Blocking Session"||':'||"Blocking Session Serial#") "Distinct Blockers"
,min("Blocking User"||':'||"Blocking Session"||':'||"Blocking Session Serial#") "Min Blocker"
,max("Blocking User"||':'||"Blocking Session"||':'||"Blocking Session Serial#") "Max Blocker"
,max("Blocking User Event") "Max Blocking User Event"
,max("sql_id blocking") "Max sql_id blocking"
,max("sql_text of Blocking User") "Max sql_text of Blocking User"
,min("Blocking User Event") "Min Blocking User Event"
,min("sql_id blocking") "Min sql_id blocking"
,min("sql_text of Blocking User") "Min sql_text of Blocking User"
from 
(
SELECT  distinct a.snap_id "Snap Id"
, a.sample_time "Sample Time"
, (select username from dba_users du where du.user_id  = a.user_id) "Blocked User"
, a.session_id "Blocked Session" 
, a.session_serial# "Blocked Session Serial#"
, a.event "Blocked User Event"
, round(decode(a.session_state, 'ON CPU', a.wait_time, 'WAITING', a.time_waited)/1000000, 3) "Duration sec"
, a.sql_id 
, DBMS_LOB.SUBSTR(s.sql_text,4000) "sql_text of Blocked User"
--, a.inst_id
, (select username from dba_users du 
    where du.user_id = (select user_id from DBA_HIST_ACTIVE_SESS_HISTORY b 
                        where b.instance_number = a.instance_number 
                          and b.dbid = a.dbid
                          and b.snap_id = a.snap_id
                          and b.sample_id = a.sample_id
                          and b.session_id = a.blocking_session 
                          and b.session_serial#=a.blocking_session_serial# ) 
   ) "Blocking User"
, a.blocking_session "Blocking Session"
, a.blocking_session_serial# "Blocking Session Serial#"
, (select event from DBA_HIST_ACTIVE_SESS_HISTORY b 
    where b.instance_number = a.instance_number
      and b.dbid = a.dbid
      and b.snap_id = a.snap_id
      and b.sample_id = a.sample_id
      and b.session_id = a.blocking_session 
      and b.session_serial#=a.blocking_session_serial# ) "Blocking User Event"
, (select sql_id from DBA_HIST_ACTIVE_SESS_HISTORY b 
    where b.instance_number = a.instance_number 
      and b.dbid = a.dbid
      and b.snap_id = a.snap_id
      and b.sample_id = a.sample_id
      and b.session_id = a.blocking_session 
      and b.session_serial# = a.blocking_session_serial# 
   ) "sql_id blocking" 
, (select DBMS_LOB.SUBSTR(txt.sql_text,4000)
     from dba_hist_sqltext txt
    where 1=1
      and txt.dbid = a.dbid
      and txt.sql_id = (select sql_id from DBA_HIST_ACTIVE_SESS_HISTORY b 
                        where b.instance_number = a.instance_number 
                          and b.dbid = a.dbid
                          and b.snap_id = a.snap_id
                          and b.sample_id = a.sample_id
                          and b.session_id = a.blocking_session 
                          and b.session_serial#=a.blocking_session_serial# )
   ) "sql_text of Blocking User" 
--, a.blocking_session_status
--, a.module
from  DBA_HIST_ACTIVE_SESS_HISTORY a  
, dba_hist_sqltext s
where a.sql_id=s.sql_id and a.dbid = s.dbid
  and blocking_session is not null
  and snap_id between :start_snap_id and :end_snap_id
  and a.sql_id = nvl(:sql_id, a.sql_id)
  and Module = nvl(:module, module) 
order by a.sample_time 
)
where "Blocked User" = nvl(:username, "Blocked User")
group by "Blocked User"
,"Blocked Session"
,"Blocked Session Serial#"
,"Blocked User Event"
,"SQL_ID"
having sum("Duration sec") >= 60
order by 7 desc -- "Duration sec"
;



----------------------
-- group by day
-- different grouping:
----------------------
select to_char(trunc("Sample Time", 'DD'),'YYYY-MM-DD')  "Day"
, "Blocked User"
,"Blocked Session"
,"Blocked Session Serial#"
,"Blocked User Event"
, count("Blocked User Event") "Event Count"
,"SQL_ID"
,sum("Duration sec") "Duration sec"
,to_char(min("Sample Time"), 'YYYY-MM-DD HH24:MI') "Min Sample Time"
,to_char(max("Sample Time"), 'YYYY-MM-DD HH24:MI')  "Max Sample Time"
, to_char(trunc(sysdate)+(cast(max("Sample Time") as date) 
                        - cast(min("Sample Time") as date)),'HH24:MI:SS')  as "Lock Time Range"
,max("sql_text of Blocked User") "sql_text of Blocked User"
,count(distinct "Blocking User"||':'||"Blocking Session"||':'||"Blocking Session Serial#") "Distinct Blockers"
,min("Blocking User"||':'||"Blocking Session"||':'||"Blocking Session Serial#") "Min Blocker"
,max("Blocking User"||':'||"Blocking Session"||':'||"Blocking Session Serial#") "Max Blocker"
,max("Blocking User Event") "Max Blocking User Event"
,max("sql_id blocking") "Max sql_id blocking"
,max("sql_text of Blocking User") "Max sql_text of Blocking User"
,min("Blocking User Event") "Min Blocking User Event"
,min("sql_id blocking") "Min sql_id blocking"
,min("sql_text of Blocking User") "Min sql_text of Blocking User"
from 
(
SELECT  distinct a.snap_id "Snap Id"
, a.sample_time "Sample Time"
, (select username from dba_users du where du.user_id  = a.user_id) "Blocked User"
, a.session_id "Blocked Session" 
, a.session_serial# "Blocked Session Serial#"
, a.event "Blocked User Event"
, round(decode(a.session_state, 'ON CPU', a.wait_time, 'WAITING', a.time_waited)/1000000, 3) "Duration sec"
, a.sql_id 
, DBMS_LOB.SUBSTR(s.sql_text,4000) "sql_text of Blocked User"
--, a.inst_id
, (select username from dba_users du 
    where du.user_id = (select user_id from DBA_HIST_ACTIVE_SESS_HISTORY b 
                        where b.instance_number = a.instance_number 
                          and b.dbid = a.dbid
                          and b.snap_id = a.snap_id
                          and b.sample_id = a.sample_id
                          and b.session_id = a.blocking_session 
                          and b.session_serial#=a.blocking_session_serial# ) 
   ) "Blocking User"
, a.blocking_session "Blocking Session"
, a.blocking_session_serial# "Blocking Session Serial#"
, (select event from DBA_HIST_ACTIVE_SESS_HISTORY b 
    where b.instance_number = a.instance_number
      and b.dbid = a.dbid
      and b.snap_id = a.snap_id
      and b.sample_id = a.sample_id
      and b.session_id = a.blocking_session 
      and b.session_serial#=a.blocking_session_serial# ) "Blocking User Event"
, (select sql_id from DBA_HIST_ACTIVE_SESS_HISTORY b 
    where b.instance_number = a.instance_number 
      and b.dbid = a.dbid
      and b.snap_id = a.snap_id
      and b.sample_id = a.sample_id
      and b.session_id = a.blocking_session 
      and b.session_serial# = a.blocking_session_serial# 
   ) "sql_id blocking" 
, (select DBMS_LOB.SUBSTR(txt.sql_text,4000)
     from dba_hist_sqltext txt
    where 1=1
      and txt.dbid = a.dbid
      and txt.sql_id = (select sql_id from DBA_HIST_ACTIVE_SESS_HISTORY b 
                        where b.instance_number = a.instance_number 
                          and b.dbid = a.dbid
                          and b.snap_id = a.snap_id
                          and b.sample_id = a.sample_id
                          and b.session_id = a.blocking_session 
                          and b.session_serial#=a.blocking_session_serial# )
   ) "sql_text of Blocking User" 
--, a.blocking_session_status
--, a.module
from  DBA_HIST_ACTIVE_SESS_HISTORY a  
, dba_hist_sqltext s
where a.sql_id=s.sql_id and a.dbid = s.dbid
  and blocking_session is not null
  and snap_id between :start_snap_id and :end_snap_id
  and snap_id between nvl(:start_snap_id, snap_id) and nvl(:end_snap_id, snap_id)
  and a.sql_id = nvl(:sql_id, a.sql_id)
  and Module = nvl(:module, module) 
order by a.sample_time 
)
where "Blocked User" = nvl(:username, "Blocked User")
group by to_char(trunc("Sample Time", 'DD'),'YYYY-MM-DD')
,"Blocked User"
,"Blocked Session"
,"Blocked Session Serial#"
,"Blocked User Event"
,"SQL_ID"
having sum("Duration sec") >= :duration_sec
order by 1, 8 desc -- "Duration sec"
;
