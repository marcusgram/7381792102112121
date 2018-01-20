
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
