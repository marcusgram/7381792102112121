---------------------------------------------------------------------------------------------
--Les informations utiles de la vue V$SESSION_LONGOPS sont :

--SID, SERIAL# et USERNAME qui permettent d'identifier la session et le compte utilisateur.
--SQL_ID et SQL_HASH_VALUE qui permettent d'idenfier la requete et son plan d'exécution.
--TARGET et OPNAME qui donnent de l�information sur l�objet accédé ou le type d'opération réalisée.
--START_TIME, ELAPSED_SECONDS et TIME_REMAINING qui indiquent la date et heure de d�but, les secondes �coul�es et le temps restant.
--SOFAR et TOTAL_WORK et UNITS qui pr�cisent la charge de travail d�j� r�alis�e, la charge totale � r�aliser et l�unit� de cette charge.
--------------------------------------------------------------------------------------------

set lines 180 pages 1000

SELECT a.sid||','||a.serial#, a.opname, a.target, a.target_desc, a.sofar,
       a.totalwork, a.units, a.start_time, a.last_update_time,
       a.time_remaining, a.elapsed_seconds, a.context, a.message,
       a.username, a.sql_address, a.sql_hash_value, a.qcsid
  FROM gv$session_longops a 
where a.time_remaining <> 0
  order by a.target, TIME_REMAINING desc;
  



  
COLUMN sid FORMAT 999
COLUMN serial# FORMAT 9999999
COLUMN machine FORMAT A30
COLUMN progress_pct FORMAT 99999999.00
COLUMN elapsed FORMAT A10
COLUMN remaining FORMAT A10

SELECT s.sid,
       s.serial#,
	   sl.opname,
       s.machine,
       ROUND(sl.elapsed_seconds/60) || ':' || MOD(sl.elapsed_seconds,60) elapsed,
       ROUND(sl.time_remaining/60) || ':' || MOD(sl.time_remaining,60) remaining,
       ROUND(sl.sofar/sl.totalwork*100, 2) progress_pct
FROM   v$session s,
       v$session_longops sl
WHERE  s.sid     = sl.sid
AND    s.serial# = sl.serial#;

 SID  SERIAL# OPNAME                                                           MACHINE                        ELAPSED    REMAINING  PROGRESS_PCT
---- -------- ---------------------------------------------------------------- ------------------------------ ---------- ---------- ------------
 135    11409 SYS_IMPORT_FULL_01                                               parva4117033                   152:32     1:30              99.67









SELECT SID, SERIAL#, CONTEXT, SOFAR, TOTALWORK,
       ROUND(SOFAR/TOTALWORK*100,2) "%_COMPLETE"
FROM V$SESSION_LONGOPS
WHERE OPNAME NOT LIKE '%aggregate%'
  AND TOTALWORK != 0
  AND SOFAR  != TOTALWORK;
  
   SID  SERIAL#    CONTEXT      SOFAR  TOTALWORK %_COMPLETE
---- -------- ---------- ---------- ---------- ----------
 135    11409          0        302        303      99.67







SELECT sid, username, target, opname, TO_CHAR(start_time, 'HH24:MI:SS') AS start_time, elapsed_seconds, time_remaining
FROM   v$session_longops
WHERE  time_remaining > 0
ORDER BY start_time DESC
/


 
 
