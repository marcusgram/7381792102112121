

A/Undo parameters
-----------------
select nam.ksppinm NAME, val.KSPPSTVL VALUE 
from x$ksppi nam, x$ksppsv val 
where nam.indx = val.indx and (nam.ksppinm like '%undo%' 
or nam.ksppinm in ('_first_spare_parameter','_smu_debug_mode')) order by 1;


 
B/What are the various statuses for Undo Extents?
-------------------------------------------------
SELECT DISTINCT STATUS, SUM(BYTES), COUNT(*) FROM DBA_UNDO_EXTENTS GROUP BY STATUS;
 

C/Tuned Retention
-----------------
SELECT MAX(TUNED_UNDORETENTION),
MAX(MAXQUERYLEN), 
MAX(NOSPACEERRCNT), 
MAX(EXPSTEALCNT) FROM V$UNDOSTAT;


SELECT BEGIN_TIME, 
END_TIME, 
TUNED_UNDORETENTION, 
MAXQUERYLEN, 
MAXQUERYID, 
NOSPACEERRCNT, 
EXPSTEALCNT, 
UNDOBLKS, 
TXNCOUNT 
FROM V$UNDOSTAT
ORDER BY BEGIN_TIME ASC;


D/The size details and auto-extend setting for the UNDO Tablespace
------------------------------------------------------------------
SELECT FILE_ID, BYTES/1024/1024 AS "BYTES (MB)", MAXBYTES/1024/1024 AS "MAXBYTES (MB)",
 AUTOEXTENSIBLE FROM DBA_DATA_FILES 
WHERE TABLESPACE_NAME='UNDOTBS1'
