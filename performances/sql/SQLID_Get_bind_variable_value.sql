
-------------------------------------------------
-- bind values captured on DB
-- for more need to do oradebug dump errorstack 3
-- Luca Mar 2012 updated for oracle 11g
--------------------------------------------------

select * from gV$SQL_BIND_CAPTURE where sql_id='&1';

select BINDS_XML from gv$sql_monitor where sql_id='&1';


set linesize 512
set pages 50000
col LAST_CAPTURED format a30
col VALUE_STRING  format a50

select snap_id,to_char(LAST_CAPTURED,'YYYY-MM-DD HH24:MI:SS') LAST_CAPTURED,WAS_CAPTURED,NAME,VALUE_STRING 
from DBA_HIST_SQLBIND
where sql_id='&sql_id'
order by LAST_CAPTURED,NAME;
