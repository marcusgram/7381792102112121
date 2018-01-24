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
