

REM ***********************************************************************************
REM REQUIRES:   dba_indexes
REM
REM INPUTS:		1 = Index owner
REM			2 = Index name
REM ******************** Knowledge Xpert for Oracle Administration ********************

SET pages 20 lines 600 verify off feedback off
COLUMN owner                   format a20            heading "Owner"
COLUMN index_name              format a30           heading "Index"
COLUMN status                  format a7            heading "Status"
COLUMN blevel                  format 999999          heading " Tree| Level"
COLUMN leaf_blocks             format 9999999         heading " Leaf| Blk"
COLUMN distinct_keys           format 99999999       heading " # Keys"
COLUMN avg_leaf_blocks_per_key format 999999          heading " Avg| Leaf Blocks| Key"
COLUMN avg_data_blocks_per_key format 999999         heading " Avg| Data Blocks| Key"
COLUMN clustering_factor       format 99999999        heading " Cluster| Factor"
COLUMN num_rows                format 99999999       heading " Number| Rows"
COLUMN sample_size             format 99999999       heading " Sample| Size"
COLUMN last_analyzed                                heading " Analysis| Date"
REM
ttitle "Index Statistics Report"
REM
SELECT   owner, index_name, status, blevel, leaf_blocks, distinct_keys,
         avg_leaf_blocks_per_key, avg_data_blocks_per_key, clustering_factor,
         num_rows, sample_size, last_analyzed
    FROM dba_indexes
   WHERE owner LIKE UPPER ('&&iowner')
     --AND index_name LIKE UPPER ('&&iname')
     AND num_rows > 0
     AND BLEVEL > 1 
ORDER BY 1, 2;




-----------------------------------------------
-- for the given table
-- list the indexes on the table
--
-- parameter 1 = owner
-- parameter 2 = table_name
--
-- usage is: @SHOWINDEXES <owner> <table_name>
-----------------------------------------------

set verify off

break on index_name skip 1
col column_name format a30

select index_name,column_name
,(select index_type from dba_indexes b where b.owner = a.index_owner and b.index_name = a.index_name) index_type
,(select uniqueness from dba_indexes b where b.owner = a.index_owner and b.index_name = a.index_name) uniqueness
,(select tablespace_name from dba_indexes b where b.owner = a.index_owner and b.index_name = a.index_name) tablespace_name
from dba_ind_columns a
where table_name = upper('&&2')
and table_owner = upper('&&1')
order by 1,column_position
/


-- -----------------------------------------------------------------------------------
-- Description  : Displays information about specified indexes.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @show_indexes (schema) (table-name or all)
-- -----------------------------------------------------------------------------------
SET VERIFY OFF
SET LINESIZE 200

COLUMN table_owner FORMAT A20
COLUMN index_owner FORMAT A20
COLUMN index_type FORMAT A12
COLUMN tablespace_name FORMAT A20

SELECT table_owner,
       table_name,
       owner AS index_owner,
       index_name,
       tablespace_name,
       num_rows,
       status,
       index_type
FROM   dba_indexes
WHERE  table_owner = UPPER('&tabowner')
AND    table_name = DECODE(UPPER('&tabname'), 'ALL', table_name, UPPER('&tabname'))
ORDER BY table_owner, table_name, index_owner, index_name;
