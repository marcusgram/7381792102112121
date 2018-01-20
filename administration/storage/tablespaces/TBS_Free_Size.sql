
-------------------------------------------------------------------------------------------------
-- The following script displays the percentage of free space left in a tablespace and data file:
-------------------------------------------------------------------------------------------------

SET PAGESIZE 100 LINES 132 ECHO OFF VERIFY OFF FEEDB OFF SPACE 1 TRIMSP ON
COMPUTE SUM OF a_byt t_byt f_byt ON REPORT
BREAK ON REPORT ON tablespace_name ON pf
COL tablespace_name FOR A17 TRU HEAD 'Tablespace|Name'
COL file_name FOR A40 TRU HEAD 'Filename'
COL a_byt FOR 9,990.999 HEAD 'Allocated|GB'
COL t_byt FOR 9,990.999 HEAD 'Current|Used GB'
COL f_byt FOR 9,990.999 HEAD 'Current|Free GB'
COL pct_free FOR 990.0 HEAD 'File %|Free'
COL pf FOR 990.0 HEAD 'Tbsp %|Free'
COL seq NOPRINT
DEFINE b_div=1073741824
--
SELECT 1 seq, b.tablespace_name, nvl(x.fs,0)/y.ap*100 pf, b.file_name file_name,
b.bytes/&&b_div a_byt, NVL((b.bytes-SUM(f.bytes))/&&b_div,b.bytes/&&b_div) t_byt,
NVL(SUM(f.bytes)/&&b_div,0) f_byt, NVL(SUM(f.bytes)/b.bytes*100,0) pct_free
FROM dba_free_space f, dba_data_files b
,(SELECT y.tablespace_name, SUM(y.bytes) fs
FROM dba_free_space y GROUP BY y.tablespace_name) x
,(SELECT x.tablespace_name, SUM(x.bytes) ap
FROM dba_data_files x GROUP BY x.tablespace_name) y
WHERE f.file_id(+) = b.file_id
AND x.tablespace_name(+) = y.tablespace_name
and y.tablespace_name = b.tablespace_name
AND f.tablespace_name(+) = b.tablespace_name
GROUP BY b.tablespace_name, nvl(x.fs,0)/y.ap*100, b.file_name, b.bytes
UNION
SELECT 2 seq, tablespace_name,
j.bf/k.bb*100 pf, b.name file_name, b.bytes/&&b_div a_byt,
a.bytes_used/&&b_div t_byt, a.bytes_free/&&b_div f_byt,
a.bytes_free/b.bytes*100 pct_free
FROM v$temp_space_header a, v$tempfile b
,(SELECT SUM(bytes_free) bf FROM v$temp_space_header) j
,(SELECT SUM(bytes) bb FROM v$tempfile) k
WHERE a.file_id = b.file#
ORDER BY 1,2,4,3;



Tablespace        Tbsp %                                           Allocated    Current    Current File %
Name                Free Filename                                         GB    Used GB    Free GB   Free
----------------- ------ ---------------------------------------- ---------- ---------- ---------- ------
DATA0001            69.2 /apps/oracledata/DEL1FRR0/data0001/data0      1.000      0.308      0.692   69.2
INDX0001             5.3 /apps/oracledata/DEL1FRR0/indx0001/indx0      0.133      0.126      0.007    5.3
STATSPACK           99.2 /apps/oracledata/DEL1FRR0/osys3/stat0001      0.124      0.001      0.123   99.2
SYSAUX              26.5 /apps/oracledata/DEL1FRR0/osys2/sysaux01      0.977      0.718      0.259   26.5
SYSTEM              29.8 /apps/oracledata/DEL1FRR0/osys1/sys01.db      0.977      0.686      0.291   29.8
TOOLS               98.4 /apps/oracledata/DEL1FRR0/osys3/tol01.db      0.062      0.001      0.061   98.4
UNDOTBS1            40.3 /apps/oracledata/DEL1FRR0/osys2/undo01.d      0.781      0.467      0.315   40.3
USR                 99.0 /apps/oracledata/DEL1FRR0/data0001/usr.d      0.098      0.001      0.097   99.0
TEMP                 0.0 /apps/oracledata/DEL1FRR0/osys3/tmp01.db      0.244      0.244      0.000    0.0
***************** ******                                          ---------- ---------- ----------
                                                                       4.395      2.551      1.843






WITH
files AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       tablespace_name,
       SUM(DECODE(autoextensible, 'YES', maxbytes, bytes)) / 1024 / 1024 / 1024 total_gb
  FROM dba_data_files
 GROUP BY
       tablespace_name
),
segments AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       tablespace_name,
       SUM(bytes) / 1024 / 1024 / 1024 used_gb
  FROM dba_segments
 GROUP BY
       tablespace_name
),
tablespaces AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       files.tablespace_name,
       ROUND(files.total_gb, 1) total_gb,
       ROUND(segments.used_gb, 1) used_gb,
       ROUND(100 * segments.used_gb / files.total_gb, 1) pct_used
  FROM files,
       segments
 WHERE files.total_gb > 0
   AND files.tablespace_name = segments.tablespace_name(+)
 ORDER BY
       files.tablespace_name
),
total AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       'Total' tablespace_name,
       SUM(total_gb) total_gb,
       SUM(used_gb) used_gb,
       ROUND(100 * SUM(used_gb) / SUM(total_gb), 1) pct_used
  FROM tablespaces
)
SELECT tablespace_name,
       total_gb,
       used_gb,
       pct_used
  FROM tablespaces
 UNION ALL
SELECT tablespace_name,
       total_gb,
       used_gb,
       pct_used
  FROM total;



TABLESPACE_NAME                  TOTAL_GB    USED_GB   PCT_USED
------------------------------ ---------- ---------- ----------
DATA0001                               30          0          0
EIM_ADDR_PER_DATA                      30
EIM_ADDR_PER_INDEX                     30
EIM_CONTACT_DATA                       30
EIM_CONTACT_INDEX                      30
EIM_CON_DTL_DATA                       30
EIM_CON_DTL_INDEX                      30
EIM_CON_LOY_DATA                       30
EIM_CON_LOY_INDEX                      30
EIM_GROUP_DATA                         30
EIM_GROUP_INDEX                        30
EIM_OTHER_DATA                         30        1.3        4.2
EIM_OTHER_INDEX                        30        1.5          5
ERR_DATA                               30        1.1        3.5
INDX0001                               30        2.1        6.8
PURGE_DATA                             30         .3         .9
PURGE_INDEX                            30          0         .1
REPRISE_PCOM_DATA                      30        7.5       25.1
REPRISE_PCOM_INDEX                     30        3.5       11.5
STATSPACK                              30          0          0
SYSAUX                                 30        6.5       21.8
SYSTEM                                 30          1        3.4
S_1M_INDEX                            120       94.5       78.8
S_4M_DATA                              60       31.5       52.5
S_50M_DATA                             30        5.8       19.4
S_60M_DATA                             60       28.6       47.7
S_70M_DATA                             30       15.4       51.3
S_8M_DATA                              30       14.6       48.8
S_ADDR_INDEX                           30        5.3       17.7
S_ADDR_PER_INDEX                       30        6.4       21.3
S_BU_DATA                              30          0          0
S_BU_INDEX                             30          0          0
S_CONTACT_DATA                         30       14.3       47.7
S_CONTACT_INDEX                        60       31.6       52.7
S_CONTACT_X_DATA                       30        6.2       20.6
S_CONTACT_X_INDEX                      30        1.8        6.1
S_CON_ADDR_INDEX                       30        5.2       17.2
S_GROUP_CONTACT_INDEX                  30        4.6       15.3
S_ORGGRP_INDEX                         30        3.8       12.8
S_ORG_GROUP_BU_DATA                    30        5.6       18.8
S_ORG_GROUP_BU_INDEX                   30        9.4       31.2
S_ORG_GROUP_DATA                       30        4.1       13.8
S_ORG_GROUP_INDEX                      30        4.1       13.8
S_OTHER_DATA                         78.1       61.8       79.1
S_OTHER_INDEX                       120.5       85.1       70.6
S_OTHER_MD_DATA                        30        3.9       13.1
S_OTHER_MD_INDEX                       30       13.6       45.4
S_PARTY_INDEX                          30          6       20.1
S_PER_COMM_ADDR_DATA                   30        7.4       24.8
S_PER_COMM_ADDR_INDEX                  30        9.5       31.6
S_POSTN_INDEX                          30       10.2       33.9
TESTTBS                                30          0          0
TOOLS                                  30        1.2        3.9
TSDATA                                 30       10.6       35.2
TSINDEX                                30       16.6       55.3
UNDOTBS1                               94       13.3       14.1
USERS                                  30          0          0
Total                              2092.6      556.8       26.6
