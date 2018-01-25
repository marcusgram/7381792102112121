

spool resultat.html col last_analyzed FOR a13

SET feedback OFF col last_analyzed FOR a13
SET termout OFF
SET trimspool OFF col client_name FOR a40 col attributes FOR a60
SET lines 180
SET pagesize 1000 echo ON markup html ON
SELECT * FROM v$instance;

prompt '1)Statistics for System'
SELECT * FROM sys.aux_stats$;

ALTER session SET nls_date_format='MM/DD/YYYY HH24:MI:SS';

prompt '2)Statistics for SYS tables'
SELECT NVL(TO_CHAR(last_analyzed, 'MM/DD/YYYY HH24:MI:SS'), 'NO STATS') last_analyzed,
  COUNT(*) dictionary_tables
FROM dba_tables
WHERE owner = 'SYS'
GROUP BY TO_CHAR(last_analyzed, 'MM/DD/YYYY HH24:MI:SS')
ORDER BY 1 DESC;

prompt '3)Statistics for Fixed Objects'
SELECT NVL(TO_CHAR(last_analyzed, 'MM/DD/YYYY HH24:MI:SS'), 'NO STATS') last_analyzed,
  COUNT(*) fixed_objects
FROM dba_tab_statistics
WHERE object_type = 'FIXED TABLE'
GROUP BY TO_CHAR(last_analyzed, 'MM/DD/YYYY HH24:MI:SS')
ORDER BY 1 DESC;
prompt 'Histograms'
SELECT OWNER,
  TABLE_NAME,
  HISTOGRAM
FROM DBA_TAB_COL_STATISTICS
WHERE OWNER NOT IN ('SYSTEM','SYS','DBSNMP','SYSMAN')
GROUP BY HISTOGRAM;

prompt '4)Statistics for Schema objects'
SELECT *
FROM DBA_TAB_STATISTICS
WHERE OWNER NOT IN ('SYSTEM','SYS','DBSNMP','SYSMAN');

prompt '5)Default values for ghatring stats'
SELECT DBMS_STATS.GET_PREFS ('AUTOSTATS_TARGET'),
  DBMS_STATS.GET_PREFS ('CASCADE'),
  DBMS_STATS.GET_PREFS ('DEGREE'),
  DBMS_STATS.GET_PREFS ('ESTIMATE_PERCENT'),
  DBMS_STATS.GET_PREFS ('METHOD_OPT'),
  DBMS_STATS.GET_PREFS ('NO_INVALIDATE'),
  DBMS_STATS.GET_PREFS ('GRANULARITY'),
  DBMS_STATS.GET_PREFS ('PUBLISH'),
  DBMS_STATS.GET_PREFS ('INCREMENTAL'),
  DBMS_STATS.GET_PREFS ('STALE_PERCENT')
FROM dual;

prompt '6)Automatic task'
SELECT client_name,
  status,
  attributes,
  service_name
FROM dba_autotask_client;
SELECT SUM(space)/1024/1024 FROM dba_recyclebin ORDER BY owner;


prompt 'Histograms'
SELECT OWNER,TABLE_NAME,count(column_name) COLUMN_NAME,HISTOGRAM 
FROM DBA_TAB_COL_STATISTICS 
where OWNER not in ('SYSTEM','SYS','DBSNMP','SYSMAN') 
group by OWNER,TABLE_NAME,HISTOGRAM;


prompt 'Statistics for Schema objects'
select * from DBA_TAB_STATISTICS 
where OWNER not in ('SYSTEM','SYS','DBSNMP','SYSMAN');


SELECT a.ksppinm "Parameter",
  b.ksppstvl "Session Value",
  c.ksppstvl "Instance Value"
FROM x$ksppi a,
  x$ksppcv b,
  x$ksppsv c
WHERE a.indx = b.indx
AND a.indx   = c.indx
AND a.ksppinm LIKE '/_%read_count' ESCAPE '/';

spool OFF
EXIT
