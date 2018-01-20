
-- The following script displays the percentage of free space left in a tablespace and data file:

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

