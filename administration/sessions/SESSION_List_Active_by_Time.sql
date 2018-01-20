
-------------------------------------------------------------
-- Lister les sessions actives par temps d'activité ordre DEC
-- v$session
-- v$sql sql
-------------------------------------------------------------

select 
sid,username,
sql.sql_id,
FIRST_LOAD_TIME,
to_char(logon_time,'dd-mm-yy hh:mi:ss') "LOGON",
floor(last_call_et/3600)||':'||
floor(mod(last_call_et,3600)/60)||':'||
mod(mod(last_call_et,3600),60) "DUREE (hh:mm:ss)",
disk_reads,
buffer_gets,
wait_class,
state,
user_io_wait_time,
program,
sql_text
from 
v$session,
v$sql sql
where sql_hash_value = sql.hash_value
and sql_address = sql.address
and status = 'ACTIVE'
and type='USER'
and disk_reads > 0
and username not in ('SYS','SYSTEM','OEMPF','EIM_BATCH','REPRISE_PCOM','SADMIN')
order by last_call_et 
;




---------------------------------------------------------
-- Lister les sessions actives avec leur durée d'activité
-- v$session
---------------------------------------------------------

set echo off
set linesize 95
set head on
set feedback on
col sid head "Sid" form 9999 trunc
col serial# form 99999 trunc head "Ser#"
col username form a8 trunc
col osuser form a7 trunc
col machine form a20 trunc head "Client|Machine"
col program form a15 trunc head "Client|Program"
col login form a11
col "last call"  form 9999999 trunc head "Last Call|In Secs"
col status form a6 trunc

select sid,serial#,substr(username,1,10) username,substr(osuser,1,10) osuser,
	 substr(program||module,1,15) program,substr(machine,1,22) machine,
	 to_char(logon_time,'ddMon hh24:mi') login,
	 last_call_et "last call",status
from v$session 
where status='ACTIVE'
order by 1
/
                              Client          Client                           Last Call
  Sid   Ser# USERNAME OSUSER  Program         Machine              LOGIN         In Secs STATUS
----- ------ -------- ------- --------------- -------------------- ----------- --------- ------
    1      1          oracle  oracle@parva411 parva4119817         15Dec 13:31   8541663 ACTIVE
    2      1          oracle  oracle@parva411 parva4119817         15Dec 13:31   8541662 ACTIVE





---------------------------------------------------------
-- Lister les sessions actives avec leur durée d'activité
-- v$session
--------------------------------------------------------

set linesize 1000
SELECT USERNAME, 
       TERMINAL, 
       STATUS,	
       PROGRAM, 
       SQL_ID, 
       LOGON_TIME, 
       ROUND((SYSDATE-LOGON_TIME)*(24*60),1) as MINUTES_LOGGED_ON, 
       ROUND(LAST_CALL_ET/60,1) as Minutes_FOR_CURRENT_SQL  
  From v$session 
 WHERE STATUS='ACTIVE' 
   AND USERNAME IS NOT NULL
ORDER BY MINUTES_LOGGED_ON DESC;


USERNAME                       TERMINAL                       STATUS   PROGRAM                                          SQL_ID        LOGON_TIM MINUTES_LOGGED_ON MINUTES_FOR_CURRENT_SQL
------------------------------ ------------------------------ -------- ------------------------------------------------ ------------- --------- ----------------- -----------------------
GEN$HUIS                                                      ACTIVE   tel_drop_admin@parva4119184 (TNS V1-V3)                        21-MAR-16            2522.5                  2395.6
GEN$HUIS                                                      ACTIVE   tel_direct_admin@parva4119184 (TNS V1-V3)                      21-MAR-16            2522.5                  2492.1
SYS                            pts/3                          ACTIVE   sqlplus@parva4119817 (TNS V1-V3)                 7brx025nsqxur 23-MAR-16               9.9                       0




-------------------------------------------------------------
-- Lister les sessions actives avec + de 2 heures d'activité
-- v$session,
-- v$sql sql
-------------------------------------------------------------

set linesize
select 
sid,username,
sql.sql_id,
FIRST_LOAD_TIME,
to_char(logon_time,'dd-mm-yy hh:mi:ss') "LOGON",
floor(last_call_et/3600)||':'||
floor(mod(last_call_et,3600)/60)||':'||
mod(mod(last_call_et,3600),60) "DUREE (hh:mm:ss)",
disk_reads,
buffer_gets,
wait_class,
state,
user_io_wait_time,
program
--,sql_text
from 
v$session,
v$sql sql
where sql_hash_value = sql.hash_value
and sql_address = sql.address
and status = 'ACTIVE'
and type='USER'
and disk_reads > 0
and last_call_et > 1000
and username not in ('SYS','SYSTEM','OEMPF','EIM_BATCH','REPRISE_PCOM','SADMIN')
order by last_call_et desc;







-----------------------------------------------------
-- les sessions toujours en cours avec temps SQL > 1h
-- genere les KILL SESSION adequates
-- v$sql_monitor
----------------------------------------------------

with MY_SQLMONITOR AS
(SELECT *
     FROM
       (SELECT status,
	     SID thsid,
        SESSION_SERIAL#, 
         username thusrn,
         sql_id thsqlid,
         TO_CHAR(sql_exec_start,'dd-mon-yyyy hh24:mi:ss') AS sql_exec_start,
		 floor(trunc(elapsed_time/1000000)/86400) || 'd ' || to_char(to_date(MOD(ROUND(elapsed_time/1000000), 86400),'SSSSS'),'hh24"h" mi"m" ss"s"') thtte ,
         ROUND(cpu_time    /1000000) AS "CPU (s)",
         buffer_gets,
         ROUND(physical_read_bytes /(1024*1024)) AS "Phys reads (MB)",
         ROUND(physical_write_bytes/(1024*1024)) AS "Phys writes (MB)"
		 --SQL_TEXT
       FROM v$sql_monitor
	   WHERE status = 'EXECUTING'
	   AND ROUND(elapsed_time/1000000) > 3600
       AND username not in ('SYS','SYSTEM','OEMPF','EIM_BATCH','REPRISE_PCOM','SADMIN')
       ORDER BY elapsed_time DESC
       )
     WHERE rownum<=10)
SELECT thtte DUREE
,thusrn USERNAME
,thsqlid SQL_ID,'ALTER SYSTEM KILL SESSION ''' || S.thsid || ',' || S.session_serial# || ''' IMMEDIATE;' AS ALTER_KILL_SESSION_DDL 
FROM MY_SQLMONITOR S
;







----------------------------------------------------------------------------
Instructions provided describe how to list all connected sessions and report 
how long the sessions have been idle (the length of time since the session last executed a SQL statement).

Procedure

The following anonymous PL/SQL procedure reports each session 
and how long the session has been IDLE (if the time reported is greater than 0). 

Executing the procedure requires SELECT privileges on the V$SESSION table. 
Either execute the anonymous PL/SQL procedure as the SYS or SYSTEM user in SQL*Plus.
---------------------------------------------------------------------------

set serveroutput on;
set linesize 1000;

DECLARE
    
      CURSOR session_cursor IS 
        SELECT username, sid, last_call_et
        FROM v$session
        WHERE username IS NOT NULL AND username NOT IN ('SYS','SYSTEM')
        ORDER BY last_call_et;
    
     num_mins        NUMBER;
     num_mins_sec    NUMBER;
     wait_secs       NUMBER;
     num_hours       NUMBER;
     num_hours_min   NUMBER;
     wait_mins       NUMBER;
     num_days        NUMBER;
     num_days_hours  NUMBER;
     wait_hours      NUMBER;
     wait_char_mins  VARCHAR2(4);
     wait_char_secs  VARCHAR2(4);
   
   BEGIN
   
     DBMS_OUTPUT.PUT_LINE(chr(10));
   
     FOR idle_time IN session_cursor LOOP
   
     -- Total number of seconds waited...
   
       num_mins := trunc(idle_time.last_call_et/60);
       num_mins_sec := num_mins * 60;
       wait_secs := idle_time.last_call_et - num_mins_sec;
   
     -- Total number of minutes waited...
   
       num_hours := trunc(num_mins/60);
       num_hours_min := num_hours * 60;
       wait_mins := num_mins - num_hours_min;
   
     -- Total number of hours waited...
   
       num_days := trunc(num_hours/24);
       num_days_hours := num_days * 24;
       wait_hours := num_hours - num_days_hours;
   
       DBMS_OUTPUT.PUT('User '||idle_time.USERNAME||'('||idle_time.SID||') has been idle for '||num_days||' day(s) '||wait_hours||':');
     
       IF wait_mins < 10 THEN
         wait_char_mins := '0'||wait_mins||'';
         DBMS_OUTPUT.PUT(''||wait_char_mins||':');
        ELSE
         DBMS_OUTPUT.PUT(''||wait_mins||':');
       END IF;
   
       IF wait_secs < 10 THEN
         wait_char_secs := '0'||wait_secs||'';
         DBMS_OUTPUT.PUT(''||wait_char_secs||'');
       ELSE
         DBMS_OUTPUT.PUT(''||wait_secs||'');
       END IF;
     
       DBMS_OUTPUT.NEW_LINE;
   
     END LOOP;
   
   END;
   /


User GEN$HUIS(1155) has been idle for 0 day(s) 0:00:01
User GEN$HUIS(1149) has been idle for 0 day(s) 0:00:01
User GEN$HUIS(698) has been idle for 0 day(s) 0:00:02
User GEN$HUIS(932) has been idle for 0 day(s) 0:01:54
User GEN$HUIS(1609) has been idle for 0 day(s) 0:01:54
User GEN$HUIS(1385) has been idle for 0 day(s) 0:01:54
User GEN$HUIS(1151) has been idle for 0 day(s) 0:01:54
User GEN$HUIS(692) has been idle for 0 day(s) 0:01:54
User LASERMIGR(9) has been idle for 0 day(s) 18:46:05
User LASERMIGR(1607) has been idle for 0 day(s) 18:50:24

