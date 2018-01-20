
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

