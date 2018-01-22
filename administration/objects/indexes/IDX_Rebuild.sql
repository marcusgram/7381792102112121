REM:**********************************************************************************************
REM: SCRIPT FOR Database Informations : Index Rebuild ONLINE (NOPARALLEL) 
REM:FileName: indexreb.sql
****************************************************************************************************

SET HEADING OFF
SET FEEDBACK OFF
SET LINESIZE 200
SET PAGESIZE 0
SPOOL rebtemp.sql
SELECT 'SELECT to_char(SYSDATE,''YYYY/MM/DD HH24:MI:SS'') FROM dual;' FROM dual;
SELECT 'ALTER INDEX '||owner||'.'||index_name||' REBUILD TABLESPACE '||tablespace_name||' ONLINE;'
        FROM dba_indexes
        WHERE owner IN ('&ownername','&ownername')
        ORDER BY owner, index_name;
SELECT 'SELECT to_char(SYSDATE,''YYYY/MM/DD HH24:MI:SS'') FROM dual;' FROM dual;
SPOOL OFF
SET ECHO ON
SET FEEDBACK ON
SPOOL Al_Indexes.log
@rebtemp.sql
spool off


-- -----------------------------------------------------------------------------------
-- Description  : Rebuilds the specified index, or all indexes.
-- Call Syntax  : @rebuild_index (index-name or all) (schema-name)
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'ALTER INDEX ' || a.index_name || ' REBUILD PARALLEL;'
FROM   all_indexes a
WHERE  index_name  = DECODE(Upper('&1'),'ALL',a.index_name,Upper('&1'))
AND    table_owner = Upper('&2')
ORDER BY 1
/
SPOOL OFF

-- Comment out following line to prevent immediate run
--@temp.sql







set pages 200
set lines 200

Select 'alter index ' || owner || '.' || index_name || ' rebuild online;'
from dba_indexes where status = 'INVALID'
/




------------------------------------------------------------
--Run the query below to find out how skewed each index is. 
--This query checks on all indexes that are on emp table.
------------------------------------------------------------
select index_name, blevel, 
decode(blevel,0,'OK BLEVEL',1,'OK BLEVEL',2, 
'OK BLEVEL',3,'OK BLEVEL',4,'OK BLEVEL','BLEVEL HIGH') OK 
from user_indexes where table_name='&1';

=============================================================================
BLEVEL (or branch level) is part of the B-tree index format 
and relates to the number of times Oracle has to narrow its search 
on the index while searching for a particular record. In some cases, 
a separate disk hit is requested for each BLEVEL. 
If the BLEVEL were to be more than 4, it is recommended to rebuild the index. 
=============================================================================





--------------------------------------------------------
--Run the following query to find out PCT_DELETED ratio.
--------------------------------------------------------
select DEL_LF_ROWS*100/decode(LF_ROWS, 0, 1, LF_ROWS) PCT_DELETED, 
 (LF_ROWS-DISTINCT_KEYS)*100/ decode(LF_ROWS,0,1,LF_ROWS) DISTINCTIVENESS 
 from index_stats 
 where NAME='EMP_EMPNO_PK';  

=================================================================================================================
The PCT_DELETED column shows the percent of leaf entries (i.e. index entries) 
that have been deleted and remain unfilled. The more deleted entries exist on an index, 
the more unbalanced the index becomes. If the PCT_DELETED is 20% or higher, the index is candidate for rebuilding. 
If you can afford to rebuild indexes more frequently, then do so if the value is higher than 10%. 
Leaving indexes with high PCT_DELETED without rebuild might cause excessive redo allocation on some systems.

The DISTINCTIVENESS column shows how often a value for the column(s) of the index is repeated on average. 
For example, if a table has 10000 records and 9000 distinct SSN values, the formula would result in (10000-9000) x 100 / 10000 = 10. 
This shows a good distribution of values. 
If, however, the table has 10000 records and only 2 distinct SSN values, the formula would result in (10000-2) x 100 /10000 = 99.98. 
This shows that there are very few distinct values as a percentage of total records in the column. 
Such columns are not candidates for a rebuild but good candidates for bitmapped indexes
=================================================================================================================
