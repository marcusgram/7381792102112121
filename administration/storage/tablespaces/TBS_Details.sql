
col tablespace_name format A22 heading "Tablespace"
col objects format 999999 heading "Objects"
col files format 9999
col allocated_mb format 9,999,990.000 heading "Allocated Size|(Mb)"
col used_mb format 9,999,990.000 heading "Used Size|(Mb)"
col ts_type format A6 heading "TS|type"
col max_size_mb format 9,999,990.000 heading "Max Size|(Mb)"
col max_free_mb format 9,999,990.000 heading "Max Free|(Mb)"
col max_free_pct format 999 heading "Max Free|%"
 
BREAK ON REPORT
COMPUTE SUM LABEL "Total SUM:" OF objects files allocated_mb used_mb max_size_mb MAX_FREE_MB ON REPORT
COMPUTE AVG LABEL "Average %:" OF FREE_PCT MAX_FREE_PCT ON REPORT
 
SELECT ts.tablespace_name, status,
DECODE(dt.contents,'PERMANENT',DECODE(dt.extent_management,'LOCAL',DECODE(dt.allocation_type,'UNIFORM','LM-UNI','LM-SYS'),'DM'),'TEMPORARY','TEMP',dt.contents) ts_type,
NVL(s.count,0) objects,
ts.files,
ts.allocated/1024/1024 allocated_mb,
ROUND((ts.allocated-nvl(ts.free_size,0))/1024/1024,3) used_mb,
ROUND(maxbytes/1024/1024,3) max_size_mb,
ROUND((maxbytes-(ts.allocated-nvl(ts.free_size,0)))/1024/1024,3) max_free_mb,
ROUND((maxbytes-(ts.allocated-nvl(ts.free_size,0)))*100/maxbytes,2) max_free_pct
FROM
(
SELECT dfs.tablespace_name,files,allocated,free_size,maxbytes
FROM
(SELECT fs.tablespace_name, sum(fs.bytes) free_size
FROM dba_free_space fs
GROUP BY fs.tablespace_name)
dfs,
(SELECT df.tablespace_name, count(*) files, sum(df.bytes) allocated,
sum(DECODE(df.maxbytes,0,df.bytes,df.maxbytes)) maxbytes, max(autoextensible) autoextensible
FROM dba_data_files df
WHERE df.status = 'AVAILABLE'
GROUP BY df.tablespace_name)
ddf
WHERE dfs.tablespace_name = ddf.tablespace_name
UNION
SELECT dtf.tablespace_name,files,allocated,free_size,maxbytes
FROM
(SELECT tf.tablespace_name, count(*) files, sum(tf.bytes) allocated,
sum(DECODE(tf.maxbytes,0,tf.bytes,tf.maxbytes)) maxbytes, max(autoextensible) autoextensible
FROM dba_temp_files tf
GROUP BY tf.tablespace_name)
dtf,
(SELECT th.tablespace_name, SUM (th.bytes_free) free_size
FROM v$temp_space_header th
GROUP BY tablespace_name)
tsh
WHERE dtf.tablespace_name = tsh.tablespace_name
) ts,
( SELECT s.tablespace_name, count(*) count
FROM dba_segments s
GROUP BY s.tablespace_name) s,
dba_tablespaces dt,
v$parameter p
WHERE p.name = 'db_block_size'
AND ts.tablespace_name = dt.tablespace_name
AND ts.tablespace_name = s.tablespace_name (+)
ORDER BY 1
/



                          TS                   Allocated Size   Used Size       Max Size       Max Free Max Free
Tablespace      STATUS    type   Objects FILES           (Mb)        (Mb)           (Mb)           (Mb)        %
--------------- --------- ------ ------- ----- -------------- ----------- -------------- -------------- --------
EXAMPLE         ONLINE    LM-SYS     313     1        345.625     309.813     32,767.984     32,458.172       99
SYSAUX          ONLINE    LM-SYS    4152     1        610.000     575.375     32,767.984     32,192.609       98
SYSTEM          ONLINE    LM-SYS    1693     1        700.000     686.688     32,767.984     32,081.297       98
TEMP            ONLINE    TEMP         0     1         59.000      59.000     32,767.984     32,708.984      100
UNDOTBS1        ONLINE    UNDO        10     1        830.000      13.250     32,767.984     32,754.734      100
USERS           ONLINE    LM-SYS      41     1          5.000       4.000     32,767.984     32,763.984      100
                                 ------- ----- -------------- ----------- -------------- -------------- --------
Average %:                                                                                                    99
Total SUM:                          6209     6      2,549.625   1,648.126    196,607.904    194,959.780
 
6 rows selected.





-- volumetrie detaillee des tablespaces ---

clear breaks
clear computes
clear columns
set pagesize 50
set linesize 120
set heading on
column tablespace_name heading 'Tablespace' justify left format a20 truncated
column tbsize heading 'Size|(Mb) ' justify left format 9,999,999.99
column tbused heading 'Used|(Mb) ' justify right format 9,999,999.99
column tbfree heading 'Free|(Mb) ' justify right format 9,999,999.99
column tbusedpct heading 'Used % ' justify left format a8
column tbfreepct heading 'Free % ' justify left format a8
break on report
compute sum label 'Totals:' of tbsize tbused tbfree on report
select t.tablespace_name, round(a.bytes,2) tbsize,
nvl(round(c.bytes,2),'0') tbfree,
nvl(round(b.bytes,2),'0') tbused,
to_char(round(100 * (nvl(b.bytes,0)/nvl(a.bytes,1)),2)) || '%' tbusedpct,
to_char(round(100 * (nvl(c.bytes,0)/nvl(a.bytes,1)),2)) || '%' tbfreepct
from dba_tablespaces t,
(select tablespace_name, round(sum(bytes)/1024/1024,2) bytes
from dba_data_files
group by tablespace_name
union
select tablespace_name, round(sum(bytes)/1024/1024,2) bytes
from dba_temp_files
group by tablespace_name ) a,
(select e.tablespace_name, round(sum(e.bytes)/1024/1024,2) bytes
from dba_segments e
group by e.tablespace_name
union
select tablespace_name, sum(max_size) bytes
from v$sort_segment
group by tablespace_name) b,
(select f.tablespace_name, round(sum(f.bytes)/1024/1024,2) bytes
from dba_free_space f
group by f.tablespace_name
union
select tmp.tablespace_name, (sum(bytes/1024/1024) - sum(max_size)) bytes
from dba_temp_files tmp, v$sort_segment sort
where tmp.tablespace_name = sort.tablespace_name
group by tmp.tablespace_name) c
where
t.tablespace_name = a.tablespace_name (+)
and t.tablespace_name = b.tablespace_name (+)
and t.tablespace_name = c.tablespace_name (+)
order by t.tablespace_name;


                     Size                   Free          Used
Tablespace           (Mb)                  (Mb)          (Mb)  Used %   Free %
-------------------- ------------- ------------- ------------- -------- --------
DATA0001                  1,171.00      1,167.00           .00 0%       99.66%
DATAAUDIT                 8,705.00      8,133.50        568.44 6.53%    93.43%
DATACOL                  16,649.00     15,283.13      1,362.81 8.19%    91.8%
DATACOL32K               66,832.00     64,627.25      2,200.75 3.29%    96.7%
DATACOLPRL               11,696.00     11,692.94           .00 0%       99.97%
DATACOLVIR                1,045.00      1,041.94           .00 0%       99.71%
DATAMAND                  7,237.00      5,952.69      1,281.25 17.7%    82.25%
DATAREF                   1,045.00        986.50         55.44 5.31%    94.4%
DATATECH                 62,016.00     61,831.25        181.69 .29%     99.7%
IDXAUDIT                  2,070.00      1,946.63        120.31 5.81%    94.04%
IDXCOL                    6,497.00      6,054.50        439.44 6.76%    93.19%
IDXCOLPRL                 9,900.00      9,387.75        509.19 5.14%    94.83%
IDXCOLVIR                 1,045.00      1,040.31          1.63 .16%     99.55%
IDXMAND                   4,753.00      4,043.19        706.75 14.87%   85.07%
IDXREF                    1,045.00      1,013.44         28.50 2.73%    96.98%
IDXTECH                   1,045.00      1,036.31          5.63 .54%     99.17%
INDX0001                  1,171.00      1,167.00           .00 0%       99.66%
STATSPACK                 1,171.00      1,167.00           .00 0%       99.66%
SYSAUX                    1,444.00        860.56        579.44 40.13%   59.6%
SYSTEM                    1,544.00      1,046.25        493.75 31.98%   67.76%
TEMP                     11,534.00    -41,906.00     10,688.00 92.67%   -363.33%
UNDOTBS1                 24,950.00     24,711.69        234.31 .94%     99.04%
                     ------------- ------------- -------------
Totals:                 244,565.00    182,284.83     19,457.33

22 rows selected.




-----------------------------------------------------------
1 a) Combine query with sm$ts_avail,sm$ts_used,sm$ts_free:
----------------------------------------------------------
set pages 1000
break on report
compute sum of Total_MB on report
compute sum of Used_MB on report
compute sum of Free_MB on report

select a.TABLESPACE_NAME, round(Curr_Size,1) Total_MB,round(Used,1) Used_MB,round(Free,1) Free_MB, round(100*(1-free/Curr_Size),1) Usage
from (select TABLESPACE_NAME,BYTES/(1024*1024) Curr_Size from sm$ts_avail) a
,(select TABLESPACE_NAME,BYTES/(1024*1024) Used from sm$ts_used) b,
(select TABLESPACE_NAME,BYTES/(1024*1024) Free from sm$ts_free) c
where a.TABLESPACE_NAME=b.TABLESPACE_NAME(+) and
a.TABLESPACE_NAME=c.TABLESPACE_NAME order by 1 ASC;


\Tablespace Fragmentation Details\
TABLESPACE_NAME                  TOTAL_MB    USED_MB    FREE_MB      USAGE
------------------------------ ---------- ---------- ---------- ----------
DATA0001                              127        .10      125.9         .9
EIM_ADDR_PER_DATA                     110                   109         .9
EIM_ADDR_PER_INDEX                   1500                  1499         .1
EIM_GROUP_INDEX                      2700                  2699          0
EIM_OTHER_DATA                       1600    1436.90      162.1       89.9
EIM_OTHER_INDEX                      2300    1748.10      550.9         76
ERR_DATA                            15800    1088.00      14711        6.9
INDX0001                             3527    2019.30     1506.8       57.3
PURGE_DATA                            410     351.00         58       85.9
PURGE_INDEX                           100      10.90       88.1       11.9
REPRISE_PCOM_DATA                    8500    7848.40      923.9       89.1
REPRISE_PCOM_INDEX                   4900    3572.40     1326.6       72.9
STATSPACK                             127        .10      125.9         .8
SYSAUX                              28300    6519.00      21780         23
SYSTEM                               5120    1051.90     4067.1       20.6
S_1M_INDEX                         160000   75676.50    84318.5       47.3
S_4M_DATA                           39520   38424.00       1094       97.2
S_50M_DATA                           7400    6144.00       1255         83
S_60M_DATA                          37300   27264.00      10034       73.1
S_70M_DATA                          17700   16768.00        931       94.7
S_8M_DATA                           17400   16192.00       1207       93.1
S_ADDR_INDEX                         6100    5755.60      343.4       94.4
S_ADDR_PER_INDEX     
-------
UNDOTBS1                           243840    4408.30   239420.7        1.8
USERS                                 100        .30         99          1
                               ---------- ---------- ----------
sum                               1030371  566287.10     464279

57 rows selected.


---------------------------------------------------------------------
1 b) If you want to know the usage details of particular tablespace, 
you can add and tablespace_name='&tablespace_name' in the where condition of the above query. 
For example
--------------------------------------------------------------------

set pages 1000
break on report
compute sum of Total_MB on report
compute sum of Used_MB on report
compute sum of Free_MB on report
select a.TABLESPACE_NAME, round(Curr_Size,1) Total_MB,round(Used,1) Used_MB,round(Free,1) Free_MB, round(100*(1-free/Curr_Size),1) Usage
from (select TABLESPACE_NAME,BYTES/(1024*1024) Curr_Size from sm$ts_avail) a
,(select TABLESPACE_NAME,BYTES/(1024*1024) Used from sm$ts_used) b,
(select TABLESPACE_NAME,BYTES/(1024*1024) Free from sm$ts_free) c
where a.TABLESPACE_NAME=b.TABLESPACE_NAME(+) and
a.TABLESPACE_NAME=c.TABLESPACE_NAME and a.TABLESPACE_NAME='&TBS' order by 1 ASC;


------------------------------------------------------------------------------------------
--If your tablespace is auto extendable, you can use the below query given in 2 a) and 2 b) 
--to get space usage of tablespace
--2 a) Below query will give you the free space details with extendable space of the tablespace 
--if the tablespace is auto extendable.
------------------------------------------------------------------------------------------
set pages 1000
set lines 500
break on report
compute sum of CURR_SIZE_MB on report
compute sum of Used_MB on report
compute sum of MAXSIZE_MB on report
compute sum of Free+extendable_MB on report
col TABLESPACE_NAME for a30
col file_name for a45
select
   a.TABLESPACE_NAME,
   round(avail,1) curr_size_MB,
   round(used,1) used_MB,
   round(total,1) Maxsize_MB,
   round(free+extentable_MB,1) "Free+extendable_MB",
   round(100*(1-(free+extentable_MB)/total),1)"Usage %"
from (
      select
        TABLESPACE_NAME,
        sum(BYTES)/(1024*1024) avail,
        sum(MAXBYTES)/(1024*1024) total,
        (sum(MAXBYTES)/(1024*1024) - sum(BYTES)/(1024*1024)) extentable_MB
      from dba_data_files
      group by TABLESPACE_NAME) a,
     (
      select
         TABLESPACE_NAME,
         sum(BYTES)/(1024*1024) free
      from dba_free_space group by TABLESPACE_NAME) b,
     (
      select
         TABLESPACE_NAME,
         BYTES/(1024*1024) Used
      from sm$ts_used) c
where a.TABLESPACE_NAME=b.TABLESPACE_NAME and
      a.TABLESPACE_NAME=c.TABLESPACE_NAME
order by 4 DESC;




-----------------------------------------------------------------------
--2 b) Here also you can get the same details for a particular tablespace 
--by adding "and  a.TABLESPACE_NAME='&tablespace_name' 
--in the where condition of the above query.
----------------------------------------------------------------------
set pages 1000
set lines 500
break on report
compute sum of CURR_SIZE_MB on report
compute sum of Used_MB on report
compute sum of MAXSIZE_MB on report
compute sum of Free+extendable_MB on report
col TABLESPACE_NAME for a30
col file_name for a45
select
   a.TABLESPACE_NAME,
   round(avail,1) curr_size_MB,
   round(used,1) used_MB,
   round(total,1) Maxsize_MB,
   round(free+extentable_MB,1) "Free+extendable_MB",
   round(100*(1-(free+extentable_MB)/total),1)"Usage %"
from (
      select
        TABLESPACE_NAME,
        sum(BYTES)/(1024*1024) avail,
        sum(MAXBYTES)/(1024*1024) total,
        (sum(MAXBYTES)/(1024*1024) - sum(BYTES)/(1024*1024)) extentable_MB
      from dba_data_files
      group by TABLESPACE_NAME) a,
     (
      select
         TABLESPACE_NAME,
         sum(BYTES)/(1024*1024) free
      from dba_free_space group by TABLESPACE_NAME) b,
     (
      select
         TABLESPACE_NAME,
         BYTES/(1024*1024) Used
      from sm$ts_used) c
where a.TABLESPACE_NAME=b.TABLESPACE_NAME and
      a.TABLESPACE_NAME=c.TABLESPACE_NAME and
      a.TABLESPACE_NAME='SE3_DATA'
order by 4 DESC;





--------------------------------------------------------------------------------------
--3) Below query will give you each datafiles' free space,used space of the tablespace.
--------------------------------------------------------------------------------------
set lines 500
col FILE_NAME for a45
compute sum of ALLOCATED_MB on report
compute sum of Used_MB on report
compute sum of FREE_SPACE_MB on report
set lines 500
COLUMN free_space_mb format 999999.90
COLUMN allocated_mb format 999999.90
COLUMN used_mb format 999999.90
col file_name for a60
SELECT   SUBSTR (df.NAME, 1, 60) file_name, df.bytes / 1024 / 1024 allocated_mb,
         ((df.bytes / 1024 / 1024) - NVL (SUM (dfs.bytes) / 1024 / 1024, 0))
               used_mb,
         NVL (SUM (dfs.bytes) / 1024 / 1024, 0) free_space_mb
    FROM v$datafile df, dba_free_space dfs
   WHERE df.file# = dfs.file_id(+) 
   --and dfs.TABLESPACE_NAME='TEK_DATA'
GROUP BY dfs.file_id, df.NAME, df.file#, df.bytes
ORDER BY file_name;



-----------------------------------------------------------------------------------
--4a) You can use the below query to find the current tablespace structure details 
--like current size,max size,auto extendable or not, next increment by
-----------------------------------------------------------------------------------
set lines 500
set pages 100
col TABLESPACE_NAME for a30
col FILE_NAME for a60
break on report
compute sum of Size_MB on report
compute sum of Maxsize_MB on report
compute sum of extentable_MB on report
select 
TABLESPACE_NAME,
FILE_NAME,BYTES/(1024*1024) Size_MB,MAXBYTES/(1024*1024) Maxsize_MB,
AUTOEXTENSIBLE,
(MAXBYTES - BYTES)/(1024*1024) extentable_MB,INCREMENT_BY*(8192/1024) "Next (in KB)"
from dba_data_files 
order by 2;


------------------------------------------------------------------------------
--4b) You can get the details for particular tablespace also using below query
------------------------------------------------------------------------------
set lines 500
set pages 100
col TABLESPACE_NAME for a30
col FILE_NAME for a60
break on report
compute sum of Size_MB on report
compute sum of Maxsize_MB on report
compute sum of extentable_MB on report
select 
TABLESPACE_NAME,
FILE_NAME,BYTES/(1024*1024) Size_MB,
MAXBYTES/(1024*1024) Maxsize_MB,
AUTOEXTENSIBLE,
(MAXBYTES - BYTES)/(1024*1024) extentable_MB,
INCREMENT_BY*(8192/1024) "Next (in KB)"
from dba_data_files 
where TABLESPACE_NAME='&tb_name' 
order by 2;



---------------------------------------------------
--5) query to find growth history for a tablespace:
---------------------------------------------------
SELECT TO_CHAR (sp.begin_interval_time,'YYYY-MM-DD') days
, ts.tsname
, max(round((tsu.tablespace_size* dt.block_size )/(1024*1024),2) ) cur_size_MB
, max(round((tsu.tablespace_usedsize* dt.block_size )/(1024*1024),2)) usedsize_MB
FROM DBA_HIST_TBSPC_SPACE_USAGE tsu
, DBA_HIST_TABLESPACE_STAT ts
, DBA_HIST_SNAPSHOT sp
, DBA_TABLESPACES dt
WHERE tsu.tablespace_id= ts.ts#
AND tsu.snap_id = sp.snap_id
AND ts.tsname = dt.tablespace_name
AND ts.tsname IN ('&tb_name')
GROUP BY TO_CHAR (sp.begin_interval_time,'YYYY-MM-DD'), ts.tsname
ORDER BY ts.tsname, days desc;



---------------------------------------------------------------------------
--6) Query to find average Growth MB/Day of a tablespace in last 30 days:
---------------------------------------------------------------------------
SELECT b.tsname tablespace_name
, MAX(b.used_size_mb) cur_used_size_mb
, round(AVG(inc_used_size_mb),2)avg_growth_mb_per_day
FROM (
  SELECT a.days, a.tsname, used_size_mb
  , used_size_mb - LAG (used_size_mb,1)  OVER ( PARTITION BY a.tsname ORDER BY a.tsname,a.days) inc_used_size_mb
  FROM (
      SELECT TO_CHAR(sp.begin_interval_time,'MM-DD-YYYY') days
       ,ts.tsname
       ,MAX(round((tsu.tablespace_usedsize* dt.block_size )/(1024*1024),2)) used_size_mb
      FROM DBA_HIST_TBSPC_SPACE_USAGE tsu, DBA_HIST_TABLESPACE_STAT ts
       ,DBA_HIST_SNAPSHOT sp, DBA_TABLESPACES dt
      WHERE tsu.tablespace_id= ts.ts# AND tsu.snap_id = sp.snap_id
       AND ts.tsname = dt.tablespace_name  AND sp.begin_interval_time > sysdate-30
      GROUP BY TO_CHAR(sp.begin_interval_time,'MM-DD-YYYY'), ts.tsname
      ORDER BY ts.tsname, days
  ) A
) b where b.tsname='&tb_name' GROUP BY b.tsname ORDER BY b.tsname
/



