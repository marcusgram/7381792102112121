column A heading "Physical|Reads"  format 9,999,999,990
column B heading "Physical|Writes" format 9,999,999,990
column C heading "Total" format 9,999,999,990

SELECT ts.name as tablespace,
Substr(df.name,1,50) as filename,
fs.phyrds A,
fs.phywrts B,
fs.phyrds + fs.phywrts C
FROM v$tablespace ts, v$datafile df, v$filestat fs
WHERE df.file# = fs.file#
  AND df.ts# = ts.ts#
ORDER by c desc
/

---------------------------
-- Get io for a filename --
---------------------------
column A heading "Physical|Reads"  format 9,999,999,990
column B heading "Physical|Writes" format 9,999,999,990
column C heading "Total" format 9,999,999,990 
SELECT ts.name as tablespace,
Substr(df.name,1,50) as filename,
fs.phyrds A,
fs.phywrts B, fs.phyrds + fs.phywrts C
FROM v$tablespace ts, v$datafile df, v$filestat fs
WHERE df.file# = fs.file#
  AND df.ts# = ts.ts#
  AND Upper(df.name) like Upper('%&name%')
ORDER by c desc
/
