SELECT
  p.spid  unix_pid,
  s.sid,
  s.serial#,
  s.status,
  Substr(s.username,1,10) username,
  s.terminal,
  s.osuser,
  s.program
from v$process p, v$session s, dba_ddl_locks d
WHERE s.paddr = p.addr(+)
  AND s.username is not null
  AND s.sid = d.session_id
  AND s.status = 'ACTIVE'
  AND d.name = Upper('&objname')
--  AND d.type = 'Body'
ORDER BY s.username, s.terminal
/

