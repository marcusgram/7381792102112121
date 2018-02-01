
Calculate UNDO_RETENTION  for given UNDO Tabespace
---------------------------------------------------

You can choose to allocate a specific size for the UNDO tablespace and then 
set the UNDO_RETENTION parameter to an optimal value according to the UNDO size and the database activity. 
If your disk space is limited and you do not want to allocate more space than necessary to the UNDO tablespace, this is the way to proceed. 
The following query will help you to optimize the UNDO_RETENTION parameter:


1/ Actual Undo Size
-------------------

SELECT SUM(a.bytes) "UNDO_SIZE"
  FROM v$datafile a,
       v$tablespace b,
       dba_tablespaces c
 WHERE c.contents = 'UNDO'
   AND c.status = 'ONLINE'
   AND b.name = c.tablespace_name
   AND a.ts# = b.ts#;


UNDO_SIZE
----------
8.3886E+10
  
  
  
  
2/Undo Blocks per Second
-------------------------
SELECT MAX(undoblks/((end_time-begin_time)*3600*24))
      "UNDO_BLOCK_PER_SEC"
  FROM v$undostat;


UNDO_BLOCK_PER_SEC
------------------
        823.768333

		
		
		
3/DB Block Size
---------------
SELECT TO_NUMBER(value) "DB_BLOCK_SIZE [KByte]"
 FROM v$parameter
WHERE name = 'db_block_size';

DB_BLOCK_SIZE [Byte]
--------------------
                8192
				
				
				
4/Optimal Undo Retention
------------------------

8.3886E+10 / (823.768333 * 8192) = 16'401 [Sec]

Using Inline Views, you can do all in one query!
------------------------------------------------

SELECT d.undo_size/(1024*1024) "ACTUAL UNDO SIZE [MByte]",
       SUBSTR(e.value,1,25) "UNDO RETENTION [Sec]",
       ROUND((d.undo_size / (to_number(f.value) *
       g.undo_block_per_sec))) "OPTIMAL UNDO RETENTION [Sec]"
  FROM (
       SELECT SUM(a.bytes) undo_size
          FROM v$datafile a,
               v$tablespace b,
               dba_tablespaces c
         WHERE c.contents = 'UNDO'
           AND c.status = 'ONLINE'
           AND b.name = c.tablespace_name
           AND a.ts# = b.ts#
       ) d,
       v$parameter e,
       v$parameter f,
       (
       SELECT MAX(undoblks/((end_time-begin_time)*3600*24))
              undo_block_per_sec
         FROM v$undostat
       ) g
WHERE e.name = 'undo_retention'
  AND f.name = 'db_block_size'
/


ACTUAL UNDO SIZE [MByte] UNDO RETENTION [Sec]      OPTIMAL UNDO RETENTION [Sec]
------------------------ ------------------------- ----------------------------
                   80000 38000                                            12431 : Avec 80G d'undo, on peut esperer 12500 sec de retention => Plus d'espace à prevoir !!
				   
				   
				   
				   
				   
				   
Calculate Needed UNDO Size for given Database Activity
-------------------------------------------------------

If you are not limited by disk space, then it would be better to choose the UNDO_RETENTION time that is best for you (for FLASHBACK, etc.). 
Allocate the appropriate size to the UNDO tablespace according to the database activity:



Again, all in one query:

SELECT d.undo_size/(1024*1024) "ACTUAL UNDO SIZE [MByte]",
       SUBSTR(e.value,1,25) "UNDO RETENTION [Sec]",
       (TO_NUMBER(e.value) * TO_NUMBER(f.value) *
       g.undo_block_per_sec) / (1024*1024) 
      "NEEDED UNDO SIZE [MByte]"
  FROM (
       SELECT SUM(a.bytes) undo_size
         FROM v$datafile a,
              v$tablespace b,
              dba_tablespaces c
        WHERE c.contents = 'UNDO'
          AND c.status = 'ONLINE'
          AND b.name = c.tablespace_name
          AND a.ts# = b.ts#
       ) d,
      v$parameter e,
       v$parameter f,
       (
       SELECT MAX(undoblks/((end_time-begin_time)*3600*24))
         undo_block_per_sec
         FROM v$undostat
       ) g
 WHERE e.name = 'undo_retention'
  AND f.name = 'db_block_size'
/				   
				   
				   
ACTUAL UNDO SIZE [MByte] UNDO RETENTION [Sec]      NEEDED UNDO SIZE [MByte]
------------------------ ------------------------- ------------------------
           80000         38000                                   244556.224 => 250 Go d'UNDO sont à envisager

