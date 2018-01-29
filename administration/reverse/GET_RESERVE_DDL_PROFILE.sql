set heading off
set feedback off
set linesize 1000
set trimspool on
set verify off
set termout off
set embedded on
set long 200000
set pages 0
SELECT DBMS_METADATA.GET_DDL('PROFILE', pr.name) ddl_string
FROM (SELECT DISTINCT pi.name 
FROM sys.profname$ pi
WHERE pi.name != 'DEFAULT') pr
/