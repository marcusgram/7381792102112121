

-----------------------
--dbms_stats preference
-----------------------

--Filed under: 11g,oracle — mdinh @ 2:33 am 
--Notes for how to set and get preferences from dbms_stats.

--TABLE Level:
-============
exec DBMS_STATS.SET_TABLE_PREFS (USER,'FCT_TABLE,'INCREMENTAL','FALSE');

SELECT 
  owner, table_name,
  DBMS_STATS.get_prefs(ownname=>USER,tabname=>table_name,pname=>'INCREMENTAL') incremental,
  DBMS_STATS.get_prefs(ownname=>USER,tabname=>table_name,pname=>'GRANULARITY') granularity,
  DBMS_STATS.get_prefs(ownname=>USER,tabname=>table_name,pname=>'STALE_PERCENT') stale_percent,
  DBMS_STATS.get_prefs(ownname=>USER,tabname=>table_name,pname=>'ESTIMATE_PERCENT') estimate_percent,
  DBMS_STATS.get_prefs(ownname=>USER,tabname=>table_name,pname=>'CASCADE') cascade,
  DBMS_STATS.get_prefs(pname=>'METHOD_OPT') method_opt
FROM dba_tables
WHERE table_name like 'FCT%'
ORDER BY owner, table_name;
-- Note: Use the DBA view versus the above for better performance

-- The previous statement adjusts the threshold for the table EMPS owned by HR to 15%
exec dbms_stats.set_table_prefs('HR', 'EMPS', 'STALE_PERCENT', '15')

select * from DBA_TAB_STAT_PREFS;





--SCHEMA Level:
-=============
exec DBMS_STATS.SET_SCHEMA_PREFS (USER,'STALE_PERCENT','8');

SELECT 
  username,
  DBMS_STATS.get_prefs(ownname=>USER,pname=>'INCREMENTAL') incremental,
  DBMS_STATS.get_prefs(ownname=>USER,pname=>'GRANULARITY') granularity,
  DBMS_STATS.get_prefs(ownname=>USER,pname=>'STALE_PERCENT') stale_percent,
  DBMS_STATS.get_prefs(ownname=>USER,pname=>'ESTIMATE_PERCENT') estimate_percent,
  DBMS_STATS.get_prefs(ownname=>USER,pname=>'CASCADE') cascade,
  DBMS_STATS.get_prefs(pname=>'METHOD_OPT') method_opt
FROM dba_users
WHERE username like '%WH'
ORDER BY username;







--DATABASE Level:
-===============
exec DBMS_STATS.SET_GLOBAL_PREFS('METHOD_OPT','FOR ALL COLUMNS SIZE REPEAT');

SELECT 
  DBMS_STATS.get_prefs(pname=>'INCREMENTAL') incremental,
  DBMS_STATS.get_prefs(pname=>'GRANULARITY') granularity,
  DBMS_STATS.get_prefs(pname=>'STALE_PERCENT') publish,
  DBMS_STATS.get_prefs(pname=>'ESTIMATE_PERCENT') estimate_percent,
  DBMS_STATS.get_prefs(pname=>'CASCADE') cascade,
  DBMS_STATS.get_prefs(pname=>'METHOD_OPT') method_opt,
  DBMS_STATS.get_prefs(pname=>'AUTOSTATS_TARGET') mode_auto  
FROM dual;

