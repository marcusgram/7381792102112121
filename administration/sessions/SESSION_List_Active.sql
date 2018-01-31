
-----------------------------------------------------------------------------------
-- Description  : Displays information on all active database sessions.
-- --------------------------------------------------------------------------------
SET LINESIZE 5000
SET PAGESIZE 1000
SET HEADING ON 
SET TRIMSPOOL OFF  
SET FEEDBACK ON 
SET ECHO ON 
SET TERMOUT ON

COLUMN username FORMAT A15
COLUMN  osuser FORMAT A15
COLUMN machine FORMAT A15
COLUMN logon_time FORMAT A20
COLUMN module FORMAT A30
COLUMN spid FORMAT A15
COLUMN lockwait FORMAT A10

COLUMN spool_time NEW_VALUE _spool_time NOPRINT
SELECT TO_CHAR(SYSDATE,'YYYYMMDD') spool_time FROM dual;

COLUMN instance_name NEW_VALUE _instance_name NOPRINT
SELECT instance_name instance_name FROM v$instance;

COLUMN host_name NEW_VALUE _host_name NOPRINT
SELECT host_name host_name FROM v$instance;

SPOOL ACTIVE_SESSIONS_&_host_name._&_instance_name._&_spool_time..out
---------- SQL -------
SELECT NVL(s.username, '(oracle)') AS username,
       s.osuser,
       s.sid,
       s.serial#,
       p.spid,
       s.lockwait,
       s.status,
       s.module,
       s.machine,
       s.program,
       TO_CHAR(s.logon_Time,'DD-MON-YYYY HH24:MI:SS') AS logon_time
FROM   v$session s,
       v$process p
WHERE  s.paddr  = p.addr
AND    s.status = 'ACTIVE'
ORDER BY s.username, s.osuser;

SET PAGESIZE 14
SPOOL OFF


----------------------------------------------------------------------------
-- Top.sql: prints details of active sessions 
-- Usage: @top, run a few times on to see dynamics of active sessions
-- Luca Canali 2002, last updated and customized for 11g, Apr 2012
----------------------------------------------------------------------------
set lines 180
col inst_sid_ser for a13
col username for a23
col serv_mod_action for a48
col tr for a2
col event for a32
col sql_id for a13
col sql_dT for 999999
col call_dT for 9999999
col W_dT for 9999
col obj# for 99999999


select 	inst_id||'_'||sid||' '||serial# inst_sid_ser,
	username||case when regexp_substr(program,' \(...') <> ' (TNS' then regexp_substr(program,' \(.+') end username,
	sql_id sql_id, 
	round((sysdate-sql_exec_start)*24*3600,1) sql_dT,
        last_call_et call_dT,
	case state when 'WAITING' then round(wait_time_micro/1000000,2) else round(time_since_last_wait_micro/1000000,2) end W_dT,
        decode(state,'WAITING',event,'CPU') event, 
	service_name||' '||substr(module,1,20)||' '||ACTION serv_mod_action,  
          nullif(row_wait_obj#,-1) obj#,decode(taddr,null,null,'NN') tr
from gv$session
where ((state='WAITING' and wait_class<>'Idle') or (state<>'WAITING' and status='ACTIVE'))
      --and audsid != to_number(sys_context('USERENV','SESSIONID')) -- this is clean but does not work on ADG so replaced by following line
      and (machine,port) <> (select machine,port from v$session where sid=sys_context('USERENV','SID')) --workaround for ADG
order by inst_id,sql_id
/



-----------------------------------------------------------------------------------
-- Description  : Displays information on all active database sessions.
-- filter on username 
-- --------------------------------------------------------------------------------
set linesize 150
column Name format a14
column SID format 9999
column PID format 99999
column TERM format a15
column OSUSER format a15
column Program format a30
column Stats format a10
column Logon_time format a20
select a.username Name, a.sid SID, a.serial#, b.spid PID,
       SUBSTR(A.TERMINAL,1,9) TERM, SUBSTR(A.OSUSER,1,9) OSUSER,
       substr(a.program,1,10) Program, a.status Status,
       to_char(a.logon_time,'MM/DD/YYYY hh24:mi') Logon_time
from v$session a, v$process b
where a.paddr = b.addr
  and a.serial# <> '1'
  and a.status = 'ACTIVE'
  and a.username like upper('%&user%') -- if you want to filter by username
order by a.logon_time;



--------------------------------------------------
REM: Script to Get Os user name with terminal name
--------------------------------------------------

SELECT
DBA_USERS.USERNAME USERNAME,
DECODE(V$SESSION.USERNAME, NULL, 'NOT CONNECTED', 'CONNECTED') STATUS,
NVL(OSUSER, '-') OSUSER,
NVL(TERMINAL,'-') TERMINAL,
SUM(DECODE(V$SESSION.USERNAME, NULL, 0,1)) SESSIONS
FROM
DBA_USERS, V$SESSION
WHERE DBA_USERS.USERNAME = V$SESSION.USERNAME (+)
GROUP BY
DBA_USERS.USERNAME,
DECODE(V$SESSION.USERNAME, NULL, 'NOT CONNECTED', 'CONNECTED'),
OSUSER,
TERMINAL
ORDER BY 1 ;

