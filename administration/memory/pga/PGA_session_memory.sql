SELECT
  p.spid unix_pid,
  s.sid,
  s.serial#,
  s.status,
  Substr(DECODE(sfprogramadi(s.sid, s.serial#),NULL,s.program,'OPSIS-'||sfprogramadi(s.sid, s.serial#)),1,48) "Program",
  Trunc(t.value/1024) "Memory (KB)",
  Substr(s.osuser||'@'||s.terminal,1,40) "kullanýcý"
FROM v$process p, v$session s, v$sesstat t, v$statname n
WHERE s.paddr   = p.addr(+)
  AND s.username is not null
  AND s.sid = t.sid
  AND t.statistic# = n.statistic#
  AND n.name = 'session pga memory'
  AND s.program is NOT NULL
ORDER BY t.value DESC
/



column sid format 9999
colum usr format a12
column stat format a25
column val format 9999999999999
column bytes format 999999999999
set head on 
set linesize 150
set pages 200

select c.sid sid,c.username usr,a.name stat,b.value bytes from 
v$statname a, v$sesstat b, v$session c
where a.statistic# = b.statistic#
and b.sid = c.sid
and a.name like '%pga%'
and c.status='ACTIVE' and
c.username is not null
order by c.sid,usr;
