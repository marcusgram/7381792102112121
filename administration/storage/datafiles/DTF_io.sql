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




SELECT Substr(df.name,2,8) as filesystem,
       Sum(fs.phyrds) as reads,
       Sum(fs.phywrts) as writes,
       Sum(fs.phyrds+fs.phywrts) as readwrites
FROM v$datafile df, v$filestat fs
WHERE df.file# = fs.file#
GROUP BY Substr(df.name,2,8)
UNION ALL
SELECT Substr(df.name,2,8) as filesystem,
       Sum(fs.phyrds) as reads,
       Sum(fs.phywrts) as writes,
       Sum(fs.phyrds+fs.phywrts) as readwrites
FROM v$tempfile df, v$filestat fs
WHERE df.file# = fs.file#
GROUP BY Substr(df.name,2,8)
ORDER BY 4 desc
/



SELECT Substr(filesystem,1,7) as name, Sum(readwrites) as toplamio
FROM ( SELECT Substr(df.name,2,8) as filesystem,
              Sum(fs.phyrds) as reads,
              Sum(fs.phywrts) as writes,
              Sum(fs.phyrds+fs.phywrts) as readwrites
       FROM v$datafile df, v$filestat fs
       WHERE df.file# = fs.file#
       GROUP BY Substr(df.name,2,8)
       UNION ALL
       SELECT Substr(df.name,2,8) as filesystem,
              Sum(fs.phyrds) as reads,
              Sum(fs.phywrts) as writes,
              Sum(fs.phyrds+fs.phywrts) as readwrites
       FROM v$tempfile df, v$filestat fs
       WHERE df.file# = fs.file#
       GROUP BY Substr(df.name,2,8) )
GROUP BY Substr(filesystem,1,7)
ORDER BY 2 DESC
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
