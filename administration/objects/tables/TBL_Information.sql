REM:**********************************************************************************************
REM: Script : All information for a Table
REM:FileName: allineone.sql
****************************************************************************************************

SPOOL D:\\ALLINONE&tbl.TXT
set lines 300
col data_type for a12
select a.table_name
,      a.tablespace_name
,      CURSOR(select b.column_name
              ,      b.data_type
              ,      b.column_id
              from   user_tab_columns b
              where  b.table_name = a.table_name
              order  by
                     b.column_id) as column_info
,      CURSOR(select c.index_name
              ,      c.uniqueness
              ,      c.tablespace_name
              from   user_indexes c
              where  c.table_name = a.table_name) as index_info
,      CURSOR(select d.constraint_name
              ,      d.constraint_type
              from   user_constraints d
              where  d.table_name = a.table_name) as constraint_info
from   user_tables a
where  a.table_name = 'Table&'
/
SPOOL OFF




-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/monitoring/show_tables.sql
-- Description  : Displays information about specified tables.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @show_tables (schema)
-- -----------------------------------------------------------------------------------
SET VERIFY OFF
SET LINESIZE 200

SELECT table_name,
       tablespace_name,
       num_rows,
       avg_row_len,
       blocks,
       empty_blocks
FROM   dba_tables
WHERE  owner = UPPER('&1')
ORDER BY table_name
;




-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/monitoring/show_tables.sql
-- Description  : Displays information about specified tables.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @show_tables (schema,tablename)
-- -----------------------------------------------------------------------------------
SET VERIFY OFF
SET LINESIZE 200

SELECT table_name,
       tablespace_name,
       num_rows,
       avg_row_len,
       blocks,
       empty_blocks
FROM   dba_tables
WHERE  owner = UPPER('&1')
AND table_name= UPPER('&2')
;
